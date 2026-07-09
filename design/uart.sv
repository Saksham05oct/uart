module clk_gen(
    input clk, rst,
    input [16:0] baud,
    output tx_clk, rx_clk
);

int rx_max = 0, tx_max = 0;
int rx_cnt = 0, tx_cnt = 0;

always@(posedge clk) begin
    if(rst) begin
        tx_max <= 0;
        rx_max <= 0;
    end
    else begin
        case(baud)
            4800: begin
                rx_max <= 11'd651; // 10416 / 16 == 651
                tx_max <= 14'd10416;
            end
            9600: begin
                rx_max <= 11'd325;
                tx_max <= 14'd5208;
            end
            14400: begin
                rx_max <= 11'd217;
                tx_max <= 14'd3472;
            end
            19200: begin
                rx_max <= 11'd163;
                tx_max <= 14'd2604;
            end
            38400: begin
                rx_max <= 11'd81;
                tx_max <= 14'd1302;
            end
            57600: begin
                rx_max <= 11'd54;
                tx_max <= 14'd868;
            end
            default: begin
                rx_max <= 11'd325;
                tx_max <= 14'd5208;
            end
        endcase
    end
end

always@(posedge clk) begin
    if(rst) begin
        rx_cnt <= 0;
    end
    else begin
        if(rx_cnt < rx_max) begin
            rx_cnt <= rx_cnt + 1;
        end
        else begin   
            rx_cnt <= 0;
        end
    end
end

assign rx_clk = ( rx_cnt ==rx_max );

always@(posedge clk) begin
    if(rst) begin
        tx_cnt <= 0;
    end
    else begin
        if(tx_cnt < tx_max) begin
            tx_cnt <= tx_cnt + 1;
        end
        else begin 
            tx_cnt <= 0;
        end
    end
end

assign tx_clk = (tx_cnt == tx_max);
endmodule



interface clk_if;
    logic clk, rst;
    logic [16:0] baud;
    logic tx_clk, rx_clk;
