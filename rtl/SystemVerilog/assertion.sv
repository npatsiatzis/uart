`include "pkg.vh"
module assertion
    import pkg::*;
    (
        input states_rx_t state_rx,
        input states_tx_t state_tx,

        input logic i_clk,
        input logic i_rst,

        /*verilator coverage_off*/ 
        input logic o_rx_error     //o_rx_error must never toggle to '1', assertion checks so
        /*verilator coverage_on*/
    );

    check_rx_error : assert property (@(posedge i_clk) disable iff(i_rst) !o_rx_error);
    cover_state_TX : cover property (@(posedge i_clk) disable iff(i_rst) state_tx ==IDLE_TX && $past(state_tx) == TRANSMIT);
    cover_state_RX : cover property (@(posedge i_clk) disable iff(i_rst) state_rx ==IDLE_RX && $past(state_tx) == RECEIVE);
endmodule
