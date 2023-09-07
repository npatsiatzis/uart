# Makefile

# defaults
TOPLEVEL_LANG ?= vhdl

ifeq ($(TOPLEVEL_LANG),verilog)
	SIM ?= icarus
	TOPLEVEL_LANG ?= verilog
	VERILOG_SOURCES += $(PWD)/../rtl/SystemVerilog/*.sv
	COMPILE_ARGS += -DWAVEFORM -DICARUS
	WAVES=1
	MODULE_NAME = testbench
else ifeq ($(TOPLEVEL_LANG),vhdl)
	SIM ?= ghdl
	EXTRA_ARGS += --std=08
	SIM_ARGS += --wave=wave.ghw
	VHDL_SOURCES += $(PWD)/../rtl/VHDL/*.vhd
	MODULE_NAME = testbench
endif



# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
# MODULE is the basename of the Python test file

#PYTHPNPATH is an environment variable that can be set to additional directories
#where python will look for modules and packages
export PYTHONPATH := $(PWD)/../model:$(PYTHONPATH)

test_adder:
		$(MAKE) sim MODULE=$(MODULE_NAME) TOPLEVEL=uart_top
test_axi:
		rm -rf sim_build
		$(MAKE) sim MODULE=testbench_axi TOPLEVEL=uart_top_axi

parity:
		rm -rf sim_build
		$(MAKE) sim MODULE=testbench_parity TOPLEVEL=parity
lint: $(VHDL_SOURCES)
	vsg --style jcl -f $^
	
documentation:
		doxygen 

.PHONY: clean_dir
clean_dir:
		rm -f *.vcd
		rm -f *.ghw
		rm -f *.o 
		rm -f *.xml
# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim