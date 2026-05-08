`timescale 1ns / 1ps

interface uart_if;
  logic       clock;
  logic       tx_baud_clock;
  logic       rx_baud_clock;
  logic       reset;
  logic       rx_serial_in;
  logic [7:0] tx_parallel_data;
  logic       tx_start;
  logic       tx_serial_out;
  logic [7:0] rx_parallel_data;
  logic       tx_done;
  logic       rx_done;
endinterface
