#!/bin/bash

# Exit on error
set -e

# Set UVM_HOME to your UVM installation path (default to standard Verilator/SystemVerilog library path if unset)
if [ -z "$UVM_HOME" ]; then
    # Adjust this path to point to your UVM 1.2 source directory if different
    export UVM_HOME="/usr/share/verilator/include/vltstd"
fi

echo "================================================================="
echo " Compiling with Verilator..."
echo "================================================================="
verilator --binary --trace -Wno-fatal \
    +incdir+$UVM_HOME/src \
    rtl/clk_gen.sv \
    rtl/uart_tx.sv \
    rtl/uart_rx.sv \
    rtl/uart_top.sv \
    rtl/uart_if.sv \
    tb/uart_ver.sv

echo "================================================================="
echo " Running Simulation..."
echo "================================================================="
./obj_dir/Vtb

echo "================================================================="
echo " Simulation Complete! 'dump.vcd' has been generated."
echo " To view the waveform, run: gtkwave dump.vcd"
echo "================================================================="
