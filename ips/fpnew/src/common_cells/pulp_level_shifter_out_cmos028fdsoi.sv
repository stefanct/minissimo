// UWVR VOLTAGES ARE INVERTED: VDDI = VOUT, VDDO = VIN
// C12T32DG_LLU_LSINX26

`include "ulpsoc_defines.sv"

module pulp_level_shifter_out
(
    input  logic in_i,
    output logic out_o
);


`ifdef CMOS28FDSOI_8T
    C8T28SOITV_LRV_LSOUTX32 lsout
    (
        .Z(out_o),
        .A(in_i)
    )
`endif


`ifdef CMOS28FDSOI_12T_UWVR
    C12T32DG_LLU_LSINX26   lsout
    (
        .Z(out_o),
        .A(in_i)
    );
`endif 


   
endmodule
