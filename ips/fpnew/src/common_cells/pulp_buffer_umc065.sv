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

// Regular VT
// BUFM1R, BUFM2R, BUFM3R
// BUFM4R, BUFM6R
// BUFM8R, BUFM12R
// BUFM16R, BUFM20R
// BUFM22RA, BUFM24R
// BUFM26RA, BUFM32R
// BUFM40R, BUFM48R

// Low VT
// BUFM1W, BUFM2W, BUFM3W
// BUFM4W, BUFM6W
// BUFM8W, BUFM12W
// BUFM16W, BUFM20W
// BUFM22WA, BUFM24W
// BUFM26WA, BUFM32W
// BUFM40W, BUFM48W

// High VT
// BUFM1S, BUFM2S, BUFM3S
// BUFM4S, BUFM6S
// BUFM8S, BUFM12S
// BUFM16S, BUFM20S
// BUFM22SA, BUFM24S
// BUFM26SA, BUFM32S
// BUFM40S, BUFM48S

module pulp_buffer
(
    input  logic in_i,
    output logic out_o
);

    BUFM22RA buf_i
    (
        .A(in_i),
        .Z(out_o)
    );

endmodule