endinterface
module uart_tx(
  input clk,
  input tx_clk, tx_start,
  input rst,
  input [7:0] tx_data,
  input [3:0] length,
  input parity_type, parity_en,   // 1-odd 0-even
  input stop2,                    // 2 stop bits
  output reg tx, tx_done, tx_err
  );

  logic [7:0] tx_reg;

  logic start_b = 0;
  logic stop_b  = 1;
  logic parity_bit = 0;

  integer count = 0;

  typedef enum bit [2:0]
  {
  idle = 0,
  start_bit = 1,
  send_data = 2,
  send_parity = 3,
  send_first_stop = 4,
  send_sec_stop = 5,
  done = 6
  } state_type;

  state_type state = idle, next_state = idle;

  //////////////////// parity generator

  always @(posedge clk)
  begin
    if(rst)
    parity_bit <= 1'b0;
    else if(tx_clk && parity_type == 1'b1)     // odd
    begin
      case(length)
        4'd5 : parity_bit <= ^(tx_data[4:0]);
        4'd6 : parity_bit <= ^(tx_data[5:0]);
        4'd7 : parity_bit <= ^(tx_data[6:0]);
        4'd8 : parity_bit <= ^(tx_data[7:0]);
        default : parity_bit <= 1'b0;
      endcase
    end
    else if(tx_clk)
    begin
      case(length)
        4'd5 : parity_bit <= ~^(tx_data[4:0]); // xnor
        4'd6 : parity_bit <= ~^(tx_data[5:0]);
        4'd7 : parity_bit <= ~^(tx_data[6:0]);
        4'd8 : parity_bit <= ~^(tx_data[7:0]);
        default : parity_bit <= 1'b0;
      endcase
    end
  end

  //////////////////// reset detector

  always @(posedge clk)
  begin
    if(rst)
    state <= idle;
    else if(tx_clk)
    state <= next_state;
  end

  //////////////////// next state decoder + output decoder

  always @(*)
  begin
    case(state)

      idle :
      begin
        tx_done = 1'b0;
        tx      = 1'b1;
        tx_reg  = {(8){1'b0}};
        tx_err  = 0;

        if(tx_start)
        next_state = start_bit;
        else
        next_state = idle;
      end

      start_bit :
      begin
        tx_reg     = tx_data;
        tx         = start_b;
        next_state = send_data;
      end

      send_data :
      begin
        if(count < (length - 1))
        begin
          next_state = send_data;
          tx = tx_reg[count];
        end
        else if(parity_en)
        begin
          tx = tx_reg[count];
          next_state = send_parity;
        end
        else
        begin
          tx = tx_reg[count];
          next_state = send_first_stop;
        end
      end

      send_parity :
      begin
        tx = parity_bit;
        next_state = send_first_stop;
      end

      send_first_stop :
      begin
        tx = stop_b;

        if(stop2)
        next_state = send_sec_stop;
        else
        next_state = done;
      end

      send_sec_stop :
      begin
        tx = stop_b;
        next_state = done;
      end

      done :
      begin
        tx_done = 1'b1;
        next_state = idle;
      end

      default :
      next_state = idle;

    endcase
  end

  //////////////////////////////////////////////////////////

  always @(posedge clk)
  begin
    if(rst)
    count <= 0;
    else if(tx_clk)
    begin
      case(state)

        idle :
        begin
          count <= 0;
        end

        start_bit :
        begin
          count <= 0;
        end

        send_data :
        begin
          count <= count + 1;
        end

        send_parity :
        begin
          count <= 0;
        end

        send_first_stop :
        begin
          count <= 0;
        end

        send_sec_stop :
        begin
          count <= 0;
        end

        done :
        begin
          count <= 0;
        end

        default :
        count <= 0;

      endcase
    end
  end

endmodule

module uart_rx(
  input clk,
  input rx_clk, rx_start,
  input rst, rx,
  input [3:0] length,
  input parity_type, parity_en,
  input stop2,
  output reg [7:0] rx_out,
  output logic rx_done, rx_error
  );

  logic parity = 0;
  logic [7:0] datard = 0;
  int count = 0;
  int bit_count = 0;

  typedef enum bit [2:0]{
  idle = 0,
  start_bit = 1,
  recv_data = 2,
  check_parity = 3,
  check_first_stop = 4,
  check_sec_stop = 5,
  done = 6
  } state_type;

  state_type state = idle, next_state = idle;

  /////////////////////////////////////////////////////
  // state register
  /////////////////////////////////////////////////////

  always @(posedge clk) begin
    if(rst)
    state <= idle;
    else if(rx_clk)
    state <= next_state;
  end

  /////////////////////////////////////////////////////
  // next state decoder + output decoder
  /////////////////////////////////////////////////////

  always @(*) begin
    rx_done = 0;
    case(state)
      idle: begin
        rx_done = 0;
        rx_error = 0;
        if(rx_start)
        next_state = start_bit;
        else
        next_state = idle;
      end
      start_bit: begin
        if(count == 7 && rx) begin
          next_state = idle;
        end
        else if(count == 15) begin
          next_state = recv_data;
        end
        else begin
          next_state = start_bit;
        end
      end
      recv_data: begin
        if(count == 7) begin
          datard[7:0] = {rx, datard[7:1]};
        end
        else if(count == 15 &&
        bit_count == (length - 1)) begin

          case(length)
            5 : rx_out = datard[7:3];
            6 : rx_out = datard[7:2];
            7 : rx_out = datard[7:1];
            8 : rx_out = datard[7:0];
            default :
            rx_out = 8'h00;
          endcase
          if(parity_type)
          parity = ^datard;
          else
          parity = ~^datard;

          if(parity_en)
          next_state = check_parity;
          else
          next_state = check_first_stop;
        end
        else begin
          next_state = recv_data;
        end
      end
      check_parity: begin
        if(count == 7) begin

          if(rx == parity)
          rx_error = 1'b0;
          else
          rx_error = 1'b1;
        end
        else if(count == 15) begin
          next_state = check_first_stop;
        end
        else begin
          next_state = check_parity;
        end

      end
      check_first_stop: begin
        if(count == 7) begin

          if(rx != 1'b1)
          rx_error = 1'b1;
          else
          rx_error = 1'b0;
        end
        else if(count == 15) begin
          if(stop2)
          next_state = check_sec_stop;
          else
          next_state = done;
        end
      end
      check_sec_stop: begin
        if(count == 7) begin

          if(rx != 1'b1)
          rx_error = 1'b1;
          else
          rx_error = 1'b0;
        end
        else if(count == 15) begin
          next_state = done;
        end
      end
      done: begin
        rx_done = 1'b1;
        next_state = idle;
        rx_error = 1'b0;
      end
      default:
      next_state = idle;
    endcase
  end

  /////////////////////////////////////////////////////
  // counters
  /////////////////////////////////////////////////////

  always @(posedge clk) begin
    if(rst) begin
      count <= 0;
      bit_count <= 0;
    end
    else if(rx_clk) begin
      case(state)

        idle: begin
          count <= 0;
          bit_count <= 0;
        end
        start_bit: begin

          if(count < 15)
          count <= count + 1;
          else
          count <= 0;
        end
        recv_data: begin
          if(count < 15)
          count <= count + 1;
          else begin
            count <= 0;
            bit_count <= bit_count + 1;
          end
        end
        check_parity: begin
          if(count < 15)
          count <= count + 1;
          else
          count <= 0;
        end
        check_first_stop: begin

          if(count < 15)
          count <= count + 1;
          else
          count <= 0;
        end
        check_sec_stop: begin
          if(count < 15)
          count <= count + 1;
          else
          count <= 0;
        end
        done: begin
          count <= 0;
          bit_count <= 0;
        end
      endcase
    end
  end

endmodule
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
