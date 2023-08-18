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

    always_comb begin : calc_parity
        logic data_parity;
        data_parity = ^(i_data);
        o_parity_bit = G_PARITY_TYPE ^ data_parity;
    end

endmodule : parity
