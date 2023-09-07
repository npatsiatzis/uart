`default_nettype none

module uart_top
    #
    (
        parameter int g_sys_clk = 40000000,
        parameter int g_baud = 256000,
        parameter int g_oversample = 16,
        parameter int g_word_width /*verilator public*/ = 8,
        parameter bit g_parity_type = 1'b0
    )
    (
        input logic i_clk,
        input logic i_rst,
        input logic i_we,
        input logic i_stb,
        input logic i_addr,
        input logic [g_word_width -1 : 0] i_data,
        output logic o_ack,
        output logic [g_word_width -1 : 0] o_data,

        output logic o_tx,
        /* verilator lint_off UNUSED */
        /*verilator coverage_off*/      // needed for toggle coverage, since it's not used
        input logic i_rx,
        /*verilator coverage_on*/
        /* verilator lint_on UNUSED */

        output logic o_tx_busy,
        output logic o_rx_busy,
        output logic f_rx_busy_prev,
        output logic o_rx_error,

        output logic o_data_valid
    );

    logic [g_word_width -1 : 0] w_tx_reg, w_rd_data;
    logic w_tx_en;

    wb_regs 
        #(.G_WORD_WIDTH(g_word_width)) 
        wb_regs
        (
            .i_clk(i_clk),
            .i_rst(i_rst),
            .i_we(i_we),
            .i_stb(i_stb),
            .i_addr(i_addr),
            .i_data(i_data),
            .o_data(o_data),
            .o_ack(o_ack),
            .i_uart_rd_data(w_rd_data),
            .o_tx_en(w_tx_en),
            .o_tx_reg(w_tx_reg),
            .o_data_valid(o_data_valid)
        );

        // (.*,.i_uart_rd_data(w_rd_data), .o_tx_en(w_tx_en), .o_tx_reg(w_tx_reg), .o_data(o_data), .o_data_valid(o_data_valid));

    uart
    #(
        .G_SYS_CLK(g_sys_clk),
        .G_BAUD       (g_baud),
        .G_OVERSAMPLE (g_oversample),
        .G_WORD_WIDTH (g_word_width),
        .G_PARITY_TYPE (g_parity_type)
    )
    uart
    (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_tx_en(w_tx_en),
        .i_data(w_tx_reg),
        .o_data(w_rd_data),
        .o_tx(o_tx),
        .i_rx(o_tx),
        .o_tx_busy(o_tx_busy),
        .o_rx_busy(o_rx_busy),
        .o_rx_error(o_rx_error)
    );
    // (
    //     .*, .i_tx_en(w_tx_en), .i_data(w_tx_reg), .o_data(w_rd_data), .i_rx(o_tx),
    // );

    // for uvm verification purposes 
    always_ff @(posedge i_clk) begin : gen_rx_busy_prev
        if(i_rst) begin
            f_rx_busy_prev <= 0;
        end else begin
            f_rx_busy_prev <= o_rx_busy;
        end
    end

    `ifdef WAVEFORM
        initial begin
            // Dump waves
            $dumpfile("dump.vcd");
            $dumpvars(0, uart_top);
        end
    `endif
endmodule : uart_top
