from cocotb_test.simulator import run
from cocotb.binary import BinaryValue
import pytest
import os

vhdl_compile_args = "--std=08"
sim_args = "--wave=wave.ghw"


tests_dir = os.path.abspath(os.path.dirname(__file__)) #gives the path to the test(current) directory in which this test.py file is placed
rtl_dir = tests_dir                                    #path to hdl folder where .vhdd files are placed


      
#run tests with generic values for length
list_generics = []
for i in range(4,13,4):
    list_generics.append({"g_word_width" : str(i),"g_sys_clk" : str(10**8)})
    list_generics.append({"g_word_width" : str(i),"g_sys_clk" : str(2*10**8)})
@pytest.mark.parametrize("parameter", list_generics)
def test_uart(parameter):

    module = "test_uart"
    toplevel = "uart"   
    vhdl_sources = [
        os.path.join(rtl_dir, "parity.vhd"),
        os.path.join(rtl_dir, "uart.vhd"),
        ]



    run(
        python_search=[tests_dir],                         #where to search for all the python test files
        vhdl_sources=vhdl_sources,
        toplevel=toplevel,
        module=module,

        vhdl_compile_args=[vhdl_compile_args],
        toplevel_lang="vhdl",
        parameters=parameter,                              #parameter dictionary
        extra_env=parameter,
        sim_build="sim_build/"
        + "_".join(("{}={}".format(*i) for i in parameter.items())),
    )



#run tests with generic values for length
@pytest.mark.parametrize("parameter", [{"g_width": str(i)} for i in range(4,9,4)])
def test_parity(parameter):

    module = "testbench_parity"
    toplevel = "parity"   
    vhdl_sources = [
        os.path.join(rtl_dir, "parity.vhd"),
        ]



    run(
        python_search=[tests_dir],                         #where to search for all the python test files
        vhdl_sources=vhdl_sources,
        toplevel=toplevel,
        module=module,

        vhdl_compile_args=[vhdl_compile_args],
        toplevel_lang="vhdl",
        parameters=parameter,                              #parameter dictionary
        extra_env=parameter,
        sim_build="sim_build/"
        + "_".join(("{}={}".format(*i) for i in parameter.items())),
    )
