# Makefile

# defaults
SIM ?= ghdl
TOPLEVEL_LANG ?= vhdl
EXTRA_ARGS += --std=08
SIM_ARGS += --wave=wave.ghw

VHDL_SOURCES += $(PWD)/../rtl/VHDL/wb_regs.vhd
VHDL_SOURCES += $(PWD)/../rtl/VHDL/axil_regs.vhd
VHDL_SOURCES += $(PWD)/../rtl/VHDL/parity.vhd
VHDL_SOURCES += $(PWD)/../rtl/VHDL/uart.vhd
VHDL_SOURCES += $(PWD)/../rtl/VHDL/uart_top.vhd
VHDL_SOURCES += $(PWD)/../rtl/VHDL/uart_top_axi.vhd
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
# MODULE is the basename of the Python test file

formal :
		sby --yosys "yosys -m ghdl" -f uart.sby

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim