![example workflow](https://github.com/npatsiatzis/uart/actions/workflows/regression.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/uart/actions/workflows/coverage.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/uart/actions/workflows/formal.yml/badge.svg)

### simple uart RTL implementation

- uart tx and rx logic
- configurable baud rate, oversample rate, word width and parity type
- CoCoTB testbench for functional verification
    - $ make
- CoCoTB-test unit testing to exercise the CoCoTB tests across a range of values for the generic parameters
    - $  SIM=ghdl pytest -n auto -o log_cli=True --junitxml=test-results.xml --cocotbxml=test-cocotb.xml
- formal verification using SymbiYosys (sby), (properties specified in PSL)
    - $ make formal
