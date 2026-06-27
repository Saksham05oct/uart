import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import pyuvm
from pyuvm import *
import random

class uart_config(uvm_object):
    def __init__(self, name="uart_config"):
        super().__init__(name)
        self.is_active = uvm_active_passive_enum.UVM_ACTIVE

class transaction(uvm_sequence_item):
    def __init__(self, name="transaction"):
        super().__init__(name)
        self.tx_start = 0
        self.rx_start = 0
        self.rst = 0
        self.tx_data = 0
        self.baud = 0
        self.length = 0
        self.parity_type = 0
        self.parity_en = 0
        self.stop2 = 0
        self.tx_err = 0
        self.rx_err = 0
        self.rx_out = 0

    def randomize(self):
        self.baud = random.choice([4800, 9600, 14400, 19200, 38400, 57600])
        self.tx_data = random.randint(0, 255)
        self.parity_type = random.choice([0, 1])
        return True

class rand_baud(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = transaction("tr")
            await self.start_item(tr)
            tr.randomize()
            tr.length = 8
            tr.rst = 0
            tr.tx_start = 1
            tr.rx_start = 1
            tr.parity_en = 1
            tr.stop2 = 0
            await self.finish_item(tr)

class rand_baud_with_stop(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = transaction("tr")
            await self.start_item(tr)
            tr.randomize()
            tr.rst = 0
            tr.length = 8
            tr.tx_start = 1
            tr.rx_start = 1
            tr.parity_en = 1
            tr.stop2 = 1
            await self.finish_item(tr)

class rand_baud_len5p(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = transaction("tr")
            await self.start_item(tr)
            tr.randomize()
            tr.rst = 0
            tr.tx_data = (tr.tx_data >> 3) & 0x1F
            tr.length = 5
            tr.tx_start = 1
            tr.rx_start = 1
            tr.parity_en = 1
            tr.stop2 = 0
            await self.finish_item(tr)

class rand_baud_len6p(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = transaction("tr")
            await self.start_item(tr)
            tr.randomize()
            tr.rst = 0
            tr.length = 6
            tr.tx_data = (tr.tx_data >> 2) & 0x3F
            tr.tx_start = 1
            tr.rx_start = 1
            tr.parity_en = 1
            tr.stop2 = 0
            await self.finish_item(tr)

class rand_baud_len7p(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = transaction("tr")
            await self.start_item(tr)
            tr.randomize()
            tr.rst = 0
            tr.length = 7
            tr.tx_data = (tr.tx_data >> 1) & 0x7F
            tr.tx_start = 1
            tr.rx_start = 1
            tr.parity_en = 1
            tr.stop2 = 0
            await self.finish_item(tr)

class rand_baud_len8p(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = transaction("tr")
            await self.start_item(tr)
            tr.randomize()
            tr.rst = 0
            tr.length = 8
            tr.tx_data = tr.tx_data & 0xFF
            tr.tx_start = 1
            tr.rx_start = 1
            tr.parity_en = 1
            tr.stop2 = 0
            await self.finish_item(tr)

class rand_baud_len5(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = transaction("tr")
            await self.start_item(tr)
            tr.randomize()
            tr.rst = 0
            tr.length = 5
            tr.tx_data = (tr.tx_data >> 3) & 0x1F
            tr.tx_start = 1
            tr.rx_start = 1
            tr.parity_en = 0
            tr.stop2 = 0
            await self.finish_item(tr)

class rand_baud_len6(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = transaction("tr")
            await self.start_item(tr)
            tr.randomize()
            tr.rst = 0
            tr.length = 6
            tr.tx_data = (tr.tx_data >> 2) & 0x3F
            tr.tx_start = 1
            tr.rx_start = 1
            tr.parity_en = 0
            tr.stop2 = 0
            await self.finish_item(tr)

class rand_baud_len7(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = transaction("tr")
            await self.start_item(tr)
            tr.randomize()
            tr.rst = 0
            tr.length = 7
            tr.tx_data = (tr.tx_data >> 1) & 0x7F
            tr.tx_start = 1
            tr.rx_start = 1
            tr.parity_en = 0
            tr.stop2 = 0
            await self.finish_item(tr)

class rand_baud_len8(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = transaction("tr")
            await self.start_item(tr)
            tr.randomize()
            tr.rst = 0
            tr.length = 8
            tr.tx_data = tr.tx_data & 0xFF
            tr.tx_start = 1
            tr.rx_start = 1
            tr.parity_en = 0
            tr.stop2 = 0
            await self.finish_item(tr)

class driver(uvm_driver):
    def build_phase(self):
        self.vif = ConfigDB().get(self, "", "vif")

    async def reset_dut(self):
        for _ in range(2):
            self.vif.rst.value = 1
            self.vif.tx_start.value = 0
            self.vif.rx_start.value = 0
            self.vif.tx_data.value = 0
            self.vif.baud.value = 0
            self.vif.length.value = 0
            self.vif.parity_type.value = 0
            self.vif.parity_en.value = 0
            self.vif.stop2.value = 0
            self.logger.info("System Reset : Start of Simulation")
            await RisingEdge(self.vif.clk)

    async def run_phase(self):
        await self.reset_dut()
        while True:
            tr = await self.seq_item_port.get_next_item()
            
            # Wait for previous transaction to fully clear 'done' state and return to 'idle'
            while self.vif.tx_done.value == 1 or self.vif.rx_done.value == 1:
                await RisingEdge(self.vif.clk)

            self.vif.rst.value = 0
            self.vif.tx_start.value = tr.tx_start
            self.vif.rx_start.value = 0
            self.vif.tx_data.value = tr.tx_data
            self.vif.baud.value = tr.baud
            self.vif.length.value = tr.length
            self.vif.parity_type.value = tr.parity_type
            self.vif.parity_en.value = tr.parity_en
            self.vif.stop2.value = tr.stop2
            
            while True:
                await RisingEdge(self.vif.clk)
                if self.vif.tx_clk.value == 1:
                    break
            self.vif.tx_start.value = 0
            
            await RisingEdge(self.vif.clk)
            
            self.vif.rx_start.value = tr.rx_start
            while True:
                await RisingEdge(self.vif.clk)
                if self.vif.rx_clk.value == 1:
                    break
            self.vif.rx_start.value = 0

            self.logger.info(f"BAUD:{tr.baud} LEN:{tr.length} PAR_T:{tr.parity_type} PAR_EN:{tr.parity_en} STOP:{tr.stop2} TX_DATA:{tr.tx_data}")

            async def wait_tx_done():
                await RisingEdge(self.vif.tx_done)

            async def wait_rx_done():
                await RisingEdge(self.vif.rx_done)

            t1 = cocotb.start_soon(wait_tx_done())
            t2 = cocotb.start_soon(wait_rx_done())
            await t1
            await t2

            self.seq_item_port.item_done()

class mon(uvm_monitor):
    def build_phase(self):
        self.vif = ConfigDB().get(self, "", "vif")
        self.send = uvm_analysis_port("send", self)

    async def run_phase(self):
        while True:
            await RisingEdge(self.vif.clk)
            
            try:
                is_rst = int(self.vif.rst.value)
            except ValueError:
                continue

            if is_rst == 1:
                tr = transaction("tr")
                tr.rst = 1
                self.logger.info("SYSTEM RESET DETECTED")
                self.send.write(tr)
            elif int(self.vif.tx_start.value) == 1 or int(self.vif.rx_start.value) == 1:
                tr = transaction("tr")
                tr.rst = 0
                tr.tx_start = int(self.vif.tx_start.value)
                tr.rx_start = int(self.vif.rx_start.value)
                tr.tx_data = int(self.vif.tx_data.value)
                tr.baud = int(self.vif.baud.value)
                tr.length = int(self.vif.length.value)
                tr.parity_type = int(self.vif.parity_type.value)
                tr.parity_en = int(self.vif.parity_en.value)
                tr.stop2 = int(self.vif.stop2.value)

                async def wait_tx():
                    await RisingEdge(self.vif.tx_done)

                async def wait_rx():
                    await RisingEdge(self.vif.rx_done)

                t1 = cocotb.start_soon(wait_tx())
                t2 = cocotb.start_soon(wait_rx())
                await t1
                await t2

                tr.rx_out = int(self.vif.rx_out.value)
                tr.rx_err = int(self.vif.rx_err.value)
                tr.tx_err = int(self.vif.tx_err.value)

                self.logger.info(f"BAUD:{tr.baud} LEN:{tr.length} PAR_T:{tr.parity_type} PAR_EN:{tr.parity_en} STOP:{tr.stop2} TX_DATA:{tr.tx_data} RX_DATA:{tr.rx_out} RX_ERR:{tr.rx_err}")
                self.send.write(tr)

class sco(uvm_scoreboard):
    def build_phase(self):
        self.fifo = uvm_tlm_analysis_fifo("fifo", self)

    async def run_phase(self):
        while True:
            tr = await self.fifo.get()
            self.write(tr)

    def write(self, tr):
        if tr.rst == 1:
            self.logger.info("System Reset")
        elif tr.tx_data == tr.rx_out and tr.rx_err == 0 and tr.tx_err == 0:
            self.logger.info("Test Passed")
        elif tr.tx_data == tr.rx_out and (tr.rx_err == 1 or tr.tx_err == 1):
            self.logger.error("Test Failed - Parity/Framing Error Detected")
        else:
            self.logger.error("Test Failed - Data Mismatch")
        self.logger.info("-" * 64)

class agent(uvm_agent):
    def build_phase(self):
        self.cfg = ConfigDB().get(self, "", "cfg")
        if self.cfg is None:
            self.logger.info("Using default agent configuration")
            self.cfg = uart_config("cfg")
        self.m = mon("m", self)
        if self.cfg.is_active == uvm_active_passive_enum.UVM_ACTIVE:
            self.d = driver("d", self)
            self.seqr = uvm_sequencer("seqr", self)

    def connect_phase(self):
        if self.cfg.is_active == uvm_active_passive_enum.UVM_ACTIVE:
            self.d.seq_item_port.connect(self.seqr.seq_item_export)

class env(uvm_env):
    def build_phase(self):
        self.cfg = uart_config("cfg")
        ConfigDB().set(self, "a", "cfg", self.cfg)
        self.a = agent("a", self)
        self.s = sco("s", self)

    def connect_phase(self):
        self.a.m.send.connect(self.s.fifo.analysis_export)

@pyuvm.test()
class test(uvm_test):
    def build_phase(self):
        self.e = env("env", self)
        ConfigDB().set(None, "*", "vif", cocotb.top)

    async def run_phase(self):
        self.raise_objection()

        clock = Clock(cocotb.top.clk, 20, units="ns")
        cocotb.start_soon(clock.start())

        sequences = [
            (rand_baud, "rb"),
            (rand_baud_with_stop, "rbs"),
            (rand_baud_len5p, "rb5l"),
            (rand_baud_len6p, "rb6l"),
            (rand_baud_len7p, "rb7l"),
            (rand_baud_len8p, "rb8l"),
            (rand_baud_len5, "rb5lwop"),
            (rand_baud_len6, "rb6lwop"),
            (rand_baud_len7, "rb7lwop"),
            (rand_baud_len8, "rb8lwop")
        ]

        for seq_cls, name in sequences:
            self.logger.info(f"Starting {seq_cls.__name__} sequence")
            seq = seq_cls(name)
            await seq.start(self.e.a.seqr)

        await Timer(20, units="ns")
        self.drop_objection()
