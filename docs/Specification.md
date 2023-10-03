## Requirements Specification
This document describes the requirements specification for a UART design.


#### Definitions
**Word** : The data block that is transmitted.
**Baud Rate** : Symbols (bits) / second.
**Parity Bit** : 
1. *Even* parity : The number of ONEs in each transmitted set of bits (word + parity bit) must be an even number.
1. *Odd* parity : The number of ONES in each transmitted set of bits (word + parity bit) must be an odd number.
1. *No parity* : No parity bit is used in transmitting the data.

**Start Bit** : A bit (low level) to indicate the start of transmission.
**Stop Bit** : A bit (high level) to indicate the end of transmission and make the lien transition to low be recognized as the next Start Bit.
**Framing Error** : Error condition where received data is not properly framed.
**Parity Error** : Error condition where the received data (+ parity) have a different number of ONES from which specified by the selected parity type.

<p align="center">
  <img src="https://github.com/npatsiatzis/uart/blob/main/docs/img/uart_core.drawio.svg" />
</p>

THe CPU interface in this case is the Wishbone B4 interface.

#### Physical Layer
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
#### Protocol Layer
A message consists of the following bits transmitted according to the baud rate:
1. Start Bit
2. Word
3. Parity Bitt
4. Stop Bit 

#### Robustness
The errors below, when identified should be reported.
1. Framing Error
2. Parity Error

These errors should be reported to the interrupt registers (not implemented yet). Instead, if such errors occur, I create an interrupt (output signal) signifying this condition.

#### Hardware and Software
**Parameterization** : 
| Param. Name | Description |
| :------: | :------: |
| word width | width of the CPU data interface |
| baud rate | symbol(bits) / sec |
| system clock frequency | frequency of the clock provided to the uart core |
| oversample rate | rate for which the receiver oversamples the line (i.e multiple of the baud rate) |
| parity type | even or odd parity of the word |

**CPU interface** : 
| addr | we (+ stb) | Description |
| :------: | :------: | :------: | 
| 0 | 1 | set word to transmit |
| 1 | 0 | read word from receiver |

(* Obviously, only the bare minimum of UART features are implemented, namely the transmit and receive functionality).
