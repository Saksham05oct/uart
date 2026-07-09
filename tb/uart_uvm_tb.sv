`timescale 1ns/1ps

`include "uvm_macros.svh"
import uvm_pkg::*;

// -------------------------------------------------------------------------
// Interface
// -------------------------------------------------------------------------
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
    logic tx;
    logic tx_done;
    logic tx_err;
    logic [7:0] rx_out;
    logic rx_done;
    logic rx_err;

    // Internal clocks for synchronization
    logic tx_clk;
    logic rx_clk;
endinterface

class uart_config extends uvm_object; // configuration of env
    `uvm_object_utils(uart_config)
    
    function new(string name = "uart_config");
        super.new(name);
    endfunction
    
    uvm_active_passive_enum is_active = UVM_ACTIVE;
endclass

typedef enum bit [3:0] {RAND_BAUD_1_STOP, LENGTH5_WP, LENGTH6_WP, LENGTH7_WP, LENGTH8_WP, LENGTH5_WOP, LENGTH6_WOP, LENGTH7_WOP, LENGTH8_WOP, RAND_BAUD_2_STOP} oper_mode;

class transaction extends uvm_sequence_item;
    rand oper_mode op;
    
    rand bit [16:0] baud;
    rand bit tx_start;
    rand bit rx_start;
    rand bit [7:0] tx_data;
    rand bit [3:0] length;
    rand bit parity_type;
    rand bit parity_en;
    rand bit stop2;
    
    bit tx;
    bit tx_done;
    bit tx_err;
    bit [7:0] rx_out;
    bit rx_done;
    bit rx_err;

    `uvm_object_utils_begin(transaction)
        `uvm_field_enum(oper_mode, op, UVM_DEFAULT)
        `uvm_field_int(baud, UVM_ALL_ON)
        `uvm_field_int(tx_start, UVM_ALL_ON)
        `uvm_field_int(rx_start, UVM_ALL_ON)
        `uvm_field_int(tx_data, UVM_ALL_ON)
        `uvm_field_int(length, UVM_ALL_ON)
        `uvm_field_int(parity_type, UVM_ALL_ON)
        `uvm_field_int(parity_en, UVM_ALL_ON)
        `uvm_field_int(stop2, UVM_ALL_ON)
        `uvm_field_int(tx, UVM_ALL_ON)
        `uvm_field_int(tx_done, UVM_ALL_ON)
        `uvm_field_int(tx_err, UVM_ALL_ON)
        `uvm_field_int(rx_out, UVM_ALL_ON)
        `uvm_field_int(rx_done, UVM_ALL_ON)
        `uvm_field_int(rx_err, UVM_ALL_ON)
    `uvm_object_utils_end

    constraint baud_c {
        baud inside {4800, 9600, 14400, 19200, 38400, 57600};
    }
    
    function new(string name = "transaction");
        super.new(name);
    endfunction
endclass : transaction

// -------------------------------------------------------------------------
// Sequences
// -------------------------------------------------------------------------
class rand_baud_seq extends uvm_sequence#(transaction);
    `uvm_object_utils(rand_baud_seq)
    transaction tr;
    function new(string name="rand_baud_seq"); super.new(name); endfunction
    virtual task body();
        repeat(2) begin
            tr = transaction::type_id::create("tr");
            start_item(tr);
            if(!tr.randomize()) `uvm_error("SEQ", "Randomization failed")
            tr.op = RAND_BAUD_1_STOP;
            tr.length = 8;
            tr.parity_en = 1;
            tr.stop2 = 0;
            tr.tx_start = 1; tr.rx_start = 1;
            finish_item(tr);
        end
    endtask
endclass

class rand_baud_with_stop_seq extends uvm_sequence#(transaction);
    `uvm_object_utils(rand_baud_with_stop_seq)
    transaction tr;
    function new(string name="rand_baud_with_stop_seq"); super.new(name); endfunction
    virtual task body();
        repeat(2) begin
            tr = transaction::type_id::create("tr");
            start_item(tr);
            if(!tr.randomize()) `uvm_error("SEQ", "Randomization failed")
            tr.op = RAND_BAUD_2_STOP;
            tr.length = 8;
            tr.parity_en = 1;
            tr.stop2 = 1;
            tr.tx_start = 1; tr.rx_start = 1;
            finish_item(tr);
        end
    endtask
