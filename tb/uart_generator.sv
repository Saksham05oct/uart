typedef class uart_transaction;

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

      @(driver_ready_for_next);
      @(scoreboard_ready_for_next);
    end

    -> generation_done;
  endtask

endclass
