typedef class uart_transaction;

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

        @(posedge uart_vif.tx_baud_clock);
        monitor_to_scoreboard_mbx.put(observed_tx_payload);
      end else if ((uart_vif.rx_serial_in == 1'b0) && (uart_vif.tx_start == 1'b0)) begin
        wait (uart_vif.rx_done == 1'b1);
        observed_rx_payload = uart_vif.rx_parallel_data;
        $display("[MON] Observed UART RX payload: %0d", observed_rx_payload);

        @(posedge uart_vif.tx_baud_clock);
        monitor_to_scoreboard_mbx.put(observed_rx_payload);
      end
    end
  endtask

endclass
