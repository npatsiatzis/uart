`ifndef PKG_VH
`define PKG_VH
package pkg;
    typedef enum logic {IDLE_RX, RECEIVE} states_rx_t;
    typedef enum logic {IDLE_TX, TRANSMIT} states_tx_t;
endpackage
`endif
