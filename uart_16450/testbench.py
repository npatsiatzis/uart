# Functional test for uart module
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer,RisingEdge,FallingEdge,ClockCycles,ReadWrite
from cocotb.result import TestFailure
import random
from cocotb_coverage.coverage import CoverPoint,coverage_db

covered_valued = []

g_sys_clk = int(cocotb.top.g_sys_clk)
period_ns = 10**9 / g_sys_clk
g_word_width = int(cocotb.top.g_data_width)

full = False
def notify():
	global full
	full = True


async def connect_tx_rx(dut):
	while full != True:
		await RisingEdge(dut.i_clk)
		dut.i_rx.value = dut.o_tx.value

# at_least = value is superfluous, just shows how you can determine the amount of times that
# a bin must be hit to considered covered
@CoverPoint("top.i_data",xf = lambda x : x.i_data.value, bins = list(range(2**g_word_width)), at_least=1)
def number_cover(dut):
	covered_valued.append(int(dut.i_data.value))

async def reset(dut,cycles=1):
	dut.i_arstn.value = 0
	dut.i_we.value = 0 
	dut.i_stb.value = 0
	dut.i_data.value = 0
	dut.i_rx.value = 0

	await ClockCycles(dut.i_clk,cycles)
	dut.i_arstn.value = 1
	await RisingEdge(dut.i_clk)
	dut._log.info("the core was reset")

@cocotb.test()
async def test(dut):
	"""Check results and coverage for UART"""

	cocotb.start_soon(Clock(dut.i_clk, period_ns, units="ns").start())
	await reset(dut,5)	
	cocotb.start_soon(connect_tx_rx(dut))

	expected_value = 0
	rx_data = 0

	# configure UART core via interface
	# set databits(8), stopbits(1), parity_en(1), parity_type etc..
	dut.i_stb.value = 1
	dut.i_addr.value = 1
	dut.i_we.value = 1
	dut.i_data.value = 11

	await RisingEdge(dut.i_clk)

	while(full != True):
		data = random.randint(0,2**g_word_width-1)
		while(data in covered_valued):
			data = random.randint(0,2**g_word_width-1)
		expected_value = data

		dut.i_stb.value = 1
		dut.i_we.value = 1
		dut.i_addr.value = 0
		dut.i_data.value = data

		await RisingEdge(dut.i_clk)
		dut.i_stb.value = 0
		await FallingEdge(dut.o_rx_done)

		dut.i_stb.value = 1
		dut.i_we.value = 0
		dut.i_addr.value = 0

		await ClockCycles(dut.i_clk,2)	#1 cycle to register read rd_rbr command, 1 cycle to copy rbr to o_data

		assert not (expected_value != int(dut.o_data.value)),"Different expected to actual read data"
		coverage_db["top.i_data"].add_threshold_callback(notify, 100)
		number_cover(dut)

	coverage_db.report_coverage(cocotb.log.info,bins=True)
	coverage_db.export_to_xml(filename="coverage.xml")


