## Requirements Specification

### 1. Scope
1. **Scope**

This document establishes the requirements for an Intellectual Property (IP) that provides a UART function.
1. **Purpose**

These requirements shall apply to a FizzBuzz core with a simple interface for inclusion as a component.
1. **Classification**

This document defines the requirements for a hardware design.


### 2. Definitions
1. **Word** : The data block that is transmitted.
2. **Baud Rate** : Symbols (bits) / second.
3. **Parity Bit** : 
	* *Even* parity : The number of ONEs in each transmitted set of bits (word + parity bit) must be an even number.
	* *Odd* parity : The number of ONES in each transmitted set of bits (word + parity bit) must be an odd number.
	* *No parity* : No parity bit is used in transmitting the data.

1. **Start Bit** : A bit (low level) to indicate the start of transmission.
1. **Stop Bit** : A bit (high level) to indicate the end of transmission and make the lien transition to low be recognized as the next Start Bit.
1. **Framing Error** : Error condition where received data is not properly framed.
1. **Parity Error** : Error condition where the received data (+ parity) have a different number of ONES from which specified by the selected parity type.

### 3. Applicable Documents
1. **Government Documents**
None
1. **Non-government Documents**
None

### 4. Architectural Overview
1. **Introduction**
The UART component shall represent a design written in an HDL (VHDL and/or SystemVerilog) that can easily be incorporateed into a larger design. The UART shall provide the function of a bridge between the CPU and a RS-232 like protocol. This UART shall include the following features : 
    1. Parameterized word length, oversample rate and parity type.
    1. UART Transmit/Receive Protocol.
    1. Identify Framing and Parity Errors.
<p align="center">
  <img src="https://github.com/npatsiatzis/uart/blob/main/docs/img/uart_core.drawio.svg" width = "500" height = "250" />
</p>
The CPU interface in this case is the Wishbone B4 interface.

1.  **System Application**
The UART can be applied to a variety of system configurations. Most often, it is used as a hardwired interface between two subsystems.

### 5. Physical Layer
* Serial Interface
    1. tx, Transmit Data
    2. rx, Receive Data
* CPU interface
    1. wb B4 bus (we, stb, addr, ack)
    5. i_data, word to transmit (CPU -> UART)
    6. o_data, word that receiver got (UART -> CPU)
    7. o_data_valid, defines the timing at which the o_data is valid
    8. tx_busy, defines the timing at which transmit is underway
    9. rx_busy, defines the timing at which receive is underway
    10. rx_error, informs about an error (either framing and/or parity) in receive operation
    7. clk, system clock
    8. rst, system reset, synchronous active high

### 6. Protocol Layer
A message consists of the following bits transmitted according to the baud rate:
1. Start Bit
2. Word
3. Parity Bitt
4. Stop Bit 

### 7. Robustness
The errors below, when identified should be reported.
1. Framing Error
2. Parity Error

These errors should be reported to the interrupt registers (not implemented yet). Instead, if such errors occur, I create an interrupt (output signal) signifying this condition.

### 8. Hardware and Software
1. **Parameterization**
The UART shall provide for the following parameters used for the definition of the implemented hardware during hardware build:

| Param. Name | Description |
| :------: | :------: |
| word width | width of the CPU data interface |
| baud rate | symbol(bits) / sec |
| system clock frequency | frequency of the clock provided to the uart core |
| oversample rate | rate for which the receiver oversamples the line (i.e multiple of the baud rate) |
| parity type | even or odd parity of the word |

1. **CPU interface**
The CPU shall write into the UART data for transmission and also read from the receive register.

| addr | we (+ stb) | Description |
| :------: | :------: | :------: | 
| 0 | 1 | set word to transmit |
| 1 | 0 | read word from receiver |

(* Obviously, only the bare minimum of UART features are implemented, namely the transmit and receive functionality).

### 9. Performance
1. **Frequency**
1. **Power Dissipation**
1. **Environmental**
Does not apply.
1. **Technology**
The design shall be adaptable to any technology because the design shall be portable and defined in an HDL.

### 10. Testability
None required.

### 11. Mechanical
Does not apply.
