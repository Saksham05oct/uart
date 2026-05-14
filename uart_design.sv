// Code your design here
// ============================================================
// UART Interface
// ============================================================
`timescale 1ns / 1ps

interface uart_if;
  logic       clock;
  logic       tx_baud_clock;
  logic       rx_baud_clock;
  logic       reset;
  logic       rx_serial_in;
  logic [7:0] tx_parallel_data;
  logic       tx_start;
  logic       tx_serial_out;
  logic [7:0] rx_parallel_data;
  logic       tx_done;
  logic       rx_done;
endinterface

// ============================================================
// UART Transmitter
// ============================================================
module uart_tx #(
  parameter int CLOCK_FREQUENCY_HZ = 1000000,
  parameter int BAUD_RATE = 9600
) (
  input  logic       clock,
  input  logic       reset,
  input  logic       tx_start,
  input  logic [7:0] tx_parallel_data,
  output logic       tx_serial_out,
  output logic       tx_done
);

  localparam int CLOCKS_PER_BAUD = CLOCK_FREQUENCY_HZ / BAUD_RATE;

  typedef enum logic [1:0] {
    TX_IDLE,
    TX_SHIFT_DATA
  } tx_state_t;

  tx_state_t tx_state;

  int baud_clock_count;
  int transmitted_bit_index;

  logic       baud_sample_clock;
  logic [7:0] transmit_shift_data;

  always_ff @(posedge clock) begin
    if (reset) begin
      baud_clock_count <= 0;
      baud_sample_clock <= 1'b0;
    end else if (baud_clock_count < CLOCKS_PER_BAUD / 2) begin
      baud_clock_count <= baud_clock_count + 1;
    end else begin
      baud_clock_count <= 0;
      baud_sample_clock <= ~baud_sample_clock;
    end
  end

  always_ff @(posedge baud_sample_clock) begin
    if (reset) begin
      tx_state <= TX_IDLE;
      tx_serial_out <= 1'b1;
      tx_done <= 1'b0;
      transmitted_bit_index <= 0;
      transmit_shift_data <= 8'h00;
    end else begin
      case (tx_state)
        TX_IDLE: begin
          transmitted_bit_index <= 0;
          tx_serial_out <= 1'b1;
          tx_done <= 1'b0;

          if (tx_start) begin
            tx_state <= TX_SHIFT_DATA;
            transmit_shift_data <= tx_parallel_data;
            tx_serial_out <= 1'b0;
          end
        end

        TX_SHIFT_DATA: begin
          if (transmitted_bit_index <= 7) begin
            tx_serial_out <= transmit_shift_data[transmitted_bit_index];
            transmitted_bit_index <= transmitted_bit_index + 1;
          end else begin
            tx_serial_out <= 1'b1;
            tx_done <= 1'b1;
            transmitted_bit_index <= 0;
            tx_state <= TX_IDLE;
          end
        end

        default: begin
          tx_state <= TX_IDLE;
        end
      endcase
    end
  end

endmodule

// ============================================================
// UART Receiver
// ============================================================
module uart_rx #(
  parameter int CLOCK_FREQUENCY_HZ = 1000000,
  parameter int BAUD_RATE = 9600
) (
  input  logic       clock,
  input  logic       reset,
  input  logic       rx_serial_in,
  output logic       rx_done,
  output logic [7:0] rx_parallel_data
);

  localparam int CLOCKS_PER_BAUD = CLOCK_FREQUENCY_HZ / BAUD_RATE;

  typedef enum logic [1:0] {
    RX_IDLE,
    RX_CAPTURE_DATA
  } rx_state_t;

  rx_state_t rx_state;

  int baud_clock_count;
  int received_bit_index;

  logic baud_sample_clock;

  always_ff @(posedge clock) begin
    if (reset) begin
      baud_clock_count <= 0;
      baud_sample_clock <= 1'b0;
    end else if (baud_clock_count < CLOCKS_PER_BAUD / 2) begin
      baud_clock_count <= baud_clock_count + 1;
    end else begin
      baud_clock_count <= 0;
      baud_sample_clock <= ~baud_sample_clock;
    end
  end

  always_ff @(posedge baud_sample_clock) begin
    if (reset) begin
      rx_state <= RX_IDLE;
      rx_parallel_data <= 8'h00;
      received_bit_index <= 0;
      rx_done <= 1'b0;
    end else begin
      case (rx_state)
        RX_IDLE: begin
          rx_parallel_data <= 8'h00;
          received_bit_index <= 0;
          rx_done <= 1'b0;

          if (rx_serial_in == 1'b0) begin
            rx_state <= RX_CAPTURE_DATA;
          end
        end

        RX_CAPTURE_DATA: begin
          if (received_bit_index <= 7) begin
            rx_parallel_data <= {rx_serial_in, rx_parallel_data[7:1]};
            received_bit_index <= received_bit_index + 1;
          end else begin
            received_bit_index <= 0;
            rx_done <= 1'b1;
            rx_state <= RX_IDLE;
          end
        end

        default: begin
          rx_state <= RX_IDLE;
        end
      endcase
    end
  end

endmodule

// ============================================================
// UART Top Module
// ============================================================
module uart_top #(
  parameter int CLOCK_FREQUENCY_HZ = 1000000,
  parameter int BAUD_RATE = 9600
) (
  input  logic       clock,
  input  logic       reset,
  input  logic       rx_serial_in,
  input  logic [7:0] tx_parallel_data,
  input  logic       tx_start,
  output logic       tx_serial_out,
  output logic [7:0] rx_parallel_data,
  output logic       tx_done,
  output logic       rx_done
);

  uart_tx #(
    .CLOCK_FREQUENCY_HZ(CLOCK_FREQUENCY_HZ),
    .BAUD_RATE(BAUD_RATE)
  ) uart_tx_inst (
    .clock(clock),
    .reset(reset),
    .tx_start(tx_start),
    .tx_parallel_data(tx_parallel_data),
    .tx_serial_out(tx_serial_out),
    .tx_done(tx_done)
  );

  uart_rx #(
    .CLOCK_FREQUENCY_HZ(CLOCK_FREQUENCY_HZ),
    .BAUD_RATE(BAUD_RATE)
  ) uart_rx_inst (
    .clock(clock),
    .reset(reset),
    .rx_serial_in(rx_serial_in),
    .rx_done(rx_done),
    .rx_parallel_data(rx_parallel_data)
  );

endmodule
