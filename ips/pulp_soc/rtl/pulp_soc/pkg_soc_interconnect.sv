package pkg_soc_interconnect;

    typedef struct packed {
        logic [31:0] idx;
        logic [31:0] start_addr;
        logic [31:0] end_addr;
    } addr_map_rule_t;

endpackage : pkg_soc_interconnect
