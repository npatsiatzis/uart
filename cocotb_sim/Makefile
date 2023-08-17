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

test:
		rm -rf sim_build
		$(MAKE) sim MODULE=testbench TOPLEVEL=uart_top

test_axi:
		rm -rf sim_build
		$(MAKE) sim MODULE=testbench_axi TOPLEVEL=uart_top_axi

parity:
		rm -rf sim_build
		$(MAKE) sim MODULE=testbench_parity TOPLEVEL=parity
clean_dir:
		rm -f wave.*
		rm -f *.o 
		rm -f *.xml
		find . -maxdepth 1 -type f -executable -exec rm {} +
		find -mindepth 1 -maxdepth 1 -type d -print0 | xargs -r0 rm -R

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim