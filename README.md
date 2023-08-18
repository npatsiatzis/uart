![example workflow](https://github.com/npatsiatzis/uart/actions/workflows/regression.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/uart/actions/workflows/coverage.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/uart/actions/workflows/formal.yml/badge.svg)

### simple uart RTL implementation

- uart tx and rx logic
- configurable baud rate, oversample rate, word width and parity type

-- RTL code in:
- [VHDL](https://github.com/npatsiatzis/uart/tree/main/rtl/VHDL)
- [SystemVerilog](https://github.com/npatsiatzis/uart/tree/main/rtl/SystemVerilog)

-- Functional verification with methodologies:
- [cocotb](https://github.com/npatsiatzis/uart/tree/main/cocotb_sim)
- [pyuvm](https://github.com/npatsiatzis/uart/tree/main/pyuvm_sim)