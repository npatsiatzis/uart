![example workflow](https://github.com/npatsiatzis/uart/actions/workflows/regression.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/uart/actions/workflows/coverage.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/uart/actions/workflows/regression_pyuvm.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/uart/actions/workflows/coverage_pyuvm.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/uart/actions/workflows/formal.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/uart/actions/workflows/verilator_regression.yml/badge.svg)
[![codecov](https://codecov.io/gh/npatsiatzis/uart/graph/badge.svg?token=529VOQ9EWL)](https://codecov.io/gh/npatsiatzis/uart)

### simple uart RTL implementation

- uart tx and rx logic
- configurable baud rate, oversample rate, word width and parity type


### Repo Structure

This is a short tabular description of the contents of each folder in the repo.

| Folder | Description |
| ------ | ------ |
| [rtl/SystemVerilog](https://github.com/npatsiatzis/uart/tree/main/rtl/SystemVerilog) | SV RTL implementation files |
| [rtl/VHDL](https://github.com/npatsiatzis/uart/tree/main/rtl/VHDL) | VHDL RTL implementation files |
| [uart_16450](https://github.com/npatsiatzis/uart/tree/main/uart_16450) | VHDL RTL implementation files for the UART 16450 model (several features not implemented)|
| [cocotb_sim](https://github.com/npatsiatzis/uart/tree/main/cocotb_sim) | Functional Verification with CoCoTB (Python-based) |
| [pyuvm_sim](https://github.com/npatsiatzis/uart/tree/main/pyuvm_sim) | Functional Verification with pyUVM (Python impl. of UVM standard) |
| [uvm_sim](https://github.com/npatsiatzis/uart/tree/main/uvm_sim) | Functional Verification with UVM (SV impl. of UVM standard) |
| [verilator_sim](https://github.com/npatsiatzis/uart/tree/main/verilator_sim) | Functional Verification with Verilator (C++ based) |
| [mcy_sim](https://github.com/npatsiatzis/uart/tree/main/mcy_sim) | Mutation Coverage Testing of Verilator tb, using  [YoysHQ/mcy](https://github.com/YosysHQ/oss-cad-suite-build)|
| [formal](https://github.com/npatsiatzis/uart/tree/main/formal) | Formal Verification using  PSL properties and [YoysHQ/sby](https://github.com/YosysHQ/oss-cad-suite-build) |


This is the tree view of the strcture of the repo.
<pre>
<font size = "2">
.
├── <font size = "4"><b><a href="https://github.com/npatsiatzis/uart/tree/main/rtl">rtl</a></b> </font>
│   ├── <font size = "4"><a href="https://github.com/npatsiatzis/uart/tree/main/rtl/SystemVerilog">SystemVerilog</a> </font>
│   │   └── SV files
│   └── <font size = "4"><a href="https://github.com/npatsiatzis/uart/tree/main/rtl/VHDL">VHDL</a> </font>
│       └── VHD files
├── <font size = "4"><b><a href="https://github.com/npatsiatzis/uart/tree/main/cocotb_sim">cocotb_sim</a></b></font>
│   ├── Makefile
│   └── python files
├── <font size = "4"><b><a 
 href="https://github.com/npatsiatzis/uart/tree/main/pyuvm_sim">pyuvm_sim</a></b></font>
│   ├── Makefile
│   └── python files
├── <font size = "4"><b><a href="https://github.com/npatsiatzis/uart/tree/main/uvm_sim">uvm_sim</a></b></font>
│   └── .zip file
├── <font size = "4"><b><a href="https://github.com/npatsiatzis/uart/tree/main/verilator_sim">verilator_sim</a></b></font>
│   ├── Makefile
│   └── verilator tb
├── <font size = "4"><b><a href="https://github.com/npatsiatzis/uart/tree/main/mcy_sim">mcy_sim</a></b></font>
│   ├── Makefile, (modified) SV files, Verilator tb
│   └── scripts
├── <font size = "4"><b><a href="https://github.com/npatsiatzis/uart/tree/main/uart_16450">uart_16450</a></b></font>
│   ├── VHD files
└── <font size = "4"><b><a href="https://github.com/npatsiatzis/uart/tree/main/formal">formal</a></b></font>
    ├── Makefile
    └── PSL properties file, scripts
</pre>