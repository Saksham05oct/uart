`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction)
  rand logic [16:0] baud;
  logic tx_clk;
  logic rx_clk;
  real period;       // Measured tx_clk period
  real rx_period;    // Measured rx_clk period

  // Randomize to valid bauds 80% of the time, and invalid bauds 20% of the time to test default fallback
  constraint valid_bauds_dist {
    baud dist {
      4800   := 15,
      9600   := 15,
      14400  := 15,
      19200  := 15,
      38400  := 15,
      57600  := 15,
      [1:4799]   := 2,
      [4801:9599] := 2,
      [9601:14399] := 2,
      [14401:19199] := 2,
      [19201:38399] := 2,
      [38401:57599] := 2,
      [57601:131071] := 2
    };
  }

  function new(string name = "transaction");
    super.new(name);
  endfunction
endclass

class variable_baud extends uvm_sequence#(transaction);
  `uvm_object_utils(variable_baud)

  transaction tr;

  function new(string name = "variable_baud");
    super.new(name);
  endfunction

  virtual task body();
    repeat(10) begin // Increased runs to hit multiple valid and fallback scenarios
      tr = transaction::type_id::create("tr");
      start_item(tr);
      assert(tr.randomize);
      finish_item(tr);
    end
  endtask
endclass

class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver)

  virtual clk_if vif;
  transaction tr;

  function new(string name = "drv", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual clk_if)::get(this, "", "vif", vif)) begin
      `uvm_error("drv", "Virtual interface not found")
    end
  endfunction

  task reset_dut();
    repeat(5) begin
      vif.rst <= 1'b1;
      vif.baud <= 17'h0;
      @(posedge vif.clk);
    end
    `uvm_info("DRV", "System Reset : Start of Simulation", UVM_MEDIUM);
    vif.rst <= 1'b0;
  endtask

  virtual task run_phase(uvm_phase phase);
    reset_dut();
    forever begin
      seq_item_port.get_next_item(tr);
      `uvm_info("DRV", $sformatf("Setting baud to %0d", tr.baud), UVM_NONE);
      vif.baud <= tr.baud;
      @(posedge vif.clk);
      @(posedge vif.tx_clk);
      @(posedge vif.tx_clk);
      seq_item_port.item_done();
    end
  endtask
endclass

class mon extends uvm_monitor;
  `uvm_component_utils(mon)

  uvm_analysis_port#(transaction) send;
  transaction tr;
  virtual clk_if vif;

  function new(string name = "mon", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    send = new("send", this);
    if(!uvm_config_db#(virtual clk_if)::get(this, "", "vif", vif)) begin
      `uvm_error("mon", "Virtual interface not found")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      if(vif.rst) begin
        `uvm_info("MON", "System Reset Detected", UVM_NONE);
      end
      else begin
        tr = transaction::type_id::create("tr");
        tr.baud = vif.baud;
        
        // Measure both tx_clk and rx_clk periods concurrently
        fork
          begin
            real ton_tx = 0, toff_tx = 0;
            @(posedge vif.tx_clk);
            ton_tx = $realtime;
            @(posedge vif.tx_clk);
            toff_tx = $realtime;
            tr.period = toff_tx - ton_tx;
          end
          begin
            real ton_rx = 0, toff_rx = 0;
            @(posedge vif.rx_clk);
            ton_rx = $realtime;
            @(posedge vif.rx_clk);
            toff_rx = $realtime;
            tr.rx_period = toff_rx - ton_rx;
          end
        join
        
        `uvm_info("MON", $sformatf("Baud: %0d, TX Period: %0f, RX Period: %0f", tr.baud, tr.period, tr.rx_period), UVM_NONE);
        send.write(tr);
      end
    end
  endtask
endclass

class sco extends uvm_scoreboard;
  `uvm_component_utils(sco)

  real tx_count = 0;
  real rx_count = 0;
  uvm_analysis_imp#(transaction,sco) recv;

  function new(string name = "sco", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    recv = new("recv", this);
  endfunction

  virtual function void write(transaction tr);
    tx_count = tr.period/20;
    rx_count = tr.rx_period/20;
    real expected_tx_count;
    real expected_rx_count;

    case(tr.baud)
      4800: begin
        expected_tx_count = 10418;
        expected_rx_count = 653;
      end
      9600: begin
        expected_tx_count = 5210;
        expected_rx_count = 327;
      end
      14400: begin
        expected_tx_count = 3474;
        expected_rx_count = 219;
      end
      19200: begin
        expected_tx_count = 2606;
        expected_rx_count = 165;
      end
      38400: begin
        expected_tx_count = 1304;
        expected_rx_count = 83;
      end
      57600: begin
        expected_tx_count = 870;
        expected_rx_count = 56;
      end
      default: begin
        // Fallback to 9600 baud
        expected_tx_count = 5210;
        expected_rx_count = 327;
      end
    endcase     

    `uvm_info("SCO", $sformatf("BAUD:%0d tx_count:%0f rx_count:%0f | Expected tx_count:%0f rx_count:%0f", 
              tr.baud, tx_count, rx_count, expected_tx_count, expected_rx_count), UVM_NONE);

    if (tx_count == expected_tx_count && rx_count == expected_rx_count) begin
      `uvm_info("SCO", "TEST PASSED", UVM_NONE)
    end
    else begin
      `uvm_error("SCO", $sformatf("TEST FAILED! Expected TX: %0f (Got %0f), Expected RX: %0f (Got %0f)", 
                expected_tx_count, tx_count, expected_rx_count, rx_count))
    end
  endfunction
endclass

class agent extends uvm_agent;
  `uvm_component_utils(agent)

  function new(string name = "agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  driver d;
  mon m;
  uvm_sequencer#(transaction) sequencer;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sequencer = uvm_sequencer#(transaction)::type_id::create("sequencer", this);
    d = driver::type_id::create("d", this);
    m = mon::type_id::create("m", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass

class env extends uvm_env;
  `uvm_component_utils(env)

  function new(input string inst = "env", uvm_component c);
    super.new(inst, c);
  endfunction

  agent a;
  sco s;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a = agent::type_id::create("a", this);
    s = sco::type_id::create("s", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.m.send.connect(s.recv);
  endfunction
endclass

class test extends uvm_test;
  `uvm_component_utils(test)

  env e;
  variable_baud vbar;

  function new(input string inst = "test", uvm_component c);
    super.new(inst, c);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = env::type_id::create("e", this);
    vbar = variable_baud::type_id::create("vbar");
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    vbar.start(e.a.sequencer);
    #20;
    phase.drop_objection(this);
  endtask
endclass

module tb;
  clk_if vif();
  
  // Correctly bound both tx_clk and rx_clk to the virtual interface
  clk_gen dut (
    .clk(vif.clk),
    .rst(vif.rst), 
    .baud(vif.baud), 
    .tx_clk(vif.tx_clk),
    .rx_clk(vif.rx_clk)
  );
  
  initial begin
    vif.clk <= 0;
  end
 
  always #10 vif.clk <= ~vif.clk; // 50MHz Clock (20ns Period)
  
  initial begin
    uvm_config_db#(virtual clk_if)::set(null, "*", "vif", vif);
    run_test("test");
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule
