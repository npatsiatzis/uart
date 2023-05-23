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
		$(MAKE) sim MODULE=tb_uart TOPLEVEL=uart_top

test_axi:
		rm -rf sim_build
		$(MAKE) sim MODULE=tb_uart_axi TOPLEVEL=uart_top_axi

parity:
		rm -rf sim_build
		$(MAKE) sim MODULE=tb_parity TOPLEVEL=parity

clean_dir:
		rm -f wave.*
		rm -f *.o 
		rm -f *.xml
		find . -maxdepth 1 -type f -executable -exec rm {} +
		find -mindepth 1 -maxdepth 1 -type d -print0 | xargs -r0 rm -R
# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim