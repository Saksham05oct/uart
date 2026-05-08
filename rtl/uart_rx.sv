`timescale 1ns / 1ps

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
