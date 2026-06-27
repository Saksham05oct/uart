module dump;
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, uart_top);
  end
endmodule
