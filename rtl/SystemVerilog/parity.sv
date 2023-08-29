`default_nettype none

module parity
    #
    (
        parameter int G_WIDTH = 8,
        parameter bit G_PARITY_TYPE = 1'b1
    )

    (
        input  logic [G_WIDTH - 1 : 0] i_data,
        output logic o_parity_bit
    );

    logic data_parity;
    assign data_parity = ^(i_data);
    assign o_parity_bit = G_PARITY_TYPE ^ data_parity;

    // always_comb begin : calc_parity
        // data_parity = ^(i_data);
        // o_parity_bit = G_PARITY_TYPE ^ data_parity;
    // end

endmodule : parity
