`timescale 1ns / 1ps

typedef class uart_environment;

module tb;

  uart_if uart_vif();
  uart_environment environment;

  uart_top #(
    .CLOCK_FREQUENCY_HZ(1000000),
    .BAUD_RATE(9600)
  ) dut (
    .clock(uart_vif.clock),
    .reset(uart_vif.reset),
    .rx_serial_in(uart_vif.rx_serial_in),
    .tx_parallel_data(uart_vif.tx_parallel_data),
    .tx_start(uart_vif.tx_start),
    .tx_serial_out(uart_vif.tx_serial_out),
    .rx_parallel_data(uart_vif.rx_parallel_data),
    .tx_done(uart_vif.tx_done),
    .rx_done(uart_vif.rx_done)
  );

  initial begin
    uart_vif.clock <= 1'b0;
  end

  always #10 uart_vif.clock <= ~uart_vif.clock;

  initial begin
    environment = new(uart_vif);
    environment.generator.transaction_count = 5;
    environment.run();
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

  assign uart_vif.tx_baud_clock = dut.uart_tx_inst.baud_sample_clock;
  assign uart_vif.rx_baud_clock = dut.uart_rx_inst.baud_sample_clock;

endmodule
