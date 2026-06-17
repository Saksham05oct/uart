interface uart_if;
  logic clk;
  logic rst;
  logic [16:0] baud;
  logic tx_start;
  logic rx_start;
  logic [7:0] tx_data;
  logic [3:0] length;
  logic parity_type;
  logic parity_en;
  logic stop2;
  logic tx_done;
  logic tx_err;
  logic [7:0] rx_out;
  logic rx_done;
  logic rx_err;
endinterface
