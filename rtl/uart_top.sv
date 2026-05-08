`timescale 1ns / 1ps

module uart_top #(
  parameter int CLOCK_FREQUENCY_HZ = 1000000,
  parameter int BAUD_RATE = 9600
) (
  input  logic       clock,
  input  logic       reset,
  input  logic       rx_serial_in,
  input  logic [7:0] tx_parallel_data,
  input  logic       tx_start,
  output logic       tx_serial_out,
  output logic [7:0] rx_parallel_data,
  output logic       tx_done,
  output logic       rx_done
);

  uart_tx #(
    .CLOCK_FREQUENCY_HZ(CLOCK_FREQUENCY_HZ),
    .BAUD_RATE(BAUD_RATE)
  ) uart_tx_inst (
    .clock(clock),
    .reset(reset),
    .tx_start(tx_start),
    .tx_parallel_data(tx_parallel_data),
    .tx_serial_out(tx_serial_out),
    .tx_done(tx_done)
  );

  uart_rx #(
    .CLOCK_FREQUENCY_HZ(CLOCK_FREQUENCY_HZ),
    .BAUD_RATE(BAUD_RATE)
  ) uart_rx_inst (
    .clock(clock),
    .reset(reset),
    .rx_serial_in(rx_serial_in),
    .rx_done(rx_done),
    .rx_parallel_data(rx_parallel_data)
  );

endmodule