endclass

class rand_baud_len5p_seq extends uvm_sequence#(transaction);
    `uvm_object_utils(rand_baud_len5p_seq)
    transaction tr;
    function new(string name="rand_baud_len5p_seq"); super.new(name); endfunction
    virtual task body();
        repeat(2) begin
            tr = transaction::type_id::create("tr");
            start_item(tr);
            if(!tr.randomize()) `uvm_error("SEQ", "Randomization failed")
            tr.op = LENGTH5_WP;
            tr.length = 5;
            tr.parity_en = 1;
            tr.stop2 = 0;
            tr.tx_data = tr.tx_data & 8'h1F;
            tr.tx_start = 1; tr.rx_start = 1;
            finish_item(tr);
        end
    endtask
endclass

class rand_baud_len6p_seq extends uvm_sequence#(transaction);
    `uvm_object_utils(rand_baud_len6p_seq)
    transaction tr;
    function new(string name="rand_baud_len6p_seq"); super.new(name); endfunction
    virtual task body();
        repeat(2) begin
            tr = transaction::type_id::create("tr");
            start_item(tr);
            if(!tr.randomize()) `uvm_error("SEQ", "Randomization failed")
            tr.op = LENGTH6_WP;
            tr.length = 6;
            tr.parity_en = 1;
            tr.stop2 = 0;
            tr.tx_data = tr.tx_data & 8'h3F;
            tr.tx_start = 1; tr.rx_start = 1;
            finish_item(tr);
        end
    endtask
endclass

class rand_baud_len7p_seq extends uvm_sequence#(transaction);
    `uvm_object_utils(rand_baud_len7p_seq)
    transaction tr;
    function new(string name="rand_baud_len7p_seq"); super.new(name); endfunction
    virtual task body();
        repeat(2) begin
            tr = transaction::type_id::create("tr");
            start_item(tr);
            if(!tr.randomize()) `uvm_error("SEQ", "Randomization failed")
            tr.op = LENGTH7_WP;
            tr.length = 7;
            tr.parity_en = 1;
            tr.stop2 = 0;
            tr.tx_data = tr.tx_data & 8'h7F;
            tr.tx_start = 1; tr.rx_start = 1;
            finish_item(tr);
        end
    endtask
endclass

class rand_baud_len8p_seq extends uvm_sequence#(transaction);
    `uvm_object_utils(rand_baud_len8p_seq)
    transaction tr;
    function new(string name="rand_baud_len8p_seq"); super.new(name); endfunction
    virtual task body();
        repeat(2) begin
            tr = transaction::type_id::create("tr");
            start_item(tr);
            if(!tr.randomize()) `uvm_error("SEQ", "Randomization failed")
            tr.op = LENGTH8_WP;
            tr.length = 8;
            tr.parity_en = 1;
            tr.stop2 = 0;
            tr.tx_start = 1; tr.rx_start = 1;
            finish_item(tr);
        end
    endtask
endclass

class rand_baud_len5_seq extends uvm_sequence#(transaction);
    `uvm_object_utils(rand_baud_len5_seq)
    transaction tr;
    function new(string name="rand_baud_len5_seq"); super.new(name); endfunction
    virtual task body();
        repeat(2) begin
            tr = transaction::type_id::create("tr");
            start_item(tr);
            if(!tr.randomize()) `uvm_error("SEQ", "Randomization failed")
            tr.op = LENGTH5_WOP;
            tr.length = 5;
            tr.parity_en = 0;
            tr.stop2 = 0;
            tr.tx_data = tr.tx_data & 8'h1F;
            tr.tx_start = 1; tr.rx_start = 1;
            finish_item(tr);
        end
    endtask
endclass

class rand_baud_len6_seq extends uvm_sequence#(transaction);
    `uvm_object_utils(rand_baud_len6_seq)
    transaction tr;
    function new(string name="rand_baud_len6_seq"); super.new(name); endfunction
    virtual task body();
        repeat(2) begin
            tr = transaction::type_id::create("tr");
            start_item(tr);
            if(!tr.randomize()) `uvm_error("SEQ", "Randomization failed")
            tr.op = LENGTH6_WOP;
            tr.length = 6;
            tr.parity_en = 0;
            tr.stop2 = 0;
            tr.tx_data = tr.tx_data & 8'h3F;
            tr.tx_start = 1; tr.rx_start = 1;
            finish_item(tr);
        end
    endtask
