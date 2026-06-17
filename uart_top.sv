module uart_top(
    input clk,
    input rst,
    input [16:0] baud,
    input tx_start,
    input rx_start,
    input [7:0] tx_data,
    input [3:0] length,
    input parity_type,
    input parity_en,
    input stop2,
    output tx,
    output tx_done,
    output tx_err,
    output [7:0] rx_out,
    output rx_done,
    output rx_err
);

//////////////////////////////////////////////////
// Clock Generator
//////////////////////////////////////////////////

wire tx_clk;
wire rx_clk;

clk_gen clk_gen_inst(
    .clk(clk),
    .rst(rst),
    .baud(baud),
    .tx_clk(tx_clk),
    .rx_clk(rx_clk)
);

wire loopback_tx_rx;

//////////////////////////////////////////////////
// UART TX
//////////////////////////////////////////////////

uart_tx tx_inst(
    .clk(clk),
    .tx_clk(tx_clk),
    .tx_start(tx_start),
    .rst(rst),
    .tx_data(tx_data),
    .length(length),
    .parity_type(parity_type),
    .parity_en(parity_en),
    .stop2(stop2),
    .tx(loopback_tx_rx),
    .tx_done(tx_done),
    .tx_err(tx_err)
);

//////////////////////////////////////////////////
// UART RX
//////////////////////////////////////////////////

uart_rx rx_inst(
    .clk(clk),
    .rx_clk(rx_clk),
    .rx_start(rx_start),
    .rst(rst),
    .rx(loopback_tx_rx),
    .length(length),
    .parity_type(parity_type),
    .parity_en(parity_en),
    .stop2(stop2),
    .rx_out(rx_out),
    .rx_done(rx_done),
    .rx_error(rx_err)
);

assign tx = loopback_tx_rx;

endmodule
