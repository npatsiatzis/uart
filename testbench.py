# Functional test for uart module
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer,RisingEdge,FallingEdge,ClockCycles,ReadWrite
from cocotb.result import TestFailure
import random
from cocotb_coverage.coverage import CoverCross,CoverPoint,coverage_db

covered_valued = []

g_sys_clk = int(cocotb.top.g_sys_clk)
period_ns = 10**9 / g_sys_clk
baud = int(cocotb.top.g_baud)
g_oversample = int(cocotb.top.g_oversample)
g_word_width = int(cocotb.top.g_word_width)
g_parity_type = int(cocotb.top.g_parity_type)

full = False
def notify(p):
	global full
	if(p == 25 or p == 50 or p == 75):
		print("Reached {}% coverage!".format(p))
	elif(p == 100):
		print("Reached {}% coverage!".format(p))
		full = True


async def connect_tx_rx(dut):
	while full != True:
		await RisingEdge(dut.i_clk)
		dut.i_rx.value = dut.o_tx.value

# at_least = value is superfluous, just shows how you can determine the amount of times that
# a bin must be hit to considered covered
@CoverPoint("top.i_tx_data",xf = lambda x : x.i_tx_data.value, bins = list(range(2**g_word_width)), at_least=1)
def number_cover(dut):
	covered_valued.append(int(dut.i_tx_data.value))

async def reset(dut,cycles=1):
	dut.i_rst.value = 1

	dut.i_tx_en.value = 0 
	dut.i_tx_data.value = 0
	dut.i_rx.value = 0

	await ClockCycles(dut.i_clk,cycles)
	dut.i_rst.value = 0
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

	while(full != True):
		data = random.randint(0,2**g_word_width-1)
		while(data in covered_valued):
			data = random.randint(0,2**g_word_width-1)
		dut.i_tx_data.value = data
		expected_value = data
		dut.i_tx_en.value = 1

		await RisingEdge(dut.i_clk)
		await FallingEdge(dut.o_tx_busy)
		dut.i_tx_en.value = 0
		await FallingEdge(dut.o_rx_busy)
		assert not (expected_value != int(dut.o_rx_data.value)),"Different expected to actual read data"
		coverage_db["top.i_tx_data"].add_threshold_callback(notify(25), 25)
		coverage_db["top.i_tx_data"].add_threshold_callback(notify(50), 50)
		coverage_db["top.i_tx_data"].add_threshold_callback(notify(75), 75)
		coverage_db["top.i_tx_data"].add_threshold_callback(notify(100), 100)
		number_cover(dut)


