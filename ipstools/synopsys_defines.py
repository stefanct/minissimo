#!/usr/bin/env python
#
# synopsys_defines.py
# Francesco Conti <f.conti@unibo.it>
#
# Copyright (C) 2015 ETH Zurich, University of Bologna
# All rights reserved.
#
# This software may be modified and distributed under the terms
# of the BSD license.  See the LICENSE file for details.
#

# templates for vcompile.csh scripts

SYNOPSYS_ANALYZE_PREAMBLE = "puts \"${Green}Analyzing %s ${NC}\"\n"

SYNOPSYS_ANALYZE_PREAMBLE_SUBIP = "\nputs \"${Green}--> compile %s${NC}\"\n"

SYNOPSYS_ANALYZE_SV_CMD   = "analyze -format sverilog %s -work work ${%s_PATH}/%s\n"
SYNOPSYS_ANALYZE_V_CMD    = "analyze -format verilog  %s -work work ${%s_PATH}/%s\n"
SYNOPSYS_ANALYZE_VHDL_CMD = "analyze -format vhdl        -work work ${%s_PATH}/%s\n"

