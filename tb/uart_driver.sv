typedef class uart_transaction;

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

    repeat (5) @(posedge uart_vif.tx_baud_clock);
    uart_vif.reset <= 1'b0;
    @(posedge uart_vif.tx_baud_clock);

    $display("[DRV] Reset complete");
    $display("----------------------------------------");
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

        wait (uart_vif.rx_done == 1'b1);
        uart_vif.rx_serial_in <= 1'b1;
        -> driver_ready_for_next;
      end
    end
  endtask

endclass
