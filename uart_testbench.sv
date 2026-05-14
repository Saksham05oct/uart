// ============================================================
// UART SystemVerilog Testbench (EDA Playground Combined)
// ============================================================
`timescale 1ns / 1ps

// Forward declarations
typedef class uart_transaction;
typedef class uart_generator;
typedef class uart_driver;
typedef class uart_monitor;
typedef class uart_scoreboard;
typedef class uart_environment;

// Global log file handle (accessible from all classes and modules)
integer log_file;

// ============================================================
// Transaction
// ============================================================
typedef enum bit {
  UART_WRITE = 1'b0,
  UART_READ  = 1'b1
} uart_operation_t;

class uart_transaction;

  randc uart_operation_t operation;

  bit       rx_serial_value;
  rand bit [7:0] tx_payload;
  bit       tx_start;
  bit       tx_serial_value;
  bit [7:0] rx_payload;
  bit       tx_done;
  bit       rx_done;

  function automatic uart_transaction copy();
    copy = new();
    copy.rx_serial_value = this.rx_serial_value;
    copy.tx_payload = this.tx_payload;
    copy.tx_start = this.tx_start;
    copy.tx_serial_value = this.tx_serial_value;
    copy.rx_payload = this.rx_payload;
    copy.tx_done = this.tx_done;
    copy.rx_done = this.rx_done;
    copy.operation = this.operation;
  endfunction

endclass

// ============================================================
// Generator
// ============================================================
class uart_generator;

  uart_transaction generated_transaction;

  mailbox #(uart_transaction) generator_to_driver_mbx;

  event generation_done;
  event driver_ready_for_next;
  event scoreboard_ready_for_next;

  int transaction_count = 0;

  function new(mailbox #(uart_transaction) generator_to_driver_mbx);
    this.generator_to_driver_mbx = generator_to_driver_mbx;
    generated_transaction = new();
  endfunction

  task run();
    repeat (transaction_count) begin
      assert(generated_transaction.randomize())
        else $error("[GEN] Randomization failed");

      generator_to_driver_mbx.put(generated_transaction.copy());
      $display("[GEN] Operation: %0s, TX payload: %0d",
               generated_transaction.operation.name(),
               generated_transaction.tx_payload);
      $fdisplay(log_file, "[%0t] [GEN] Operation: %0s, TX payload: %0d (0x%0h)",
               $time, generated_transaction.operation.name(),
               generated_transaction.tx_payload, generated_transaction.tx_payload);

      @(driver_ready_for_next);
      @(scoreboard_ready_for_next);
    end

    -> generation_done;
  endtask

endclass

// ============================================================
// Driver
// ============================================================
class uart_driver;

  virtual uart_if uart_vif;

  uart_transaction current_transaction;

  mailbox #(uart_transaction) generator_to_driver_mbx;
  mailbox #(bit [7:0]) driver_to_scoreboard_mbx;

  event driver_ready_for_next;

  bit [7:0] received_serial_payload;

  function new(
    mailbox #(bit [7:0]) driver_to_scoreboard_mbx,
    mailbox #(uart_transaction) generator_to_driver_mbx
  );
    this.generator_to_driver_mbx = generator_to_driver_mbx;
    this.driver_to_scoreboard_mbx = driver_to_scoreboard_mbx;
  endfunction

  task reset();
    uart_vif.reset <= 1'b1;
    uart_vif.tx_parallel_data <= 8'h00;
    uart_vif.tx_start <= 1'b0;
    uart_vif.rx_serial_in <= 1'b1;

    // Use system clock during reset (baud clock is frozen while reset is active)
    repeat (20) @(posedge uart_vif.clock);
    uart_vif.reset <= 1'b0;

    // Wait for baud clock to start toggling after reset release
    repeat (10) @(posedge uart_vif.clock);

    $display("[DRV] Reset complete");
    $display("----------------------------------------");
    $fdisplay(log_file, "[%0t] [DRV] Reset complete", $time);
    $fdisplay(log_file, "----------------------------------------");
  endtask

  task run();
    forever begin
      generator_to_driver_mbx.get(current_transaction);

      if (current_transaction.operation == UART_WRITE) begin
        @(posedge uart_vif.tx_baud_clock);
        uart_vif.reset <= 1'b0;
        uart_vif.tx_start <= 1'b1;
        uart_vif.rx_serial_in <= 1'b1;
        uart_vif.tx_parallel_data <= current_transaction.tx_payload;

        @(posedge uart_vif.tx_baud_clock);
        uart_vif.tx_start <= 1'b0;

        driver_to_scoreboard_mbx.put(current_transaction.tx_payload);
        $display("[DRV] TX payload driven: %0d", current_transaction.tx_payload);
        $fdisplay(log_file, "[%0t] [DRV] TX payload driven: %0d (0x%0h)", $time, current_transaction.tx_payload, current_transaction.tx_payload);

        wait (uart_vif.tx_done == 1'b1);
        -> driver_ready_for_next;
      end else begin
        @(posedge uart_vif.rx_baud_clock);
        uart_vif.reset <= 1'b0;
        uart_vif.rx_serial_in <= 1'b0;
        uart_vif.tx_start <= 1'b0;

        @(posedge uart_vif.rx_baud_clock);

        for (int bit_index = 0; bit_index <= 7; bit_index++) begin
          @(posedge uart_vif.rx_baud_clock);
          uart_vif.rx_serial_in <= $urandom;
          received_serial_payload[bit_index] = uart_vif.rx_serial_in;
        end

        driver_to_scoreboard_mbx.put(received_serial_payload);
        $display("[DRV] RX payload driven: %0d", received_serial_payload);
        $fdisplay(log_file, "[%0t] [DRV] RX payload driven: %0d (0x%0h)", $time, received_serial_payload, received_serial_payload);

        wait (uart_vif.rx_done == 1'b1);
        uart_vif.rx_serial_in <= 1'b1;
        -> driver_ready_for_next;
      end
    end
  endtask

endclass

// ============================================================
// Monitor
// ============================================================
class uart_monitor;

  uart_transaction observed_transaction;

  mailbox #(bit [7:0]) monitor_to_scoreboard_mbx;

  bit [7:0] observed_tx_payload;
  bit [7:0] observed_rx_payload;

  virtual uart_if uart_vif;

  function new(mailbox #(bit [7:0]) monitor_to_scoreboard_mbx);
    this.monitor_to_scoreboard_mbx = monitor_to_scoreboard_mbx;
  endfunction

  task run();
    forever begin
      @(posedge uart_vif.tx_baud_clock);

      if ((uart_vif.tx_start == 1'b1) && (uart_vif.rx_serial_in == 1'b1)) begin
        @(posedge uart_vif.tx_baud_clock);

        for (int bit_index = 0; bit_index <= 7; bit_index++) begin
          @(posedge uart_vif.tx_baud_clock);
          observed_tx_payload[bit_index] = uart_vif.tx_serial_out;
        end

        $display("[MON] Observed UART TX payload: %0d", observed_tx_payload);
        $fdisplay(log_file, "[%0t] [MON] Observed UART TX payload: %0d (0x%0h)", $time, observed_tx_payload, observed_tx_payload);

        @(posedge uart_vif.tx_baud_clock);
        monitor_to_scoreboard_mbx.put(observed_tx_payload);
      end else if ((uart_vif.rx_serial_in == 1'b0) && (uart_vif.tx_start == 1'b0)) begin
        wait (uart_vif.rx_done == 1'b1);
        observed_rx_payload = uart_vif.rx_parallel_data;
        $display("[MON] Observed UART RX payload: %0d", observed_rx_payload);
        $fdisplay(log_file, "[%0t] [MON] Observed UART RX payload: %0d (0x%0h)", $time, observed_rx_payload, observed_rx_payload);

        @(posedge uart_vif.tx_baud_clock);
        monitor_to_scoreboard_mbx.put(observed_rx_payload);
      end
    end
  endtask

endclass

// ============================================================
// Scoreboard
// ============================================================
class uart_scoreboard;

  mailbox #(bit [7:0]) driver_to_scoreboard_mbx;
  mailbox #(bit [7:0]) monitor_to_scoreboard_mbx;

  bit [7:0] expected_payload;
  bit [7:0] observed_payload;

  event scoreboard_ready_for_next;

  function new(
    mailbox #(bit [7:0]) driver_to_scoreboard_mbx,
    mailbox #(bit [7:0]) monitor_to_scoreboard_mbx
  );
    this.driver_to_scoreboard_mbx = driver_to_scoreboard_mbx;
    this.monitor_to_scoreboard_mbx = monitor_to_scoreboard_mbx;
  endfunction

  task run();
    forever begin
      driver_to_scoreboard_mbx.get(expected_payload);
      monitor_to_scoreboard_mbx.get(observed_payload);

      $display("[SCO] Expected: %0d, observed: %0d", expected_payload, observed_payload);
      $fdisplay(log_file, "[%0t] [SCO] Expected: %0d (0x%0h), Observed: %0d (0x%0h)",
               $time, expected_payload, expected_payload, observed_payload, observed_payload);
      if (expected_payload == observed_payload) begin
        $display("DATA MATCHED");
        $fdisplay(log_file, "[%0t] >>> DATA MATCHED <<<", $time);
      end else begin
        $display("DATA MISMATCHED");
        $fdisplay(log_file, "[%0t] >>> DATA MISMATCHED <<<", $time);
      end

      $display("----------------------------------------");
      $fdisplay(log_file, "----------------------------------------");

      -> scoreboard_ready_for_next;
    end
  endtask

endclass

// ============================================================
// Environment
// ============================================================
class uart_environment;

  uart_generator  generator;
  uart_driver     driver;
  uart_monitor    monitor;
  uart_scoreboard scoreboard;

  event driver_ready_for_next;
  event scoreboard_ready_for_next;

  mailbox #(uart_transaction) generator_to_driver_mbx;
  mailbox #(bit [7:0]) driver_to_scoreboard_mbx;
  mailbox #(bit [7:0]) monitor_to_scoreboard_mbx;

  virtual uart_if uart_vif;

  function new(virtual uart_if uart_vif);
    generator_to_driver_mbx = new();
    driver_to_scoreboard_mbx = new();
    monitor_to_scoreboard_mbx = new();

    generator = new(generator_to_driver_mbx);
    driver = new(driver_to_scoreboard_mbx, generator_to_driver_mbx);
    monitor = new(monitor_to_scoreboard_mbx);
    scoreboard = new(driver_to_scoreboard_mbx, monitor_to_scoreboard_mbx);

    this.uart_vif = uart_vif;
    driver.uart_vif = this.uart_vif;
    monitor.uart_vif = this.uart_vif;

    generator.driver_ready_for_next = driver_ready_for_next;
    driver.driver_ready_for_next = driver_ready_for_next;

    generator.scoreboard_ready_for_next = scoreboard_ready_for_next;
    scoreboard.scoreboard_ready_for_next = scoreboard_ready_for_next;
  endfunction

  task pre_test();
    driver.reset();
  endtask

  task test();
    fork
      generator.run();
      driver.run();
      monitor.run();
      scoreboard.run();
    join_any
  endtask

  task post_test();
    wait (generator.generation_done.triggered);
    $finish();
  endtask

  task run();
    pre_test();
    test();
    post_test();
  endtask

endclass

// ============================================================
// Top-level Testbench Module
// ============================================================
module tb;

  uart_if uart_vif();
  uart_environment environment;

  // Use faster baud rate ratio for EDA Playground (CLOCKS_PER_BAUD = 2)
  uart_top #(
    .CLOCK_FREQUENCY_HZ(19200),
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
    environment.generator.transaction_count = 500;
    environment.run();
  end

  // Open output.log for EDA Playground file viewer
  initial begin
    log_file = $fopen("output.log", "w");
    $fdisplay(log_file, "========================================");
    $fdisplay(log_file, " UART Verification - Simulation Log");
    $fdisplay(log_file, " Simulator: Synopsys VCS");
    $fdisplay(log_file, " Clock: 19200 Hz, Baud: 9600");
    $fdisplay(log_file, " Transactions: 500");
    $fdisplay(log_file, "========================================");
    $fdisplay(log_file, "");
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

  // Safety timeout to prevent EDA Playground from killing the simulation
  initial begin
    #100_000_000;
    $fdisplay(log_file, "");
    $fdisplay(log_file, "[TIMEOUT] Simulation reached maximum time limit at %0t", $time);
    $fdisplay(log_file, "========================================");
    $fclose(log_file);
    $display("[TIMEOUT] Simulation reached maximum time limit");
    $finish();
  end

  assign uart_vif.tx_baud_clock = dut.uart_tx_inst.baud_sample_clock;
  assign uart_vif.rx_baud_clock = dut.uart_rx_inst.baud_sample_clock;

endmodule

