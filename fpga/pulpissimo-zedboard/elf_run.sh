#!/bin/sh

trap "exit" INT TERM
trap "kill 0" EXIT


SCRIPTDIR=$(dirname $0)
UART_TTY=${PULP_ZEDBOARD_UART_TTY:=/dev/ttyUSB0}
UART_BAUDRATE=${PULP_ZEDBOARD_UART_BAUDRATE:=115200}
TERM_EMU=${PULP_ZEDBOARD_TERM_EMU:=minicom -D}

#Execute gdb and connect to openocd via pipe
$OPENOCD/bin/openocd -f $PULP_ZEDBOARD_OPENOCD_CFG &
$PULP_RISCV_GCC_TOOLCHAIN_CI/bin/riscv32-unknown-elf-gdb -x $SCRIPTDIR/elf_run.gdb $1 &
sleep 3
$TERM_EMU $UART_TTY -b $UART_BAUDRATE


