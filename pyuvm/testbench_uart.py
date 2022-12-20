from cocotb.triggers import FallingEdge
from cocotb.clock import Clock
from pyuvm import *
import random
import cocotb
import pyuvm
from utils import UartBfm

g_sys_clk = int(cocotb.top.g_sys_clk)
period_ns = 10**9 / g_sys_clk
g_word_width = int(cocotb.top.g_word_width)
covered_values = []


# Sequence classes
class SeqItem(uvm_sequence_item):

    def __init__(self, name, i_tx_en,i_tx_data):
        super().__init__(name)
        self. i_tx_en = i_tx_en
        self.i_tx_data = i_tx_data

    def randomize_operands(self):
        self.i_tx_en = 1
        self.i_tx_data = random.randint(0,2**g_word_width-1)

    def randomize(self):
        self.randomize_operands()


class RandomSeq(uvm_sequence):

    async def body(self):
        while(len(covered_values) != 2**g_word_width):
            data_tr = SeqItem("data_tr", None,None)
            await self.start_item(data_tr)
            data_tr.randomize_operands()
            while((data_tr.i_tx_data) in covered_values):
                data_tr.randomize_operands()
            covered_values.append((data_tr.i_tx_data))
            await self.finish_item(data_tr)
            await FallingEdge(cocotb.top.o_tx_busy)


class TestAllSeq(uvm_sequence):

    async def body(self):
        seqr = ConfigDB().get(None, "", "SEQR")
        random = RandomSeq("random")
        await random.start(seqr)

class Driver(uvm_driver):
    def build_phase(self):
        self.ap = uvm_analysis_port("ap", self)

    def start_of_simulation_phase(self):
        self.bfm = UartBfm()

    async def launch_tb(self):
        await self.bfm.reset()
        self.bfm.start_bfm()

    async def run_phase(self):
        await self.launch_tb()
        while True:
            data = await self.seq_item_port.get_next_item()
            await self.bfm.send_data((data.i_tx_en,data.i_tx_data))
            result = await self.bfm.get_result()
            self.ap.write(result)
            data.result = result
            self.seq_item_port.item_done()


class Coverage(uvm_subscriber):

    def end_of_elaboration_phase(self):
        self.cvg = set()

    def write(self, data):
        (i_tx_en,i_tx_data) = data
        if(int(i_tx_data) not in self.cvg):
            self.cvg.add(int(i_tx_data))

    def report_phase(self):
        try:
            disable_errors = ConfigDB().get(
                self, "", "DISABLE_COVERAGE_ERRORS")
        except UVMConfigItemNotFound:
            disable_errors = False
        if not disable_errors:
            if len(set(covered_values) - self.cvg) > 0:
                self.logger.error(
                    f"Functional coverage error. Missed: {set(covered_values)-self.cvg}")   
                assert False
            else:
                self.logger.info("Covered all input space")
                assert True


class Scoreboard(uvm_component):

    def build_phase(self):
        self.data_fifo = uvm_tlm_analysis_fifo("data_fifo", self)
        self.result_fifo = uvm_tlm_analysis_fifo("result_fifo", self)
        self.data_get_port = uvm_get_port("data_get_port", self)
        self.result_get_port = uvm_get_port("result_get_port", self)
        self.data_export = self.data_fifo.analysis_export
        self.result_export = self.result_fifo.analysis_export

    def connect_phase(self):
        self.data_get_port.connect(self.data_fifo.get_export)
        self.result_get_port.connect(self.result_fifo.get_export)

    def check_phase(self):
        passed = True
        rx_data = 0
        try:
            self.errors = ConfigDB().get(self, "", "CREATE_ERRORS")
        except UVMConfigItemNotFound:
            self.errors = False
        while self.result_get_port.can_get():
            _, actual_result = self.result_get_port.try_get()
            data_success, data = self.data_get_port.try_get()
            if not data_success:
                self.logger.critical(f"result {actual_result} had no command")
            else:
                (i_tx_en,i_tx_data) = data
                old_rx_data = rx_data
                rx_data = actual_result
                if(old_rx_data != rx_data):
                    if int(i_tx_data) == int(actual_result):
                        self.logger.info("PASSED:")
                    else:
                        self.logger.error("FAILED:")

                        passed = False
        assert passed


class Monitor(uvm_component):
    def __init__(self, name, parent, method_name):
        super().__init__(name, parent)
        self.method_name = method_name

    def build_phase(self):
        self.ap = uvm_analysis_port("ap", self)
        self.bfm = UartBfm()
        self.get_method = getattr(self.bfm, self.method_name)

    async def run_phase(self):
        while True:
            datum = await self.get_method()
            self.logger.debug(f"MONITORED {datum}")
            self.ap.write(datum)


class Env(uvm_env):

    def build_phase(self):
        self.seqr = uvm_sequencer("seqr", self)
        ConfigDB().set(None, "*", "SEQR", self.seqr)
        self.driver = Driver.create("driver", self)
        self.data_mon = Monitor("data_mon", self, "get_data")
        self.coverage = Coverage("coverage", self)
        self.scoreboard = Scoreboard("scoreboard", self)

    def connect_phase(self):
        self.driver.seq_item_port.connect(self.seqr.seq_item_export)
        self.data_mon.ap.connect(self.scoreboard.data_export)
        self.data_mon.ap.connect(self.coverage.analysis_export)
        self.driver.ap.connect(self.scoreboard.result_export)


@pyuvm.test()
class Test(uvm_test):
    """Test UART rx-tx loopback with random values"""

    def build_phase(self):
        self.env = Env("env", self)
        self.bfm = UartBfm()

    def end_of_elaboration_phase(self):
        self.test_all = TestAllSeq.create("test_all")

    async def run_phase(self):
        self.raise_objection()
        cocotb.start_soon(Clock(self.bfm.dut.i_clk, period_ns, units="ns").start())
        await self.test_all.start()
        self.drop_objection()
