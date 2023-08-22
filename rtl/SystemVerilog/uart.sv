`default_nettype none

module uart
    #
    (
        parameter int G_SYS_CLK = 40000000,
        parameter int G_BAUD = 256000,
        parameter int G_OVERSAMPLE = 16,
        parameter int G_WORD_WIDTH = 8,
        parameter bit G_PARITY_TYPE = 1'b1
    )

    (
        input logic i_clk,
        input logic i_rst,

        input logic i_tx_en,
        input logic [G_WORD_WIDTH - 1 : 0] i_data,
        output logic [G_WORD_WIDTH - 1 : 0] o_data,

        // tx, rx serial lines
        output logic o_tx,
        input logic i_rx,

        // interrupts
        output logic o_tx_busy,
        output logic o_rx_busy,
        output logic o_rx_error
    );

    // counter to create the baud rate from the system clock
    // Non-type localparam names must be styled with CamelCase (verible lint)
    localparam int RangeBaud = G_SYS_CLK/G_BAUD -1;
    // counter to create the oveerasmple rate
    localparam int RangeOversample = (G_SYS_CLK/G_BAUD)/G_OVERSAMPLE -1;

    // pulse signal (1 cycle) @baud rate
    logic r_baud_pulse;
    // pulse signal (1 cycle) @oversample rate
    logic r_oversample_pulse;

    // states of uart TX,RX FSMs
    typedef enum logic {IDLE_RX, RECEIVE} states_rx_t;
    typedef enum logic {IDLE_TX, TRANSMIT} states_tx_t;
    states_rx_t state_rx;
    states_tx_t state_tx;

    // signal holding the parity bit of the transmit data
    logic w_tx_parity;

    // baud and oversample counters
    logic [$clog2(RangeBaud) - 1 + ($clog2(RangeBaud+1) - $clog2(RangeBaud)): 0] cnt_baud;
    logic [$clog2(RangeOversample) - 1 + ($clog2(RangeOversample+1) - $clog2(RangeOversample)): 0] cnt_oversample;

    // uart TX FSM signals
    logic [G_WORD_WIDTH - 1 + 3 : 0] r_tx_data;
    logic [$clog2(G_WORD_WIDTH + 3) -1 + ($clog2(G_WORD_WIDTH +4) - $clog2(G_WORD_WIDTH +3)): 0] cnt_digits_sent;

    // uart RX FSM signals
    logic [$clog2(G_OVERSAMPLE) - 1  + ($clog2(G_OVERSAMPLE+1) - $clog2(G_OVERSAMPLE)): 0] cnt_oversample_pulses;
    logic [$clog2(G_WORD_WIDTH + 2) - 1 + ($clog2(G_WORD_WIDTH +3) - $clog2(G_WORD_WIDTH +2)): 0] cnt_digits_received;
    // rx data stream including the data plus parity and end bit
    logic [G_WORD_WIDTH + 1 : 0] r_rx_data;
    logic [G_WORD_WIDTH - 1 : 0] w_rx_data;



    assign o_data = w_rx_data;

    always_ff @(posedge i_clk) begin : gen_pulse
        if(i_rst) begin
            cnt_baud <= 0;
            r_baud_pulse <= 1'b0;
            cnt_oversample <= 0;
            r_oversample_pulse <= 1'b0;
        end else begin
            if ($size(RangeBaud)'(cnt_baud) < RangeBaud) begin
                cnt_baud <= cnt_baud + 1;
                r_baud_pulse <= 1'b0;
            end else begin
                cnt_baud <= 0;
                r_baud_pulse <= 1'b1;
                cnt_oversample <= 0;
            end

            if ($size(RangeOversample)'(cnt_oversample) < RangeOversample) begin
                cnt_oversample <= cnt_oversample + 1;
                r_oversample_pulse <= 1'b0;
            end else begin
                cnt_oversample <= 0;
                r_oversample_pulse <= 1'b1;
            end
        end
    end

    always_ff @(posedge i_clk) begin : TX_FSM
        if(i_rst) begin
            o_tx_busy <= 1'b0;
            state_tx <= IDLE_TX;
            cnt_digits_sent <= 0;
            r_tx_data <= 0;
            o_tx <= 1'b1;
        end else begin
            case (state_tx)
                IDLE_TX : begin
                    o_tx <= 1'b1;
                    if (i_tx_en) begin
                        r_tx_data <= {1'b1, w_tx_parity, i_data, 1'b0};
                        state_tx <= TRANSMIT;
                        cnt_digits_sent <= 0;
                        o_tx_busy <= 1'b1;
                    end
                end
                TRANSMIT :  begin
                    if (r_baud_pulse) begin
                        o_tx <= r_tx_data[0];
                        o_tx_busy <= 1'b1;
                        if ($size(G_WORD_WIDTH)'(cnt_digits_sent) < G_WORD_WIDTH + 2) begin
                            r_tx_data <= {1'b1, r_tx_data[$high(r_tx_data): 1]};
                            cnt_digits_sent <= cnt_digits_sent + 1;
                            state_tx <= TRANSMIT;
                        end else begin
                            cnt_digits_sent <= 0;
                            state_tx <= IDLE_TX;
                            o_tx_busy <= 1'b0;
                            o_tx <= 1'b1;
                        end
                    end
                end
                default : begin
                    o_tx_busy <= 1'b0;
                    o_tx <= 1'b1;
                    state_tx <= IDLE_TX;
                end
            endcase
        end
    end

    parity #(.G_WIDTH(G_WORD_WIDTH),.G_PARITY_TYPE(G_PARITY_TYPE)) parity_gen (
        .i_data(i_data),
        .o_parity_bit(w_tx_parity)
    );

    always_ff @(posedge i_clk) begin : RX_FSM
        if(i_rst) begin
            o_rx_busy <= 1'b0;
            o_rx_error <= 1'b0;
            w_rx_data <= 0;
            r_rx_data <= 0;
            state_rx <= IDLE_RX;
            cnt_digits_received <= 0;
            cnt_oversample_pulses <= 0;
        end else begin
            case (state_rx)
                IDLE_RX : begin
                    if (r_oversample_pulse) begin
                        if ( !i_rx) begin
                            if ($size(G_OVERSAMPLE)'(cnt_oversample_pulses) <
                            G_OVERSAMPLE/2 - 1) begin
                                cnt_oversample_pulses <= cnt_oversample_pulses + 1;
                                state_rx <= IDLE_RX;
                            end else begin
                                o_rx_busy <= 1'b1;
                                cnt_oversample_pulses <= 0;
                                state_rx <= RECEIVE;
                            end
                        end else begin
                            o_rx_busy <= 1'b0;
                            o_rx_error <= 1'b0;
                            r_rx_data <= 0;
                        end
                    end
                end
                RECEIVE : begin
                    o_rx_busy <= 1'b1;

                    if (r_oversample_pulse) begin
                        if ($size(G_OVERSAMPLE)'(cnt_oversample_pulses) < G_OVERSAMPLE) begin
                            cnt_oversample_pulses <= cnt_oversample_pulses + 1;
                        end else begin
                            cnt_oversample_pulses <= 0;
                            if ($size(G_WORD_WIDTH)'(cnt_digits_received) < G_WORD_WIDTH + 2) begin
                                r_rx_data <= {i_rx, r_rx_data[$high(r_rx_data) : 1]};
                                cnt_digits_received <= cnt_digits_received + 1;
                                state_rx <= RECEIVE;
                            end else begin
                                state_rx <= IDLE_RX;
                                cnt_digits_received <= 0;
                                o_rx_busy <= 1'b0;
                                w_rx_data <= r_rx_data[$high(r_rx_data) -2 : 0];
                                if ( !r_rx_data[$high(r_rx_data)])
                                    o_rx_error <= 1'b1;
                                if ( ^({r_rx_data[$high(r_rx_data) - 2 : 0], G_PARITY_TYPE})
                                    != G_PARITY_TYPE)
                                    o_rx_error <= 1'b1;
                            end
                        end
                    end
                end
                default : begin
                    o_rx_busy <= 1'b1;
                    o_rx_error <= 1'b0;
                    w_rx_data <= 0;
                    state_rx <= IDLE_RX;
                end
            endcase
        end
    end

endmodule : uart
