
from cocotb.triggers import Timer,RisingEdge,FallingEdge,ClockCycles
from cocotb.clock import Clock
from cocotb.queue import QueueEmpty, Queue
import cocotb
import enum
import random
from cocotb_coverage import crv 
from cocotb_coverage.coverage import CoverCross,CoverPoint,coverage_db
from pyuvm import utility_classes



class ParityBfm(metaclass=utility_classes.Singleton):
    def __init__(self):
        self.dut = cocotb.top
        self.driver_queue = Queue(maxsize=1)
        self.data_mon_queue = Queue(maxsize=0)
        self.result_mon_queue = Queue(maxsize=0)

    async def send_data(self, data):
        await self.driver_queue.put(data)

    async def get_data(self):
        data = await self.data_mon_queue.get()
        return data

    async def get_result(self):
        result = await self.result_mon_queue.get()
        return result

    async def reset(self):
        await Timer(2,units = 'ns')
        self.dut.i_data.value = 0 
        await Timer(2,units = 'ns')


    async def driver_bfm(self):
        self.dut.i_data.value = 0
        while True:
            await Timer(2,units = 'ns')
            try:
                data = self.driver_queue.get_nowait()
                self.dut.i_data.value = data
            except QueueEmpty:
                pass

    async def data_mon_bfm(self):
        while True:
            await Timer(2,units = 'ns')
            data = self.dut.i_data.value
            self.data_mon_queue.put_nowait(data)

    async def result_mon_bfm(self):
        while True:
            await Timer(2,units = 'ns')
            self.result_mon_queue.put_nowait(self.dut.o_parity_bit.value)


    def start_bfm(self):
        cocotb.start_soon(self.driver_bfm())
        cocotb.start_soon(self.data_mon_bfm())
        cocotb.start_soon(self.result_mon_bfm())



class UartBfm(metaclass=utility_classes.Singleton):
    def __init__(self):
        self.dut = cocotb.top
        self.driver_queue = Queue(maxsize=1)
        self.data_mon_queue = Queue(maxsize=0)
        self.result_mon_queue = Queue(maxsize=0)

    async def send_data(self, data):
        await self.driver_queue.put(data)

    async def get_data(self):
        data = await self.data_mon_queue.get()
        return data

    async def get_result(self):
        result = await self.result_mon_queue.get()
        return result

    async def reset(self):
        await RisingEdge(self.dut.i_clk)
        self.dut.i_rst.value = 1

        self.dut.i_we.value = 0
        self.dut.i_stb.value = 0 
        self.dut.i_addr.value = 0
        self.dut.i_data.value = 0
        self.dut.i_rx.value = 0
        await ClockCycles(self.dut.i_clk,5)
        self.dut.i_rst.value = 0


    async def driver_bfm(self):

        while True:
            await RisingEdge(self.dut.i_clk)
            self.dut.i_rx.value = self.dut.o_tx.value
            try:
                (i_we,i_stb,i_addr,i_data) = self.driver_queue.get_nowait()
                self.dut.i_we.value = i_we
                self.dut.i_stb.value = i_stb
                self.dut.i_addr.value = i_addr
                self.dut.i_data.value = i_data

            except QueueEmpty:
                pass

    async def data_mon_bfm(self):
        while True:
            await RisingEdge(self.dut.wb_regs.f_is_data_to_tx)
            i_data = self.dut.i_data.value

            self.data_mon_queue.put_nowait(i_data)


    async def result_mon_bfm(self):
        while True:
            await FallingEdge(self.dut.o_rx_busy)
            await RisingEdge(self.dut.o_ack)
            self.result_mon_queue.put_nowait(self.dut.o_data.value)


    def start_bfm(self):
        cocotb.start_soon(self.driver_bfm())
        cocotb.start_soon(self.data_mon_bfm())
        cocotb.start_soon(self.result_mon_bfm())