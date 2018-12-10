// Copyright (c) 2018 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.
//
// Bug fixes and contributions will eventually be released under the
// SolderPad open hardware license in the context of the PULP platform
// (http://www.pulp-platform.org), under the copyright of ETH Zurich and the
// University of Bologna.

// Author: Stefan Mach <smach@iis.ee.ethz.ch>

module fpnew_opgroup_block #(
  parameter fpnew_pkg::opgroup_e        OpGroup       = fpnew_pkg::ADDMUL,
  // FPU configuration
  parameter int unsigned                Width         = 32,
  parameter logic                       EnableVectors = 1'b1,
  parameter fpnew_pkg::fmt_logic_t      FpFmtMask     = '1,
  parameter fpnew_pkg::ifmt_logic_t     IntFmtMask    = '1,
  parameter fpnew_pkg::fmt_unsigned_t   FmtPipeRegs   = '{default: 0},
  parameter fpnew_pkg::fmt_unit_types_t FmtUnitTypes  = '{default: fpnew_pkg::PARALLEL},
  parameter fpnew_pkg::pipe_config_t    PipeConfig    = fpnew_pkg::BEFORE,
  parameter type                        TagType       = logic,
  // Do not change
  localparam int unsigned NUM_FORMATS  = fpnew_pkg::NUM_FP_FORMATS,
  localparam int unsigned NUM_OPERANDS = fpnew_pkg::num_operands(OpGroup)
) (
  input logic                               clk_i,
  input logic                               rst_ni,
  // Input signals
  input logic [0:NUM_OPERANDS-1][Width-1:0]       operands_i,
  input logic [0:NUM_FORMATS-1][0:NUM_OPERANDS-1] is_boxed_i,
  input fpnew_pkg::roundmode_e                    rnd_mode_i,
  input fpnew_pkg::operation_e                    op_i,
  input logic                                     op_mod_i,
  input fpnew_pkg::fp_format_e                    fp_fmt_i,
  input fpnew_pkg::fp_format_e                    fp_fmt2_i,
  input fpnew_pkg::int_format_e                   int_fmt_i,
  input logic                                     vectorial_op_i,
  input TagType                                   tag_i,
  // Input Handshake
  input  logic                              in_valid_i,
  output logic                              in_ready_o,
  input  logic                              flush_i,
  // Output signals
  output logic [Width-1:0]                  result_o,
  output fpnew_pkg::status_t                status_o,
  output logic                              extension_bit_o,
  output TagType                            tag_o,
  // Output handshake
  output logic                              out_valid_o,
  input  logic                              out_ready_i,
  // Indication of valid data in flight
  output logic                              busy_o
);

  // ----------------
  // Type Definition
  // ----------------
  typedef struct packed {
    logic [Width-1:0]   result;
    fpnew_pkg::status_t status;
    logic               ext_bit;
    TagType             tag;
  } output_t;

  // Handshake signals for the slices
  logic [0:NUM_FORMATS-1] fmt_in_ready, fmt_out_valid, fmt_out_ready, fmt_busy;
  output_t [0:NUM_FORMATS-1] fmt_outputs;

  // -----------
  // Input Side
  // -----------
  assign in_ready_o = in_valid_i & fmt_in_ready[fp_fmt_i]; // Ready is given by selected format

  // -------------------------
  // Generate Parallel Slices
  // -------------------------
  for (genvar fmt = 0; fmt < int'(NUM_FORMATS); fmt++) begin : gen_parallel_slices
    logic in_valid;

    // Generate slice only if format enabled
    if (FpFmtMask[fmt] && (FmtUnitTypes[fmt] == fpnew_pkg::PARALLEL)) begin : active_format

      assign in_valid = in_valid_i & (fp_fmt_i == fmt); // enable selected format

      fpnew_opgroup_fmt_slice #(
        .OpGroup       ( OpGroup          ),
        .FpFormat      ( fmt              ),
        .Width         ( Width            ),
        .EnableVectors ( EnableVectors    ),
        .NumPipeRegs   ( FmtPipeRegs[fmt] ),
        .PipeConfig    ( PipeConfig       ),
        .TagType       ( TagType          )
      ) i_fmt_slice (
        .clk_i,
        .rst_ni,
        .operands_i     ( operands_i               ),
        .rnd_mode_i,
        .op_i,
        .op_mod_i,
        .vectorial_op_i,
        .tag_i,
        .in_valid_i     ( in_valid                 ),
        .in_ready_o     ( fmt_in_ready[fmt]        ),
        .flush_i,
        .result_o       ( fmt_outputs[fmt].result  ),
        .status_o       ( fmt_outputs[fmt].status  ),
        .extension_bit_o( fmt_outputs[fmt].ext_bit ),
        .tag_o          ( fmt_outputs[fmt].tag     ),
        .out_valid_o    ( fmt_out_valid[fmt]       ),
        .out_ready_i    ( fmt_out_ready[fmt]       ),
        .busy_o         ( fmt_busy[fmt]            )
      );
    // If the format wants to use merged ops, tie off the dangling ones not used here
    end else if (FpFmtMask[fmt] && fpnew_pkg::any_enabled_multi(FmtUnitTypes) &&
        !fpnew_pkg::is_first_enabled_multi(fmt, FmtUnitTypes)) begin : merged_unused

      // Ready is split up into formats
      assign fmt_in_ready[fmt]  = fmt_in_ready[fpnew_pkg::get_first_enabled_multi(FmtUnitTypes)];

      assign fmt_out_valid[fmt] = 1'b0; // don't emit values
      assign fmt_busy[fmt]      = 1'b0; // never busy
      // Outputs are don't care
      assign fmt_outputs[fmt]  = 'X;

    // Tie off disabled formats
    end else begin : disable_format
      assign fmt_in_ready[fmt]  = 1'b0; // don't accept operations
      assign fmt_out_valid[fmt] = 1'b0; // don't emit values
      assign fmt_busy[fmt]      = 1'b0; // never busy
      // Outputs are don't care
      assign fmt_outputs[fmt]  = 'X;
    end
  end

  // ----------------------
  // Generate Merged Slice
  // ----------------------
  if (fpnew_pkg::any_enabled_multi(FmtUnitTypes)) begin : gen_merged_slice

    localparam FMT = fpnew_pkg::get_first_enabled_multi(FmtUnitTypes);

    logic in_valid;

    assign in_valid = in_valid_i & (FmtUnitTypes[fp_fmt_i] == fpnew_pkg::MERGED);

    fpnew_opgroup_multifmt_slice #(
      .OpGroup       ( OpGroup          ),
      .Width         ( Width            ),
      .FpFmtConfig   ( FpFmtMask        ),
      .IntFmtConfig  ( IntFmtMask       ),
      .EnableVectors ( EnableVectors    ),
      .NumPipeRegs   ( FmtPipeRegs[FMT] ),
      .PipeConfig    ( PipeConfig       ),
      .TagType       ( TagType          )
    ) i_multifmt_slice (
      .clk_i,
      .rst_ni,
      .operands_i,
      .is_boxed_i,
      .rnd_mode_i,
      .op_i,
      .op_mod_i,
      .fp_fmt_i,
      .fp_fmt2_i,
      .int_fmt_i,
      .vectorial_op_i,
      .tag_i,
      .in_valid_i     ( in_valid                 ),
      .in_ready_o     ( fmt_in_ready[FMT]        ),
      .flush_i,
      .result_o       ( fmt_outputs[FMT].result  ),
      .status_o       ( fmt_outputs[FMT].status  ),
      .extension_bit_o( fmt_outputs[FMT].ext_bit ),
      .tag_o          ( fmt_outputs[FMT].tag     ),
      .out_valid_o    ( fmt_out_valid[FMT]       ),
      .out_ready_i    ( fmt_out_ready[FMT]       ),
      .busy_o         ( fmt_busy[FMT]            )
    );

  end

  // ------------------
  // Arbitrate Outputs
  // ------------------
  output_t arbiter_output;

  // Round-Robin arbiter to decide which result to use
  stream_arbiter_flushable #(
    .DATA_T ( output_t    ),
    .N_INP  ( NUM_FORMATS )
  ) i_arbiter (
    .clk_i,
    .rst_ni,
    .flush_i,
    .inp_data_i  ( fmt_outputs    ),
    .inp_valid_i ( fmt_out_valid  ),
    .inp_ready_o ( fmt_out_ready  ),
    .oup_data_o  ( arbiter_output ),
    .oup_valid_o ( out_valid_o    ),
    .oup_ready_i ( out_ready_i    )
  );

  // Unpack output
  assign result_o        = arbiter_output.result;
  assign status_o        = arbiter_output.status;
  assign extension_bit_o = arbiter_output.ext_bit;
  assign tag_o           = arbiter_output.tag;

  assign busy_o = (| fmt_busy);

endmodule
