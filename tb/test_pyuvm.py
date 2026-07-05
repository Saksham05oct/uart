import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, FallingEdge, First
import pyuvm
from pyuvm import *
import random
import enum

class OperMode(enum.Enum):
    RAND_BAUD_1_STOP = 0
    LENGTH5_WP = 2
    LENGTH6_WP = 3
    LENGTH7_WP = 4
    LENGTH8_WP = 5
    LENGTH5_WOP = 6
    LENGTH6_WOP = 7
    LENGTH7_WOP = 8
    LENGTH8_WOP = 9
    RAND_BAUD_2_STOP = 11

class UartConfig(uvm_object):
    def __init__(self, name="UartConfig"):
        super().__init__(name)
        self.is_active = uvm_active_passive_enum.UVM_ACTIVE

class UartItem(uvm_sequence_item):
    def __init__(self, name="UartItem"):
        super().__init__(name)
        self.op = OperMode.RAND_BAUD_1_STOP
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

        if self.op == OperMode.RAND_BAUD_1_STOP:
            self.length = 8
            self.parity_en = 1
            self.stop2 = 0
        elif self.op == OperMode.RAND_BAUD_2_STOP:
            self.length = 8
            self.parity_en = 1
            self.stop2 = 1
        elif self.op == OperMode.LENGTH5_WP:
            self.tx_data = (self.tx_data >> 3) & 0x1F
            self.length = 5
            self.parity_en = 1
            self.stop2 = 0
        elif self.op == OperMode.LENGTH6_WP:
            self.tx_data = (self.tx_data >> 2) & 0x3F
            self.length = 6
            self.parity_en = 1
            self.stop2 = 0
        elif self.op == OperMode.LENGTH7_WP:
            self.tx_data = (self.tx_data >> 1) & 0x7F
            self.length = 7
            self.parity_en = 1
            self.stop2 = 0
        elif self.op == OperMode.LENGTH8_WP:
            self.tx_data = self.tx_data & 0xFF
            self.length = 8
            self.parity_en = 1
            self.stop2 = 0
        elif self.op == OperMode.LENGTH5_WOP:
            self.tx_data = (self.tx_data >> 3) & 0x1F
            self.length = 5
            self.parity_en = 0
            self.stop2 = 0
        elif self.op == OperMode.LENGTH6_WOP:
            self.tx_data = (self.tx_data >> 2) & 0x3F
            self.length = 6
            self.parity_en = 0
            self.stop2 = 0
        elif self.op == OperMode.LENGTH7_WOP:
            self.tx_data = (self.tx_data >> 1) & 0x7F
            self.length = 7
            self.parity_en = 0
            self.stop2 = 0
        elif self.op == OperMode.LENGTH8_WOP:
            self.tx_data = self.tx_data & 0xFF
            self.length = 8
            self.parity_en = 0
            self.stop2 = 0
        return True

