`default_nettype none

module wb_regs
    #
    (
        parameter int G_WORD_WIDTH = 8
    )

    (
        input logic i_clk,
        input logic i_rst,

        // wishbone b4 (slave) interface
        input logic i_we,
        input logic i_stb,
        input logic i_addr,
        input logic [G_WORD_WIDTH - 1 : 0] i_data,
        output logic [G_WORD_WIDTH - 1 : 0] o_data,
        output logic o_ack,

        // data read from uart rx
        input logic [G_WORD_WIDTH - 1 : 0] i_uart_rd_data,

        // internal ports within design hierarchy
        output logic o_tx_en,
        output logic [G_WORD_WIDTH - 1 : 0] o_tx_reg,
        output logic o_data_valid
    );

    logic [G_WORD_WIDTH -1 : 0] w_tx_reg;
    /* verilator lint_off UNUSEDSIGNAL */
    logic f_is_data_to_tx;
    /* verilator lint_on UNUSEDSIGNAL */

    //                  INTERFACE REGISTER MAP

    //          Address         |       Functionality
    //             0            |   data to tx (uart TX)
    //             1            |   received data (uart RX)


    assign f_is_data_to_tx = (i_we && i_stb && i_addr == 0) ? 1'b1 : 1'b0;

    always_ff @(posedge i_clk) begin : manage_inf_regs
        if(i_rst) begin
            w_tx_reg <= 0;
            o_ack <= 1'b0;
            o_tx_en <= 1'b0;
            o_data_valid <= 1'b0;
        end else begin
            o_ack <= i_stb;
            o_tx_en <= 1'b0;
            o_data_valid <= 1'b0;

            if (i_we && i_stb && i_addr == 0) begin
                w_tx_reg <= i_data;
                o_tx_en <= 1'b1;
            end else if (!i_we && i_stb && i_addr == 1)
                o_data <= i_uart_rd_data;
                o_data_valid <= 1'b1;
        end
    end

    assign o_tx_reg = w_tx_reg;

endmodule : wb_regs
