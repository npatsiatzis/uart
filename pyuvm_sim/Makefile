# Makefile

# defaults
SIM ?= ghdl
TOPLEVEL_LANG ?= vhdl
EXTRA_ARGS += --std=08
SIM_ARGS += --wave=wave.ghw

VHDL_SOURCES += $(PWD)/../rtl/parity.vhd
VHDL_SOURCES += $(PWD)/../rtl/uart.vhd
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
# MODULE is the basename of the Python test file

test:
		rm -rf sim_build
		$(MAKE) sim MODULE=tb_uart TOPLEVEL=uart

parity:
		rm -rf sim_build
		$(MAKE) sim MODULE=tb_parity TOPLEVEL=parity

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim