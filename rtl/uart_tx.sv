`timescale 1ns / 1ps

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
