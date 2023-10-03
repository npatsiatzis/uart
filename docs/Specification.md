## Requirements Specification
This document describes the requirements specification for a UART design.

---

#### Definitions
**Baud Rate** : Symbols (bits) / second.
**Parity** : 
1. *Even* parity : The number of ONEs in each transmitted set of bits (data + parity) must be an even number.
1. *Odd* parity : The number of ONES in each transmitted set of bits (data + parity) must be an odd number.
1. *No parity* : No parity bit is used in transmitting the data.

**Word** : The data block that is transmitted.
**Start Bit** : A bit (low level) to indicate the start of transmission.
**Stop Bit** : A bit (high level) to indicate the end of transmission and make the lien transition to low be recognized as the next Start Bit.
**Framing Error** : Error condition where received data is not properly framed.
**Parity Error** : Error condition where the received data (+ parity) have a different number of ONES from which specified by the selected parity type.

![uart_core](https://github.com/npatsiatzis/uart/blob/main/docs/img/uart_core.drawio.svg)
