![example workflow](https://github.com/npatsiatzis/uart/actions/workflows/regression_16450.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/uart/actions/workflows/coverage_16450.yml/badge.svg)

### simple limited features uart-16450 RTL implementation

- CoCoTB testbench for functional verification
    - $ make
- CoCoTB-test unit testing to exercise the CoCoTB tests across a range of values for the generic parameters
    - $  SIM=ghdl pytest -n auto -o log_cli=True --junitxml=test-results.xml --cocotbxml=test-cocotb.xml

