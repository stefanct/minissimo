// ============================================================================= //
//                           COPYRIGHT NOTICE                                    //
// Copyright 2014 Multitherman Laboratory - University of Bologna                //
// ALL RIGHTS RESERVED                                                           //
// This confidential and proprietary software may be used only as authorised by  //
// a licensing agreement from Multitherman Laboratory - University of Bologna.   //
// The entire notice above must be reproduced on all authorized copies and       //
// copies may only be made to the extent permitted by a licensing agreement from //
// Multitherman Laboratory - University of Bologna.                              //
// ============================================================================= //

// ============================================================================= //
// Company:        Multitherman Laboratory @ DEIS - University of Bologna        //
//                    Viale Risorgimento 2 40136                                 //
//                    Bologna - fax 0512093785 -                                 //
//                                                                               //
// Engineer:       Davide Rossi - davide.rossi@unibo.it                          //
//                                                                               //
//                                                                               //
// Additional contributions by:                                                  //
//                                                                               //
//                                                                               //
//                                                                               //
// Create Date:    01/02/2014                                                    //
// Design Name:    AXI 4 INTERCONNECT                                            //
// Module Name:    axi_aw_buffer                                                 //
// Project Name:   PULP                                                          //
// Language:       SystemVerilog                                                 //
//                                                                               //
// Description:   master slice ( FIFO wrapper  ) for address write channel       //
//                                                                               //
// Revision:                                                                     //
// Revision v0.1 - 01/02/2014 : File Created                                     //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
// ============================================================================= //

module axi_aw_buffer
#(
    parameter ID_WIDTH = 4,
    parameter ADDR_WIDTH = 32,
    parameter USER_WIDTH = 6,
    parameter BUFFER_DEPTH = 2
)
(
    
    input logic                   clk_i,
    input logic                   rst_ni,
    input logic                   test_en_i,
    
    input  logic                  slave_valid_i,
    input  logic [ADDR_WIDTH-1:0] slave_addr_i,
    input  logic [2:0]            slave_prot_i,
    input  logic [3:0]            slave_region_i,
    input  logic [7:0]            slave_len_i,
    input  logic [2:0]            slave_size_i,
    input  logic [1:0]            slave_burst_i,
    input  logic                  slave_lock_i,
    input  logic [3:0]            slave_cache_i,
    input  logic [3:0]            slave_qos_i,
    input  logic [ID_WIDTH-1:0]   slave_id_i,
    input  logic [USER_WIDTH-1:0] slave_user_i,
    output logic                  slave_ready_o,
    
    output logic                  master_valid_o,
    output logic [ADDR_WIDTH-1:0] master_addr_o,
    output logic [2:0]            master_prot_o,
    output logic [3:0]            master_region_o,
    output logic [7:0]            master_len_o,
    output logic [2:0]            master_size_o,
    output logic [1:0]            master_burst_o,
    output logic                  master_lock_o,
    output logic [3:0]            master_cache_o,
    output logic [3:0]            master_qos_o,
    output logic [ID_WIDTH-1:0]   master_id_o,
    output logic [USER_WIDTH-1:0] master_user_o,
    input  logic                  master_ready_i  
);
   
   logic [29+ADDR_WIDTH+USER_WIDTH+ID_WIDTH-1:0] s_data_in;
   logic [29+ADDR_WIDTH+USER_WIDTH+ID_WIDTH-1:0] s_data_out;
   
   
   
   assign s_data_in = {slave_cache_i,  slave_prot_i,  slave_lock_i,  slave_burst_i,  slave_size_i,  slave_len_i,  slave_qos_i,  slave_region_i,  slave_addr_i,  slave_user_i,  slave_id_i};
   assign             {master_cache_o, master_prot_o, master_lock_o, master_burst_o, master_size_o, master_len_o, master_qos_o, master_region_o, master_addr_o, master_user_o, master_id_o} = s_data_out;

`ifdef USE_GENERIC_FIFO
   generic_fifo 
   #( 
      .DATA_WIDTH ( 29+ADDR_WIDTH+USER_WIDTH+ID_WIDTH ),
      .DATA_DEPTH ( BUFFER_DEPTH          )
   )
   buffer_i
   (
      .clk       ( clk_i           ),
      .rst_n     ( rst_ni          ),
      .DATA_IN   ( s_data_in       ),
      .VALID_IN  ( slave_valid_i   ),
      .GRANT_OUT ( slave_ready_o   ),
      .DATA_OUT  ( s_data_out      ),
      .VALID_OUT ( master_valid_o  ),
      .GRANT_IN  ( master_ready_i  ),
      .test_en_i ( test_en_i       )
   );
`else
   axi_buffer
   #(
      .DATA_WIDTH(29+ADDR_WIDTH+USER_WIDTH+ID_WIDTH),
      .BUFFER_DEPTH(BUFFER_DEPTH)
   )
   buffer_i
   (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .valid_o(master_valid_o),
      .data_o(s_data_out),
      .ready_i(master_ready_i),
      .valid_i(slave_valid_i),
      .data_i(s_data_in),
      .ready_o(slave_ready_o)
   );
`endif

endmodule
