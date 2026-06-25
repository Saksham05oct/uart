#!/bin/bash
set -e

echo "Compiling design and testbench with Verilator..."
verilator --binary --trace -Wno-fatal \
    +incdir+$UVM_HOME/src \
    rtl/clk_gen.sv \
    rtl/uart_tx.sv \
    rtl/uart_rx.sv \
    rtl/uart_top.sv \
    rtl/uart_if.sv \
    tb/uart_ver.sv

echo "Running simulation..."
./obj_dir/Vtb

echo "Simulation complete. Waveform saved to dump.vcd"
