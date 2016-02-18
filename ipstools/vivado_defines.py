#!/usr/bin/env python
# KISS script to load configuration files from IPs

VIVADO_PREAMBLE = """if ![info exists PULP_HSA_SIM] {
    set RTL ../../fe/rtl
    set IPS ../../fe/ips
    set FPGA_IPS ../ips
    set FPGA_RTL ../rtl
}
"""

VIVADO_PREAMBLE_SUBIP = """
# %s
set SRC_%s " \\
"""

VIVADO_PREAMBLE_SUBIP_INCDIRS = """set INC_%s " \\
"""

VIVADO_SUBIP_LIB = "set LIB_%s\n"

VIVADO_POSTAMBLE_SUBIP = """"
"""

VIVADO_ADD_FILES_CMD = "add_files -norecurse -scan_for_includes $SRC_%s\n"

VIVADO_INC_DIRS_PREAMBLE = """set_property include_dirs { 
    ../../fe/rtl/includes \\
"""

VIVADO_INC_DIRS_CMD = "    ../../fe/ips/%s \\\n"

VIVADO_INC_DIRS_POSTAMBLE = "} [current_fileset] \n"
