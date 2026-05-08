typedef class uart_transaction;
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