class RandBaudSeq(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = UartItem("tr")
            tr.op = OperMode.RAND_BAUD_1_STOP
            await self.start_item(tr)
            tr.randomize()
            tr.rst = 0
            tr.tx_start = 1
            tr.rx_start = 1
            await self.finish_item(tr)

class RandBaudWithStopSeq(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = UartItem("tr")
            tr.op = OperMode.RAND_BAUD_2_STOP
            await self.start_item(tr)
            tr.randomize()
            tr.rst = 0
            tr.tx_start = 1
            tr.rx_start = 1
            await self.finish_item(tr)

class RandBaudLen5pSeq(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = UartItem("tr")
            tr.op = OperMode.LENGTH5_WP
            await self.start_item(tr)
            tr.randomize()
            tr.rst = 0
            tr.tx_start = 1
            tr.rx_start = 1
            await self.finish_item(tr)

class RandBaudLen6pSeq(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = UartItem("tr")
            tr.op = OperMode.LENGTH6_WP
            await self.start_item(tr)
            tr.randomize()
            tr.rst = 0
            tr.tx_start = 1
            tr.rx_start = 1
            await self.finish_item(tr)

class RandBaudLen7pSeq(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = UartItem("tr")
            tr.op = OperMode.LENGTH7_WP
            await self.start_item(tr)
            tr.randomize()
            tr.rst = 0
            tr.tx_start = 1
            tr.rx_start = 1
            await self.finish_item(tr)

class RandBaudLen8pSeq(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = UartItem("tr")
            tr.op = OperMode.LENGTH8_WP
            await self.start_item(tr)
            tr.randomize()
            tr.rst = 0
            tr.tx_start = 1
            tr.rx_start = 1
            await self.finish_item(tr)

class RandBaudLen5Seq(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = UartItem("tr")
            tr.op = OperMode.LENGTH5_WOP
            await self.start_item(tr)
            tr.randomize()
            tr.rst = 0
            tr.tx_start = 1
            tr.rx_start = 1
            await self.finish_item(tr)

class RandBaudLen6Seq(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = UartItem("tr")
            tr.op = OperMode.LENGTH6_WOP
            await self.start_item(tr)
            tr.randomize()
            tr.rst = 0
            tr.tx_start = 1
            tr.rx_start = 1
            await self.finish_item(tr)

class RandBaudLen7Seq(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = UartItem("tr")
            tr.op = OperMode.LENGTH7_WOP
            await self.start_item(tr)
            tr.randomize()
            tr.rst = 0
            tr.tx_start = 1
            tr.rx_start = 1
            await self.finish_item(tr)

class RandBaudLen8Seq(uvm_sequence):
    async def body(self):
        for _ in range(2):
            tr = UartItem("tr")
            tr.op = OperMode.LENGTH8_WOP
            await self.start_item(tr)
            tr.randomize()
            tr.rst = 0
            tr.tx_start = 1
            tr.rx_start = 1
            await self.finish_item(tr)

class UartDriver(uvm_driver):
    def build_phase(self):
        try:
            self.vif = ConfigDB().get(self, "", "vif")
        except Exception as e:
            self.logger.fatal(f"vif not found in ConfigDB: {e}")
            raise e

    async def reset_dut(self):
        for _ in range(5):
            self.vif.rst.value = 1
            self.vif.tx_start.value = 0
            self.vif.rx_start.value = 0
            self.vif.tx_data.value = 0
            self.vif.baud.value = 0
            self.vif.length.value = 0
            self.vif.parity_type.value = 0
            self.vif.parity_en.value = 0
            self.vif.stop2.value = 0
            await RisingEdge(self.vif.clk)
        self.vif.rst.value = 0
        self.logger.info("System Reset : Start of Simulation")

    async def wait_tx_done(self):
        await RisingEdge(self.vif.tx_done)
        await FallingEdge(self.vif.tx_done)

    async def wait_rx_done(self):
        await RisingEdge(self.vif.rx_done)
        await FallingEdge(self.vif.rx_done)

    async def run_phase(self):
        await self.reset_dut()
        while True:
            item = await self.seq_item_port.get_next_item()
            
            if item.rst == 1:
                self.vif.rst.value = 1
                await RisingEdge(self.vif.clk)
                self.vif.rst.value = 0
            else:
                self.vif.rst.value = 0
                self.vif.tx_start.value = item.tx_start
                self.vif.rx_start.value = 0
                self.vif.tx_data.value = item.tx_data
                self.vif.baud.value = item.baud
                self.vif.length.value = item.length
                self.vif.parity_type.value = item.parity_type
                self.vif.parity_en.value = item.parity_en
                self.vif.stop2.value = item.stop2
                
                while True:
                    await RisingEdge(self.vif.clk)
                    try:
                        if int(self.vif.tx_clk.value) == 1:
                            break
                    except ValueError:
                        pass
                self.vif.tx_start.value = 0
                
                await RisingEdge(self.vif.clk)
                
                self.vif.rx_start.value = item.rx_start
                while True:
                    await RisingEdge(self.vif.clk)
                    try:
                        if int(self.vif.rx_clk.value) == 1:
                            break
                    except ValueError:
                        pass
                self.vif.rx_start.value = 0

                self.logger.debug(f"DRV mode : TX/RX BAUD:{item.baud} LEN:{item.length} PAR_T:{item.parity_type} PAR_EN:{item.parity_en} STOP:{item.stop2} TX_DATA:{item.tx_data}")

                t1 = cocotb.start_soon(self.wait_tx_done())
                t2 = cocotb.start_soon(self.wait_rx_done())
                await t1
                await t2

            self.seq_item_port.item_done()

class UartMonitor(uvm_monitor):
    def build_phase(self):
        try:
            self.vif = ConfigDB().get(self, "", "vif")
        except Exception as e:
            self.logger.fatal(f"vif not found in ConfigDB: {e}")
            raise e
        self.send = uvm_analysis_port("send", self)

    async def wait_tx_done(self):
        await RisingEdge(self.vif.tx_done)

    async def wait_rx_done(self):
        await RisingEdge(self.vif.rx_done)

    async def run_phase(self):
        while True:
            await RisingEdge(self.vif.clk)
            
            try:
                is_rst = int(self.vif.rst.value)
            except ValueError:
                continue

            if is_rst == 1:
                tr = UartItem("tr")
                tr.rst = 1
                self.logger.info("SYSTEM RESET DETECTED")
                self.send.write(tr)
            else:
                try:
                    is_tx_start = int(self.vif.tx_start.value)
                    is_rx_start = int(self.vif.rx_start.value)
                except ValueError:
                    continue

                if is_tx_start == 1 or is_rx_start == 1:
                    tr = UartItem("tr")
                    tr.rst = 0
                    tr.tx_start = is_tx_start
                    tr.rx_start = is_rx_start
                tr.tx_data = int(self.vif.tx_data.value)
                tr.baud = int(self.vif.baud.value)
                tr.length = int(self.vif.length.value)
                tr.parity_type = int(self.vif.parity_type.value)
                tr.parity_en = int(self.vif.parity_en.value)
                tr.stop2 = int(self.vif.stop2.value)

                t1 = cocotb.start_soon(self.wait_tx_done())
                t2 = cocotb.start_soon(self.wait_rx_done())
                await t1
                await t2

                tr.rx_out = int(self.vif.rx_out.value)
                tr.rx_err = int(self.vif.rx_err.value)
                tr.tx_err = int(self.vif.tx_err.value)

                self.logger.info(f"BAUD:{tr.baud} LEN:{tr.length} PAR_T:{tr.parity_type} PAR_EN:{tr.parity_en} STOP:{tr.stop2} TX_DATA:{tr.tx_data} RX_DATA:{tr.rx_out} RX_ERR:{tr.rx_err}")
                self.send.write(tr)

class UartScoreboard(uvm_scoreboard):
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

class UartAgent(uvm_agent):
    def build_phase(self):
        self.cfg = ConfigDB().get(self, "", "cfg")
        if self.cfg is None:
            self.logger.info("Using default agent configuration")
            self.cfg = UartConfig("cfg")
        self.monitor = UartMonitor("m", self)
        if self.cfg.is_active == uvm_active_passive_enum.UVM_ACTIVE:
            self.driver = UartDriver("d", self)
            self.sequencer = uvm_sequencer("seqr", self)

    def connect_phase(self):
        if self.cfg.is_active == uvm_active_passive_enum.UVM_ACTIVE:
            self.driver.seq_item_port.connect(self.sequencer.seq_item_export)

class UartEnv(uvm_env):
    def build_phase(self):
        self.cfg = UartConfig("cfg")
        ConfigDB().set(self, "a", "cfg", self.cfg)
        self.agent = UartAgent("a", self)
        self.scoreboard = UartScoreboard("s", self)

    def connect_phase(self):
        self.agent.monitor.send.connect(self.scoreboard.fifo.analysis_export)

@pyuvm.test()
class UartTest(uvm_test):
    def build_phase(self):
        self.env = UartEnv("env", self)
        ConfigDB().set(None, "*", "vif", cocotb.top)

    async def run_phase(self):
        self.raise_objection()

        clock = Clock(cocotb.top.clk, 20, units="ns")
        cocotb.start_soon(clock.start())

        sequences = [
            (RandBaudSeq, "rb"),
            (RandBaudWithStopSeq, "rbs"),
            (RandBaudLen5pSeq, "rb5l"),
            (RandBaudLen6pSeq, "rb6l"),
            (RandBaudLen7pSeq, "rb7l"),
            (RandBaudLen8pSeq, "rb8l"),
            (RandBaudLen5Seq, "rb5lwop"),
            (RandBaudLen6Seq, "rb6lwop"),
            (RandBaudLen7Seq, "rb7lwop"),
            (RandBaudLen8Seq, "rb8lwop")
        ]

        for seq_cls, name in sequences:
            self.logger.info(f"Starting {seq_cls.__name__} sequence")
            seq = seq_cls(name)
            await seq.start(self.env.agent.sequencer)

        await Timer(20, units="ns")
        self.drop_objection()
