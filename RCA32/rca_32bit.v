`timescale 1ns/1ps

module fa_1bit (
    input  wire bit_a,
    input  wire bit_b,
    input  wire carry_in,
    output wire sum_bit,
    output wire carry_out
);
    assign sum_bit = bit_a ^ bit_b ^ carry_in;
    assign carry_out = (bit_a & bit_b) | (carry_in & (bit_a ^ bit_b));
endmodule

module rca_32bit (
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire        carry_in,
    input  wire        subtract_mode,
    output wire [31:0] result,
    output wire        carry_out,
    output wire        overflow
);

    wire [32:0] carry_chain;
    wire [31:0] b_operand;

    assign carry_chain[0] = carry_in;
    assign carry_out = carry_chain[32];
    assign overflow = carry_chain[31] ^ carry_chain[32];

    assign b_operand = subtract_mode ? ~operand_b : operand_b;
    wire effective_cin = subtract_mode | carry_in;

    genvar idx;
    generate
        for (idx = 0; idx < 32; idx = idx + 1) begin : adder_stage
            fa_1bit FA (
                .bit_a(operand_a[idx]),
                .bit_b(b_operand[idx]),
                .carry_in(carry_chain[idx]),
                .sum_bit(result[idx]),
                .carry_out(carry_chain[idx+1])
            );
        end
    endgenerate

endmodule
