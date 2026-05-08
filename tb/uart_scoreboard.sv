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
      if (expected_payload == observed_payload) begin
        $display("DATA MATCHED");
      end else begin
        $display("DATA MISMATCHED");
      end

      $display("----------------------------------------");

      -> scoreboard_ready_for_next;
    end
  endtask

endclass