endclass

class rand_baud_len7_seq extends uvm_sequence#(transaction);
    `uvm_object_utils(rand_baud_len7_seq)
    transaction tr;
    function new(string name="rand_baud_len7_seq"); super.new(name); endfunction
    virtual task body();
        repeat(2) begin
            tr = transaction::type_id::create("tr");
            start_item(tr);
            if(!tr.randomize()) `uvm_error("SEQ", "Randomization failed")
            tr.op = LENGTH7_WOP;
            tr.length = 7;
            tr.parity_en = 0;
            tr.stop2 = 0;
            tr.tx_data = tr.tx_data & 8'h7F;
            tr.tx_start = 1; tr.rx_start = 1;
            finish_item(tr);
        end
    endtask
endclass

class rand_baud_len8_seq extends uvm_sequence#(transaction);
    `uvm_object_utils(rand_baud_len8_seq)
    transaction tr;
    function new(string name="rand_baud_len8_seq"); super.new(name); endfunction
    virtual task body();
        repeat(2) begin
            tr = transaction::type_id::create("tr");
            start_item(tr);
            if(!tr.randomize()) `uvm_error("SEQ", "Randomization failed")
            tr.op = LENGTH8_WOP;
            tr.length = 8;
            tr.parity_en = 0;
            tr.stop2 = 0;
            tr.tx_start = 1; tr.rx_start = 1;
            finish_item(tr);
        end
    endtask
endclass

// -------------------------------------------------------------------------
// Driver
// -------------------------------------------------------------------------
class driver extends uvm_driver#(transaction);
    `uvm_component_utils(driver)
    
    virtual uart_if vif;
    transaction tr;

    function new(input string inst = "drv", uvm_component parent = null);
        super.new(inst, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tr = transaction::type_id::create("tr");
        if(!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif))
            `uvm_error("DRV", "Unable to access Interface")
    endfunction

    task reset_dut();
        repeat(5) begin
            vif.rst <= 1'b1;
            vif.tx_start <= 0;
            vif.rx_start <= 0;
            vif.tx_data <= 0;
            vif.baud <= 0;
            vif.length <= 0;
            vif.parity_type <= 0;
            vif.parity_en <= 0;
            vif.stop2 <= 0;
            @(posedge vif.clk);
        end
        vif.rst <= 1'b0;
        `uvm_info("DRV", "System Reset : Start of Simulation", UVM_MEDIUM)
    endtask

    task drive();
        reset_dut();
        forever begin
            seq_item_port.get_next_item(tr);
            
            @(posedge vif.clk);
            vif.rst <= 1'b0;
            vif.tx_start <= tr.tx_start;
            vif.rx_start <= 1'b0;
            vif.tx_data <= tr.tx_data;
            vif.baud <= tr.baud;
            vif.length <= tr.length;
            vif.parity_type <= tr.parity_type;
            vif.parity_en <= tr.parity_en;
            vif.stop2 <= tr.stop2;
            
            wait(vif.tx_clk == 1'b1);
            @(posedge vif.clk);
            vif.tx_start <= 1'b0;
            
            vif.rx_start <= tr.rx_start;
            wait(vif.rx_clk == 1'b1);
            @(posedge vif.clk);
            vif.rx_start <= 1'b0;

            `uvm_info("DRV", $sformatf("mode : TX/RX BAUD:%0d LEN:%0d PAR_T:%0d PAR_EN:%0d STOP:%0d TX_DATA:%0h", tr.baud, tr.length, tr.parity_type, tr.parity_en, tr.stop2, tr.tx_data), UVM_NONE)

            fork
                begin
                    @(posedge vif.tx_done);
                    @(negedge vif.tx_done);
                end
                begin
                    @(posedge vif.rx_done);
                    @(negedge vif.rx_done);
                end
            join
            
            seq_item_port.item_done();
        end
    endtask
    
    virtual task run_phase(uvm_phase phase);
        drive();
    endtask
endclass

