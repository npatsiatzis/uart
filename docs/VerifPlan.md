## Verification Plan
This document describes the verification plan for the UART design.
***Note*** : For the purpose of verification, the the tx and rx signals are crosscoupled which means that the receiver is connected to the transmitter. 

#### Definitions
**BFM** : A Bus Functional Model emulates the operation of an interface.


**transaction** : A transaction describes a high-level interace operation, e.g. WRITE DATA on ADDRESS at specified time.

#### Compliance Plan
**Feature Extraction** : Extract the design features from the requirement specification. 
**Testing Strategy** : For each feature, a testing strategy is identified.
**Test Sequence** : For each feature-strategy pair, a test sequence is identified.
**Verification Criteria** :  For each feature-strategy pair, verification (pass/fail) criteria are proposed.

| Feature | Testing Strategy | Test Sequence | Verification Criteria |
| :------: | :------: | :------: | :------: |
| Parameterization | compilation | does not apply. | Design compiles and elaborates correctly. |
| Reset | Directed Test | set reset signal active (high) | All components of UART enter reset state |
| Transmit / Receive Protocol | Constrained Random | Coverage Driven (full coverage for word input space) | *assert* received data = transmitted data for each test |
| Receive Framing Error | Directed Test | inject framing error | error identified |
| Receive Parity Error | Directed Test | inject parity error | error identified |


