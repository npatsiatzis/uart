RTL_DIR = $(PWD)

.PHONY:lint
lint:
	@verilator --lint-only $(RTL_DIR)/*.sv
	@verible-verilog-lint $(RTL_DIR)/*.sv
