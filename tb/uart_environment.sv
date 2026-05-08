typedef class uart_transaction;
typedef class uart_generator;
typedef class uart_driver;
typedef class uart_monitor;
typedef class uart_scoreboard;

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
