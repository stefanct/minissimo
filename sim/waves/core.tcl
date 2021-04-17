# add fc
set rvcores [find instances -recursive -bydu riscv_core -nodu]
set fpuprivate [find instances -recursive -bydu fpnew_top]
set rvpmp [find instances -recursive -bydu riscv_pmp]

if {$rvcores ne ""} {
  set rvprefetch [find instances -recursive -bydu riscv_prefetch_L0_buffer -nodu]

  add wave -group "Core"  -group "Main"                                     $rvcores/*
  add wave -group "Core"  -group "IF Stage" -group "Hwlp Ctrl"              $rvcores/if_stage_i/hwloop_controller_i/*
  if {$rvprefetch ne ""} {
    add wave -group "Core"  -group "IF Stage" -group "Prefetch" -group "L0"   $rvcores/if_stage_i/prefetch_128/prefetch_buffer_i/L0_buffer_i/*
    add wave -group "Core"  -group "IF Stage" -group "Prefetch"               $rvcores/if_stage_i/prefetch_128/prefetch_buffer_i/*
  } {
    add wave -group "Core"  -group "IF Stage" -group "Prefetch" -group "FIFO" $rvcores/if_stage_i/prefetch_32/prefetch_buffer_i/fifo_i/*
    add wave -group "Core"  -group "IF Stage" -group "Prefetch"               $rvcores/if_stage_i/prefetch_32/prefetch_buffer_i/*
  }
  add wave -group "Core"  -group "IF Stage"                                 $rvcores/if_stage_i/*
  add wave -group "Core"  -group "ID Stage"                                 $rvcores/id_stage_i/*
  add wave -group "Core"  -group "RF"                                       $rvcores/id_stage_i/registers_i/riscv_register_file_i/mem
  add wave -group "Core"  -group "RF_FP"                                    $rvcores/id_stage_i/registers_i/riscv_register_file_i/mem_fp
  add wave -group "Core"  -group "Decoder"                                  $rvcores/id_stage_i/decoder_i/*
  add wave -group "Core"  -group "Controller"                               $rvcores/id_stage_i/controller_i/*
  add wave -group "Core"  -group "Int Ctrl"                                 $rvcores/id_stage_i/int_controller_i/*
  add wave -group "Core"  -group "Hwloop Regs"                              $rvcores/id_stage_i/hwloop_regs_i/*
  add wave -group "Core"  -group "EX Stage" -group "ALU"                    $rvcores/ex_stage_i/alu_i/*
  add wave -group "Core"  -group "EX Stage" -group "ALU_DIV"                $rvcores/ex_stage_i/alu_i/int_div/div_i/*
  add wave -group "Core"  -group "EX Stage" -group "MUL"                    $rvcores/ex_stage_i/mult_i/*
  if {$fpuprivate ne ""} {
    add wave -group "Core"  -group "EX Stage" -group "APU_DISP"             $rvcores/ex_stage_i/genblk1/apu_disp_i/*
    add wave -group "Core"  -group "EX Stage" -group "FPU"               $rvcores/ex_stage_i/genblk1/genblk1/i_fpnew_bulk/*
  }
  add wave -group "Core"  -group "EX Stage"                                 $rvcores/ex_stage_i/*
  add wave -group "Core"  -group "LSU"                                      $rvcores/load_store_unit_i/*
  if {$rvpmp ne ""} {
    add wave -group "Core"  -group "PMP"                                    $rvcores/RISCY_PMP/pmp_unit_i/*
  }

  add wave -group "Core" -group "CSR" -group "PCCR" -radix d -radixshowbase 0 -label {PCCR[ 0] Cycles} $rvcores/cs_registers_i/PCCR_q\[0\]
  add wave -group "Core" -group "CSR" -group "PCCR" -radix d -radixshowbase 0 -label {PCCR[ 1] Insts} $rvcores/cs_registers_i/PCCR_q\[1\]
  add wave -group "Core" -group "CSR" -group "PCCR" -radix d -radixshowbase 0 -label {PCCR[ 2] LD Stalls} $rvcores/cs_registers_i/PCCR_q\[2\]
  add wave -group "Core" -group "CSR" -group "PCCR" -radix d -radixshowbase 0 -label {PCCR[ 3] J/B Stalls} $rvcores/cs_registers_i/PCCR_q\[3\]
  add wave -group "Core" -group "CSR" -group "PCCR" -radix d -radixshowbase 0 -label {PCCR[ 4] $ Misses} $rvcores/cs_registers_i/PCCR_q\[4\]
  add wave -group "Core" -group "CSR" -group "PCCR" -radix d -radixshowbase 0 -label {PCCR[ 5] Loads} $rvcores/cs_registers_i/PCCR_q\[5\]
  add wave -group "Core" -group "CSR" -group "PCCR" -radix d -radixshowbase 0 -label {PCCR[ 6] Stores} $rvcores/cs_registers_i/PCCR_q\[6\]
  add wave -group "Core" -group "CSR" -group "PCCR" -radix d -radixshowbase 0 -label {PCCR[ 7] Jumps} $rvcores/cs_registers_i/PCCR_q\[7\]
  add wave -group "Core" -group "CSR" -group "PCCR" -radix d -radixshowbase 0 -label {PCCR[ 8] Branches} $rvcores/cs_registers_i/PCCR_q\[8\]
  add wave -group "Core" -group "CSR" -group "PCCR" -radix d -radixshowbase 0 -label {PCCR[ 9] B taken} $rvcores/cs_registers_i/PCCR_q\[9\]
  add wave -group "Core" -group "CSR" -group "PCCR" -radix d -radixshowbase 0 -label {PCCR[10] Compr. Insts} $rvcores/cs_registers_i/PCCR_q\[10\]
  add wave -group "Core" -group "CSR" -group "PCCR" -radix d -radixshowbase 0 -label {PCCR[11] ELW} $rvcores/cs_registers_i/PCCR_q\[11\]
  add wave -group "Core" -group "CSR" -group "PCCR" -radix d -radixshowbase 0 -label {PCCR[12] Ext. 0} $rvcores/cs_registers_i/PCCR_q\[12\]
  add wave -group "Core" -group "CSR" -group "PCCR" -radix d -radixshowbase 0 -label {PCCR[13] APU Conf.} $rvcores/cs_registers_i/PCCR_q\[13\]
  add wave -group "Core" -group "CSR" -group "PCCR" -radix d -radixshowbase 0 -label {PCCR[14] APU Cont.} $rvcores/cs_registers_i/PCCR_q\[14\]
  add wave -group "Core" -group "CSR" -group "PCCR" -radix d -radixshowbase 0 -label {PCCR[15] APU Dep.} $rvcores/cs_registers_i/PCCR_q\[15\]
  add wave -group "Core" -group "CSR" -group "PCCR" -radix d -radixshowbase 0 -label {PCCR[16] WB Cont.} $rvcores/cs_registers_i/PCCR_q\[16\]

  add wave -group "Core"  -group "CSR"                                      $rvcores/cs_registers_i/*
}

configure wave -namecolwidth  250
configure wave -valuecolwidth 240
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -timelineunits ns
