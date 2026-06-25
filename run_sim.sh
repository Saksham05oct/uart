#!/bin/bash
# Exit immediately if any command exits with a non-zero status
set -e

echo "========================================="
echo "   Compiling UART Design with Verilator  "
echo "========================================="

# Compile the design using Verilator with trace (VCD) and timing enabled
verilator --binary -j 0 --trace --timing tb/tb_uart.sv rtl/clk_gen.sv rtl/uart_tx.sv rtl/uart_rx.sv rtl/uart_top.sv

echo "========================================="
echo "        Running Verilator Simulation     "
echo "========================================="

# Execute the generated binary
./obj_dir/Vtb_uart

echo "========================================="
echo "         Opening Waveform in GTKWave     "
echo "========================================="

# Launch GTKWave in the background
gtkwave waveform.vcd &