// -------------------------------------------------------------------------
// Monitor
// -------------------------------------------------------------------------
class mon extends uvm_monitor;
    `uvm_component_utils(mon)

    uvm_analysis_port#(transaction) send;
    transaction tr;
    virtual uart_if vif;

    function new(input string inst = "mon", uvm_component parent = null);
        super.new(inst, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tr = transaction::type_id::create("tr");
        send = new("send", this);
        if(!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif))
            `uvm_error("MON", "Unable to access Interface")
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.clk);
            
            if (vif.rst === 1'b1) begin
                `uvm_info("MON", "SYSTEM RESET DETECTED", UVM_NONE)
                // wait for reset deassertion
                @(negedge vif.rst);
            end else if (vif.tx_start === 1'b1 || vif.rx_start === 1'b1) begin
                tr.tx_start = vif.tx_start;
                tr.rx_start = vif.rx_start;
                tr.tx_data = vif.tx_data;
                tr.baud = vif.baud;
                tr.length = vif.length;
                tr.parity_type = vif.parity_type;
                tr.parity_en = vif.parity_en;
                tr.stop2 = vif.stop2;

                fork
                    begin
                        @(posedge vif.tx_done);
                    end
                    begin
                        @(posedge vif.rx_done);
                    end
                join

                tr.rx_out = vif.rx_out;
                tr.rx_err = vif.rx_err;
                tr.tx_err = vif.tx_err;

                `uvm_info("MON", $sformatf("BAUD:%0d LEN:%0d PAR_T:%0d PAR_EN:%0d STOP:%0d TX_DATA:%0h RX_DATA:%0h RX_ERR:%0b", tr.baud, tr.length, tr.parity_type, tr.parity_en, tr.stop2, tr.tx_data, tr.rx_out, tr.rx_err), UVM_NONE)
                
                send.write(tr);
            end
        end
    endtask
endclass

// -------------------------------------------------------------------------
// Scoreboard
// -------------------------------------------------------------------------
class sco extends uvm_scoreboard;
    `uvm_component_utils(sco)

    uvm_analysis_imp#(transaction, sco) recv;

    function new(input string inst = "sco", uvm_component parent = null);
        super.new(inst, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        recv = new("recv", this);
    endfunction

    virtual function void write(transaction tr);
        if (tr.tx_data == tr.rx_out && tr.rx_err == 1'b0 && tr.tx_err == 1'b0) begin
            `uvm_info("SCO", "Test Passed", UVM_NONE)
        end else if (tr.tx_data == tr.rx_out && (tr.rx_err == 1'b1 || tr.tx_err == 1'b1)) begin
            `uvm_info("SCO", "Test Failed - Parity/Framing/Length Error Detected", UVM_NONE)
        end else begin
            `uvm_info("SCO", $sformatf("Test Failed - Data Mismatch. Expected: %0h, Actual: %0h", tr.tx_data, tr.rx_out), UVM_NONE)
        end
        $display("----------------------------------------------------------------");
    endfunction
endclass

// -------------------------------------------------------------------------
// Agent
// -------------------------------------------------------------------------
class agent extends uvm_agent;
    `uvm_component_utils(agent)

    uart_config cfg;
    driver d;
    mon m;
    uvm_sequencer#(transaction) seqr;

    function new(input string inst = "agent", uvm_component parent = null);
        super.new(inst, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg = uart_config::type_id::create("cfg");
        m = mon::type_id::create("m", this);
        
        if (cfg.is_active == UVM_ACTIVE) begin
            d = driver::type_id::create("d", this);
            seqr = uvm_sequencer#(transaction)::type_id::create("seqr", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (cfg.is_active == UVM_ACTIVE) begin
            d.seq_item_port.connect(seqr.seq_item_export);
        end
    endfunction
endclass

// -------------------------------------------------------------------------
// Environment
// -------------------------------------------------------------------------
class env extends uvm_env;
    `uvm_component_utils(env)

    agent a;
    sco s;

    function new(input string inst = "env", uvm_component c);
        super.new(inst, c);
    endfunction

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

// -------------------------------------------------------------------------
// Test
// -------------------------------------------------------------------------
class test extends uvm_test;
    `uvm_component_utils(test)

    env e;
    rand_baud_seq rb;
    rand_baud_with_stop_seq rbs;
    rand_baud_len5p_seq rb5l;
    rand_baud_len6p_seq rb6l;
    rand_baud_len7p_seq rb7l;
    rand_baud_len8p_seq rb8l;
    rand_baud_len5_seq rb5lwop;
    rand_baud_len6_seq rb6lwop;
    rand_baud_len7_seq rb7lwop;
    rand_baud_len8_seq rb8lwop;

    function new(input string inst = "test", uvm_component c);
        super.new(inst, c);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        e = env::type_id::create("env", this);
        
        rb = rand_baud_seq::type_id::create("rb");
        rbs = rand_baud_with_stop_seq::type_id::create("rbs");
        rb5l = rand_baud_len5p_seq::type_id::create("rb5l");
        rb6l = rand_baud_len6p_seq::type_id::create("rb6l");
        rb7l = rand_baud_len7p_seq::type_id::create("rb7l");
        rb8l = rand_baud_len8p_seq::type_id::create("rb8l");
        rb5lwop = rand_baud_len5_seq::type_id::create("rb5lwop");
        rb6lwop = rand_baud_len6_seq::type_id::create("rb6lwop");
        rb7lwop = rand_baud_len7_seq::type_id::create("rb7lwop");
        rb8lwop = rand_baud_len8_seq::type_id::create("rb8lwop");
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        `uvm_info("TEST", "--- STARTING RAND_BAUD_SEQ ---", UVM_NONE)
        rb.start(e.a.seqr);

        `uvm_info("TEST", "--- STARTING RAND_BAUD_WITH_STOP_SEQ ---", UVM_NONE)
        rbs.start(e.a.seqr);

        `uvm_info("TEST", "--- STARTING RAND_BAUD_LEN5P_SEQ ---", UVM_NONE)
        rb5l.start(e.a.seqr);

        `uvm_info("TEST", "--- STARTING RAND_BAUD_LEN6P_SEQ ---", UVM_NONE)
        rb6l.start(e.a.seqr);

        `uvm_info("TEST", "--- STARTING RAND_BAUD_LEN7P_SEQ ---", UVM_NONE)
        rb7l.start(e.a.seqr);

        `uvm_info("TEST", "--- STARTING RAND_BAUD_LEN8P_SEQ ---", UVM_NONE)
        rb8l.start(e.a.seqr);

        `uvm_info("TEST", "--- STARTING RAND_BAUD_LEN5_SEQ ---", UVM_NONE)
        rb5lwop.start(e.a.seqr);

        `uvm_info("TEST", "--- STARTING RAND_BAUD_LEN6_SEQ ---", UVM_NONE)
        rb6lwop.start(e.a.seqr);

        `uvm_info("TEST", "--- STARTING RAND_BAUD_LEN7_SEQ ---", UVM_NONE)
        rb7lwop.start(e.a.seqr);

        `uvm_info("TEST", "--- STARTING RAND_BAUD_LEN8_SEQ ---", UVM_NONE)
        rb8lwop.start(e.a.seqr);

        #100ns;
        phase.drop_objection(this);
    endtask
endclass

// -------------------------------------------------------------------------
// Top Module
// -------------------------------------------------------------------------
module tb;
    uart_if vif();

    uart_top dut (
        .clk(vif.clk),
        .rst(vif.rst),
        .baud(vif.baud),
        .tx_start(vif.tx_start),
        .rx_start(vif.rx_start),
        .tx_data(vif.tx_data),
        .length(vif.length),
        .parity_type(vif.parity_type),
        .parity_en(vif.parity_en),
        .stop2(vif.stop2),
        .tx(vif.tx),
        .tx_done(vif.tx_done),
        .tx_err(vif.tx_err),
        .rx_out(vif.rx_out),
        .rx_done(vif.rx_done),
        .rx_err(vif.rx_err)
    );

    // Extracting internal clocks for proper synchronization in the testbench
    assign vif.tx_clk = dut.tx_clk;
    assign vif.rx_clk = dut.rx_clk;

    initial begin
        vif.clk <= 0;
    end

    always #10 vif.clk <= ~vif.clk;

    initial begin
        uvm_config_db#(virtual uart_if)::set(null, "*", "vif", vif);
        run_test("test");
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end
endmodule
