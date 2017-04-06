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

module cluster_level_shifter_clamp_out
(
    input  logic in_i,
    output logic out_o,
    input logic clamp_i
);


    SHIFT_IN_EN_X10  lsout
    (
        .Z(out_o),
        .A(in_i),
        .R(clamp_i)
    );
endmodule
