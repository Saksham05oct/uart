module tb_uart;
  reg clk;
  reg rst;
  reg [16:0] baud;
  reg tx_start;
  reg rx_start;
  reg [7:0] tx_data;
  reg [3:0] length;
  reg parity_type;
  reg parity_en;
  reg stop2;
  
  wire tx;
  wire tx_done;
  wire tx_err;
  wire [7:0] rx_out;
  wire rx_done;
  wire rx_err;

  // Instantiate the DUT (top-level wrapper)
  uart_top dut (
    .clk(clk),
    .rst(rst),
    .baud(baud),
    .tx_start(tx_start),
    .rx_start(rx_start),
    .tx_data(tx_data),
    .length(length),
    .parity_type(parity_type),
    .parity_en(parity_en),
    .stop2(stop2),
    .tx(tx),
    .tx_done(tx_done),
    .tx_err(tx_err),
    .rx_out(rx_out),
    .rx_done(rx_done),
    .rx_err(rx_err)
  );

  // Clock generator: 50 MHz (20ns period)
  always #10 clk = ~clk;

  // Test variables
  int i;
  reg [7:0] test_data;
  reg [3:0] test_len;
  reg test_parity_en;
  reg test_parity_type;
  reg test_stop2;
  reg [16:0] test_baud;
  int passed_tests = 0;
  int total_tests = 50;

  initial begin
    // Waveform dumping for GTKWave
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb_uart);

    // Initial state
    clk = 0;
    rst = 1;
    tx_start = 0;
    rx_start = 0;
    tx_data = 0;
    baud = 9600;
    length = 8;
    parity_en = 0;
    parity_type = 0;
    stop2 = 0;

    // Reset pulse
    #100;
    rst = 0;
    #100;

    $display("=== Starting %0d Random UART Tests ===", total_tests);

    for (i = 0; i < total_tests; i = i + 1) begin
      // Randomize configurations
      case ($urandom_range(0, 5))
        0: test_baud = 4800;
        1: test_baud = 9600;
        2: test_baud = 14400;
        3: test_baud = 19200;
        4: test_baud = 38400;
        5: test_baud = 57600;
      endcase

      test_len = $urandom_range(5, 8); // 5 to 8 bits
      test_parity_en = $urandom_range(0, 1);
      test_parity_type = $urandom_range(0, 1);
      test_stop2 = $urandom_range(0, 1);
      
      // Mask tx_data to valid bits depending on length
      case (test_len)
        5: test_data = $urandom & 8'h1F;
        6: test_data = $urandom & 8'h3F;
        7: test_data = $urandom & 8'h7F;
        8: test_data = $urandom;
      endcase

      $display("[Test %0d] Baud: %0d | Len: %0d | ParityEn: %0b | ParityType: %0b | Stop2: %0b | Data: 8'h%h", 
               i+1, test_baud, test_len, test_parity_en, test_parity_type, test_stop2, test_data);

      // Apply configurations
      @(posedge clk);
      baud = test_baud;
      length = test_len;
      parity_en = test_parity_en;
      parity_type = test_parity_type;
      stop2 = test_stop2;
      tx_data = test_data;
      
      // Assert start signals
      tx_start = 1;
      rx_start = 1;
      @(posedge clk);
      
      // Wait for tx_done and rx_done
      fork
        begin
          @(posedge tx_done);
          @(posedge clk);
          tx_start = 0;
        end
        begin
          @(posedge rx_done);
          @(posedge clk);
          rx_start = 0;
        end
      join

      // Verify received data
      if (rx_out == test_data && rx_err == 0) begin
        $display("--> PASSED");
        passed_tests = passed_tests + 1;
      end else begin
        $display("--> FAILED! rx_out=8'h%h, rx_err=%0b (Expected 8'h%h)", rx_out, rx_err, test_data);
      end

      // Wait between frames
      #1000;
    end

    $display("=== Simulation Finished: %0d/%0d Tests Passed ===", passed_tests, total_tests);
    $finish;
  end

endmodule
