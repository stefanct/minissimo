/* Copyright (C) 2017 ETH Zurich, University of Bologna
 * All rights reserved.
 *
 * This code is under development and not yet released to the public.
 * Until it is released, the code is under the copyright of ETH Zurich and
 * the University of Bologna, and may contain confidential and/or unpublished 
 * work. Any reuse/redistribution is strictly forbidden without written
 * permission from ETH Zurich.
 *
 * Bug fixes and contributions will eventually be released under the
 * SolderPad open hardware license in the context of the PULP platform
 * (http://www.pulp-platform.org), under the copyright of ETH Zurich and the
 * University of Bologna.
 */

// UWVR VOLTAGES ARE INVERTED: VDDI = VOUT, VDDO = VIN
// C12T32DG_LLU_LSINX26

`include "ulpsoc_defines.sv"

module cluster_level_shifter_out
(
    input  logic in_i,
    output logic out_o
);

`ifdef CMOS28FDSOI_8T
    C8T28SOITV_LRV_LSOUTX32 lsout
    (
        .Z(out_o),
        .A(in_i)
    );
`endif


`ifdef CMOS28FDSOI_12T_UWVR
    C12T32DG_LLU_LSINX26  lsout
    (
        .Z(out_o),
        .A(in_i)
    );
`endif 

endmodule
