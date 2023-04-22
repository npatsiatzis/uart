# Makefile

# defaults
SIM ?= ghdl
TOPLEVEL_LANG ?= vhdl
EXTRA_ARGS += --std=08
SIM_ARGS += --wave=wave.ghw

VHDL_SOURCES += $(PWD)/../rtl/wb_regs.vhd
VHDL_SOURCES += $(PWD)/../rtl/axil_regs.vhd
VHDL_SOURCES += $(PWD)/../rtl/parity.vhd
VHDL_SOURCES += $(PWD)/../rtl/uart.vhd
VHDL_SOURCES += $(PWD)/../rtl/uart_top.vhd
VHDL_SOURCES += $(PWD)/../rtl/uart_top_axi.vhd
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
# MODULE is the basename of the Python test file

test:
		rm -rf sim_build
		$(MAKE) sim MODULE=testbench TOPLEVEL=uart_top

test_axi:
		rm -rf sim_build
		$(MAKE) sim MODULE=testbench_axi TOPLEVEL=uart_top_axi

parity:
		rm -rf sim_build
		$(MAKE) sim MODULE=testbench_parity TOPLEVEL=parity

formal :
		sby --yosys "yosys -m ghdl" -f uart.sby

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim