// Copyright 2019 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Michael Schaffner <schaffner@iis.ee.ethz.ch>, ETH Zurich
// Date: 07.03.2019
// Description: Clos network.

module clos_net #(
  parameter int unsigned NumIn           = 4,            // Only powers of two permitted
  parameter int unsigned NumOut          = 4,            // Only powers of two permitted
  parameter int unsigned ReqDataWidth    = 32,           // word width of data
  parameter int unsigned RespDataWidth   = 32,           // word width of data
  parameter bit          WriteRespOn     = 1,            // defines whether the interconnect returns a write response
  parameter int unsigned RespLat         = 1,
  // this detemines which clos config to use
  // 1: m=0.50*n, 2: m=1.00*n, 3: m=2.00*n,
  parameter int unsigned ClosConfig      = 2
) (
  input  logic                                  clk_i,
  input  logic                                  rst_ni,
  // master side
  input  logic [NumIn-1:0]                      req_i,     // Request signal
  input  logic [NumIn-1:0][$clog2(NumOut)-1:0]  add_i,     // Bank Address
  input  logic [NumIn-1:0]                      wen_i,     // 1: Store, 0: Load
  input  logic [NumIn-1:0][ReqDataWidth-1:0]    wdata_i,   // Write data
  output logic [NumIn-1:0]                      gnt_o,     // Grant (combinationally dependent on req_i and add_i)
  output logic [NumIn-1:0]                      vld_o,     // Response valid, also asserted if write responses are enabled
  output logic [NumIn-1:0][RespDataWidth-1:0]   rdata_o,   // Data Response DATA (For LOAD commands)
  // slave side
  input   logic [NumOut-1:0]                    gnt_i,     // Grant input
  output  logic [NumOut-1:0]                    req_o,     // Request out
  output  logic [NumOut-1:0][ReqDataWidth-1:0]  wdata_o,   // Data request Wire data
  input   logic [NumOut-1:0][RespDataWidth-1:0] rdata_i    // Data Response DATA (For LOAD commands)
);

////////////////////////////////////////////////////////////////////////
// LUT params for Clos net with configs: 1: m=0.50*n, 2: m=1.00*n, 3: m=2.00*n,
// to be indexed with [config_idx][$clog2(BankingFact)][$clog2(NumBanks)]
// generated with MATLAB script gen_clos_params.m
////////////////////////////////////////////////////////////////////////
localparam logic [3:1][4:0][12:2][15:0] ClosNLut = {16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,
                                                    16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,
                                                    16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,
                                                    16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,
                                                    16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,
                                                    16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,
                                                    16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,
                                                    16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,
                                                    16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,
                                                    16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,
                                                    16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,
                                                    16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,
                                                    16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,
                                                    16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,
                                                    16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2};
localparam logic [3:1][4:0][12:2][15:0] ClosMLut = {16'd128,16'd128,16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,
                                                    16'd128,16'd128,16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,
                                                    16'd128,16'd128,16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,
                                                    16'd128,16'd128,16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,
                                                    16'd128,16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,
                                                    16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,
                                                    16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,
                                                    16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,
                                                    16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,
                                                    16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,
                                                    16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,16'd1,
                                                    16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,16'd1,
                                                    16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,16'd1,
                                                    16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,16'd1,
                                                    16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,16'd1,16'd1};
