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
baud = int(cocotb.top.g_baud)
g_oversample = int(cocotb.top.g_oversample)
g_word_width = int(cocotb.top.g_word_width)
g_parity_type = int(cocotb.top.g_parity_type)

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
	dut.i_rst.value = 1

	# dut.i_tx_en.value = 0 
	dut.i_we.value = 0
	dut.i_stb.value = 0 
	dut.i_addr.value = 0
	dut.i_data.value = 0
	dut.i_rx.value = 0

	await ClockCycles(dut.i_clk,cycles)
	dut.i_rst.value = 0
	await RisingEdge(dut.i_clk)
	dut._log.info("the core was reset")

	# 					INTERFACE REGISTER MAP

	# 			Address 		| 		Functionality
	#			   0 			|	data to tx (uart TX)
	#			   1 			|	received data (uart RX)

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
		expected_value = data
		dut.i_data.value = data
		dut.i_we.value = 1 				#write data to tx
		dut.i_stb.value = 1
		dut.i_addr.value = 0

		await RisingEdge(dut.i_clk)
		dut.i_stb.value = 0 
		await FallingEdge(dut.o_rx_busy)  #interrupt fired
		dut.i_we.value = 0
		dut.i_stb.value = 1 			  #now propagate read data to o_data
		dut.i_addr.value = 1

		await RisingEdge(dut.o_ack)
		assert not (expected_value != int(dut.o_data.value)),"Different expected to actual read data"
		coverage_db["top.i_data"].add_threshold_callback(notify, 100)
		number_cover(dut)
		print("Run is at {} % coverage".format(coverage_db["top.i_data"].cover_percentage))
		# coverage_db["top.i_data"].cover_percentage
	coverage_db.report_coverage(cocotb.log.info,bins=True)
	coverage_db.export_to_xml(filename="coverage.xml")


