`timescale 1ns/1ps

module alu_16bit #(
    parameter WIDTH = 16
) (
    input  wire [WIDTH-1:0] input_a,
    input  wire [WIDTH-1:0] input_b,
    input  wire [3:0]       operation,
    output reg  [WIDTH-1:0] output_result,
    output wire             zero_flag,
    output wire             carry_flag,
    output wire             overflow_flag,
    output wire             negative_flag,
    output wire             parity_flag
);

    localparam [3:0] OP_ADD   = 4'b0000;
    localparam [3:0] OP_SUB   = 4'b0001;
    localparam [3:0] OP_INC   = 4'b0010;
    localparam [3:0] OP_DEC   = 4'b0011;
    localparam [3:0] OP_AND   = 4'b0100;
    localparam [3:0] OP_OR    = 4'b0101;
    localparam [3:0] OP_XOR   = 4'b0110;
    localparam [3:0] OP_NOT   = 4'b0111;
    localparam [3:0] OP_SLL   = 4'b1000;
    localparam [3:0] OP_SRL   = 4'b1001;
    localparam [3:0] OP_SRA   = 4'b1010;
    localparam [3:0] OP_EQ    = 4'b1011;
    localparam [3:0] OP_SLT   = 4'b1100;
    localparam [3:0] OP_SLTU  = 4'b1101;
    localparam [3:0] OP_NAND  = 4'b1110;
    localparam [3:0] OP_NOR   = 4'b1111;

    reg [WIDTH:0] temp_result;
    wire [WIDTH-1:0] a_unsigned;
    wire [WIDTH-1:0] b_unsigned;

    assign a_unsigned = input_a;
    assign b_unsigned = input_b;

    always @(*) begin
        output_result = {WIDTH{1'b0}};
        temp_result = {WIDTH+1{1'b0}};

        case (operation)
            OP_ADD: begin
                temp_result = {1'b0, input_a} + {1'b0, input_b};
                output_result = temp_result[WIDTH-1:0];
            end
            
            OP_SUB: begin
                temp_result = {1'b0, input_a} + {1'b0, ~input_b} + 1;
                output_result = temp_result[WIDTH-1:0];
            end
            
            OP_INC: begin
                temp_result = {1'b0, input_a} + 1;
                output_result = temp_result[WIDTH-1:0];
            end
            
            OP_DEC: begin
                temp_result = {1'b0, input_a} - 1;
                output_result = temp_result[WIDTH-1:0];
            end

            OP_AND: 
                output_result = input_a & input_b;
            
            OP_OR: 
                output_result = input_a | input_b;
            
            OP_XOR: 
                output_result = input_a ^ input_b;
            
            OP_NOT: 
                output_result = ~input_a;

            OP_SLL: 
                output_result = input_a << input_b[3:0];
            
            OP_SRL: 
                output_result = input_a >> input_b[3:0];
            
            OP_SRA: 
                output_result = $signed(input_a) >>> input_b[3:0];

            OP_EQ: 
                output_result = (input_a == input_b) ? 1 : 0;
            
            OP_SLT: 
                output_result = ($signed(input_a) < $signed(input_b)) ? 1 : 0;
            
            OP_SLTU: 
                output_result = (input_a < input_b) ? 1 : 0;

            OP_NAND: 
                output_result = ~(input_a & input_b);
            
            OP_NOR: 
                output_result = ~(input_a | input_b);

            default: 
                output_result = {WIDTH{1'b0}};
        endcase
    end

    assign zero_flag = (output_result == {WIDTH{1'b0}});
    assign negative_flag = output_result[WIDTH-1];
    assign parity_flag = ^output_result;

    wire sign_a = input_a[WIDTH-1];
    wire sign_b = input_b[WIDTH-1];
    wire sign_result = output_result[WIDTH-1];

    assign carry_flag = temp_result[WIDTH];
    assign overflow_flag = (operation == OP_ADD) ? ((~sign_a & ~sign_b & sign_result) | (sign_a & sign_b & ~sign_result)) :
                          (operation == OP_SUB) ? ((~sign_a & sign_b & sign_result) | (sign_a & ~sign_b & ~sign_result)) :
                          (operation == OP_INC) ? (~sign_a & sign_result) :
                          (operation == OP_DEC) ? (sign_a & ~sign_result) : 1'b0;

endmodule
