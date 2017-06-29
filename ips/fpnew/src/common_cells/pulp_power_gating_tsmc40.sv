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

module pulp_power_gating
  (
   input  logic sleep_i,
   output logic sleepout_o
   );
   
   HEADBUFTIE16_X1M_A9TR40 power_gate_i
     (
      .SLEEP(sleep_i),
      .SLEEPOUT(sleepout_o),
      );
   
endmodule