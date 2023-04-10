import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer,RisingEdge,FallingEdge,ClockCycles
from cocotb.result import TestFailure
import random
from cocotb_coverage.coverage import CoverCross,CoverPoint,coverage_db

covered_number = []
g_width = int(cocotb.top.g_width)
g_parity_type = int(cocotb.top.g_parity_type)


def parity_bit(parity_type,data):
	bin_vec = bin(data)
	parity_bit = parity_type
	for (i,j) in enumerate(bin_vec):
		if(i>1):
			parity_bit = parity_bit ^ int(j) 
	return parity_bit

full = False

# #Callback functions to capture the bin content showing
def notify_full():
	global full
	full = True



# at_least = value is superfluous, just shows how you can determine the amount of times that
# a bin must be hit to considered covered
@CoverPoint("top.i_data",xf = lambda x : x.i_data.value, bins = list(range(2**g_width)), at_least=1)
def number_cover(dut):
	covered_number.append(dut.i_data.value)

async def init(dut,units=1):
	dut.i_data.value = 0
	await Timer(units,'ns')
	dut._log.info("the core was initialized")

@cocotb.test()
async def test(dut):
	"""Check results and coverage for the length of fizzbuzz"""

	await init(dut,5)	
	
	expected_value = 0
	while (full != True):

		data = random.randint(0,2**g_width-1)
		while(data in covered_number):
			data = random.randint(0,2**g_width-1)
		dut.i_data.value = data
		expected_value = parity_bit(g_parity_type,data)

		await Timer(5,'ns')

		assert not (expected_value != int(dut.o_parity_bit.value)),"Different expected to actual read data"

		coverage_db["top.i_data"].add_threshold_callback(notify_full, 100)

		number_cover(dut)