localparam logic [3:1][4:0][12:2][15:0] ClosRLut = {16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,
                                                    16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,
                                                    16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,
                                                    16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,
                                                    16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,
                                                    16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,
                                                    16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,
                                                    16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,
                                                    16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,
                                                    16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,
                                                    16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,
                                                    16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,
                                                    16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,
                                                    16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2,16'd2,
                                                    16'd64,16'd64,16'd32,16'd32,16'd16,16'd16,16'd8,16'd8,16'd4,16'd4,16'd2};

// classic clos parameters, make sure they are aligned with powers of 2
// good tradeoff in terms of router complexity (with b=banking factor):  N = sqrt(NumOut / (1+1/b)))
// some values (banking factor of 2):
// 8  Banks -> N = 2,
// 16 Banks -> N = 4,
// 32 Banks -> N = 4,
// 64 Banks -> N = 8,
// 128 Banks -> N = 8,
// 256 Banks -> N = 16,
// 512 Banks -> N = 16
localparam int unsigned BankFact = NumOut/NumIn;
localparam int unsigned ClosN = unsigned'(ClosNLut[ClosConfig][$clog2(BankFact)][$clog2(NumOut)]);
localparam int unsigned ClosM = unsigned'(ClosMLut[ClosConfig][$clog2(BankFact)][$clog2(NumOut)]);
localparam int unsigned ClosR = unsigned'(ClosRLut[ClosConfig][$clog2(BankFact)][$clog2(NumOut)]);


////////////////////////////////////////////////////////////////////////
// network inter-level connections
////////////////////////////////////////////////////////////////////////

logic [NumIn-1:0][ReqDataWidth+$clog2(NumOut)-1:0] add_wdata;

logic [ClosR-1:0][ClosM-1:0]                     ingress_gnt, ingress_req;
// bank address slice for RxR routers
logic [ClosR-1:0][ClosM-1:0][$clog2(ClosR)-1:0]  ingress_add;
logic [ClosR-1:0][ClosM-1:0][ReqDataWidth+$clog2(NumOut)-1:0]   ingress_req_data;
logic [ClosR-1:0][ClosM-1:0][RespDataWidth-1:0]  ingress_resp_data;

logic [ClosM-1:0][ClosR-1:0]                     middle_gnt_out, middle_gnt_in, middle_req_out, middle_req_in;
// bank address slice for RxR routers
logic [ClosM-1:0][ClosR-1:0][$clog2(ClosR)-1:0]  middle_add_in;
// bank address slice for MxN routers
logic [ClosM-1:0][ClosR-1:0][$clog2(ClosN)-1:0]  middle_add_out;
logic [ClosM-1:0][ClosR-1:0][ReqDataWidth+$clog2(ClosN)-1:0] middle_req_data_in, middle_req_data_out;
logic [ClosM-1:0][ClosR-1:0][RespDataWidth-1:0]  middle_resp_data_out, middle_resp_data_in;

logic [ClosR-1:0][ClosM-1:0]                     egress_gnt, egress_req;
// bank address slice for MxN routers
logic [ClosR-1:0][ClosM-1:0][$clog2(ClosN)-1:0]  egress_add;
logic [ClosR-1:0][ClosM-1:0][ReqDataWidth-1:0]   egress_req_data;
logic [ClosR-1:0][ClosM-1:0][RespDataWidth-1:0]  egress_resp_data;

for (genvar k = 0; unsigned'(k) < NumIn; k++) begin : g_cat
  assign add_wdata[k] = {add_i[k], wdata_i[k]};
end

for (genvar m = 0; unsigned'(m) < ClosM; m++) begin : g_connect1
  for (genvar r = 0; unsigned'(r) < ClosR; r++) begin : g_connect2
    // ingress to/from middle
    // get bank address slice for next stage (middle stage contains RxR routers)
    assign ingress_add[r][m]         = ingress_req_data[r][m][ReqDataWidth+$clog2(NumOut)-1 :
                                                              ReqDataWidth+$clog2(NumOut)-$clog2(ClosR)];
    assign middle_req_in[m][r]       = ingress_req[r][m];
    assign middle_add_in[m][r]       = ingress_add[r][m];
    // we can drop the MSBs of the address here
    assign middle_req_data_in[m][r]  = ingress_req_data[r][m][ReqDataWidth+$clog2(ClosN)-1:0];
    assign ingress_gnt[r][m]         = middle_gnt_out[m][r];
    assign ingress_resp_data[r][m]   = middle_resp_data_out[m][r];

    // middle to/from egress
    // get bank address slice for next stage (middle stage contains RxR routers)
    assign middle_add_out[m][r]      = middle_req_data_out[m][r][ReqDataWidth+$clog2(ClosN)-1 :
                                                                 ReqDataWidth];

    assign egress_req[r][m]          = middle_req_out[m][r];
    assign egress_add[r][m]          = middle_add_out[m][r];
    // we can drop the MSBs of the address here
    assign egress_req_data[r][m]     = middle_req_data_out[m][r][ReqDataWidth-1:0];
    assign middle_gnt_in[m][r]       = egress_gnt[r][m];
    assign middle_resp_data_in[m][r] = egress_resp_data[r][m];
  end
end

////////////////////////////////////////////////////////////////////////
// arbitration priorities
// need to use a locked round robin scheme to avoid correlation
// issues between local round robin counters
////////////////////////////////////////////////////////////////////////
localparam NumInNode = ClosN / BankFact;

logic [ClosR-1:0][ClosM-1:0][$clog2(NumInNode)-1:0] rr_ing;
logic [$clog2(NumInNode)-1:0] rr_ing_tmp;
// logic [ClosM*$clog2(NumInNode)-1:0][ClosR-1:0] rr_ing_tmp;
logic [ClosR-1:0][$clog2(ClosR)-1:0] rr_mid;
logic [ClosN-1:0][$clog2(ClosM)-1:0] rr_egr;
logic [$clog2(ClosM*ClosR*NumInNode)-1:0] rr_d, rr_q;

if (NumInNode > ClosM) begin : gen_rr
  // use LSB for broadcast stages
  assign rr_ing_tmp = rr_q[$clog2(NumInNode)-1:0];

  if (ClosR > 1) begin : gen_rr_mid
    assign rr_mid     = {ClosR{rr_q[$clog2(ClosR*NumInNode*ClosM)-1:$clog2(ClosM*NumInNode)]}};
  end

  if (ClosM > 1) begin : gen_rr_egr
    assign rr_egr     = {ClosN{rr_q[$clog2(ClosM*NumInNode)-1:$clog2(NumInNode)]}};
  end
end else begin : g_static
  assign rr_ing_tmp = '0;

  if (ClosR > 1) begin : gen_rr_mid
    assign rr_mid     = {ClosR{rr_q[$clog2(ClosR*ClosM)-1:$clog2(ClosM)]}};
  end

  if (ClosM > 1) begin : gen_rr_egr
    assign rr_egr     = {ClosN{rr_q[$clog2(ClosM)-1:0]}};
  end
end

for (genvar r=0; r<ClosR; r++) begin : gen_rr_ingr1
  for (genvar m = 0; m < ClosM; m++) begin : gen_rr_ingr2
    assign rr_ing[r][m] = rr_ing_tmp + $clog2(NumInNode)'(m % NumInNode);
  end
end


// // just use static assignment in this case
// always_ff @(posedge clk_i or negedge rst_ni) begin : p_rand
//   if(!rst_ni) begin
//     rr_ing <= '0;
//   end else begin
//     if (|(gnt_i & req_o)) begin
//       void'(randomize(rr_ing));
//     end
//   end
// end
// assign rr_ing_tmp = '0;

// if (ClosR > 1) begin : gen_rr_mid
//   assign rr_mid     = {ClosR{rr_q[$clog2(ClosR*ClosM)-1:$clog2(ClosM)]}};
// end

// if (ClosM > 1) begin : gen_rr_egr
//   assign rr_egr     = {ClosN{rr_q[$clog2(ClosM)-1:0]}};
// end




// function logic[31:0] lcg_parkmiller(logic[31:0] state);
// begin
//   return 32'((64'(state) * 64'(48271)) % 64'h7fffffff);
// end
// endfunction

// for (genvar r=0; r<ClosR; r++) begin : gen_rr_ingr1
//   for (genvar m = 0; m < ClosM; m++) begin : gen_rr_ingr2
//     // lfsr #(
//     //   .LfsrWidth(4*$clog2(NumInNode)),
//     //   .OutWidth($clog2(NumInNode)),
//     //   .RstVal(r*ClosM + m + 1)
//     // ) lfsr_i (
//     //   .clk_i,
//     //   .rst_ni,
//     //   .en_i(|(gnt_i & req_o)),
//     //   // .en_i(ingress_req[r][m] & ingress_gnt[r][m]),
//     //   .out(rr_ing[r][m])
//     // );

//     always_ff @(posedge clk_i or negedge rst_ni) begin : p_rand
//       if(!rst_ni) begin
//         rr_ing[r][m] <= r*ClosM + m + 1;
//       end else begin
//         if (|(gnt_i & req_o)) begin
//           // void'(randomize(tmp));
//           rr_ing[r][m] <= lcg_parkmiller(rr_ing[r][m]);
//         end
//       end
//     end
//   end
// end


// lfsr #(
//   .LfsrWidth(2*$clog2(ClosM*ClosR*NumInNode)),
//   .OutWidth($clog2(ClosM*ClosR*NumInNode)),
//   .RstVal(1)
// ) lfsr_i (
//   .clk_i,
//   .rst_ni,
//   .en_i(|(gnt_i & req_o)),
//   .out(rr_q)
// );

assign rr_d       = (|(gnt_i & req_o)) ? rr_q + 1'b1 : rr_q;

always_ff @(posedge clk_i or negedge rst_ni) begin : p_rr
  if(!rst_ni) begin
    rr_q     <= '0;
  end else begin
    rr_q     <= rr_d;
  end
end

////////////////////////////////////////////////////////////////////////
// crossbars
////////////////////////////////////////////////////////////////////////

for (genvar r = 0; unsigned'(r) < ClosR; r++) begin : g_ingress
  xbar #(
    .NumIn         ( NumInNode                     ),
    .NumOut        ( ClosM                         ),
    .ReqDataWidth  ( ReqDataWidth + $clog2(NumOut) ),
    .RespDataWidth ( RespDataWidth                 ),
    .RespLat       ( RespLat                       ),
    .WriteRespOn   ( WriteRespOn                   ),
    .ExtPrio       ( 1'b1                          ),
    .BroadCastOn   ( 1'b1                          )
  ) i_ingress_node (
    .clk_i   ( clk_i                                 ),
    .rst_ni  ( rst_ni                                ),
    .req_i   ( req_i[NumInNode * r +: NumInNode]     ),
    .add_i   ( '0                                    ),// ingress nodes perform broadcast
    .wen_i   ( wen_i[NumInNode * r +: NumInNode]     ),
    .wdata_i ( add_wdata[NumInNode * r +: NumInNode] ),
    .gnt_o   ( gnt_o[NumInNode * r +: NumInNode]     ),
    .vld_o   ( vld_o[NumInNode * r +: NumInNode]     ),
    .rdata_o ( rdata_o[NumInNode * r +: NumInNode]   ),
    .rr_i    ( rr_ing[r]                             ),
    .gnt_i   ( ingress_gnt[r]                        ),
    .req_o   ( ingress_req[r]                        ),
    .wdata_o ( ingress_req_data[r]                   ),
    .rdata_i ( ingress_resp_data[r]                  )
  );
end

for (genvar m = 0; unsigned'(m) < ClosM; m++) begin : g_middle
  xbar #(
    .NumIn         ( ClosR                          ),
    .NumOut        ( ClosR                          ),
    .ReqDataWidth  ( ReqDataWidth  + $clog2(ClosN)  ),
    .RespDataWidth ( RespDataWidth                  ),
    .RespLat       ( RespLat                        ),
    .ExtPrio       ( 1'(ClosR>1)                    )
  ) i_mid_node (
    .clk_i   ( clk_i                   ),
    .rst_ni  ( rst_ni                  ),
    .req_i   ( middle_req_in[m]        ),
    .add_i   ( middle_add_in[m]        ),
    .wen_i   ( '0                      ),
    .wdata_i ( middle_req_data_in[m]   ),
    .gnt_o   ( middle_gnt_out[m]       ),
    .vld_o   (                         ),
    .rdata_o ( middle_resp_data_out[m] ),
    .rr_i    ( rr_mid                  ),
    .gnt_i   ( middle_gnt_in[m]        ),
    .req_o   ( middle_req_out[m]       ),
    .wdata_o ( middle_req_data_out[m]  ),
    .rdata_i ( middle_resp_data_in[m]  )
  );
end

for (genvar r = 0; unsigned'(r) < ClosR; r++) begin : g_egress
  xbar #(
    .NumIn         ( ClosM         ),
    .NumOut        ( ClosN         ),
    .ReqDataWidth  ( ReqDataWidth  ),
    .RespDataWidth ( RespDataWidth ),
    .RespLat       ( RespLat       ),
    .ExtPrio       ( 1'(ClosM>1)   )
  ) i_egress_node (
    .clk_i   ( clk_i                       ),
    .rst_ni  ( rst_ni                      ),
    .req_i   ( egress_req[r]               ),
    .add_i   ( egress_add[r]               ),
    .wen_i   ( '0                          ),
    .wdata_i ( egress_req_data[r]          ),
    .gnt_o   ( egress_gnt[r]               ),
    .vld_o   (                             ),
    .rdata_o ( egress_resp_data[r]         ),
    .rr_i    ( rr_egr                      ),
    .gnt_i   ( gnt_i[ClosN * r +: ClosN]   ),
    .req_o   ( req_o[ClosN * r +: ClosN]   ),
    .wdata_o ( wdata_o[ClosN * r +: ClosN] ),
    .rdata_i ( rdata_i[ClosN * r +: ClosN] )
  );
end

////////////////////////////////////////////////////////////////////////
// assertions
////////////////////////////////////////////////////////////////////////

// pragma translate_off
initial begin
  $display("\nClos Net info:\nNumIn=%0d\nNumOut=%0d\nm=%0d\nn=%0d\nr=%0d\n", NumIn, NumOut, ClosM, ClosN, ClosR);
  // these are the LUT limits
  assert(ClosConfig <= 3 && ClosConfig >= 1) else
    $fatal(1,"Unknown clos ClosConfig.");
  assert($clog2(NumOut/NumIn) <= 4) else
    $fatal(1,"Unsupported banking factor for Clos network.");
  assert($clog2(NumOut) <= 15) else
    $fatal(1,"Unsupported NumOut parameterization for Clos network.");

  // make sure the selected config is aligned to powers of 2
  assert(2**$clog2(NumOut) == NumOut) else
    $fatal(1,"NumOut is not aligned with a power of 2.");
  assert(2**$clog2(NumIn) == NumIn) else
    $fatal(1,"NumIn is not aligned with a power of 2.");
  assert(2**$clog2(ClosN) == ClosN) else
    $fatal(1,"ClosN is not aligned with a power of 2.");
  assert(2**$clog2(ClosM) == ClosM) else
    $fatal(1,"ClosM is not aligned with a power of 2.");
  assert(2**$clog2(ClosR) == ClosR) else
    $fatal(1,"ClosR is not aligned with a power of 2.");
end
// pragma translate_on


endmodule
