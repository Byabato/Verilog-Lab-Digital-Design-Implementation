`timescale 1ns/1ps

module tb_alu_16bit;

    reg  [15:0] a;
    reg  [15:0] b;
    reg  [3:0]  op;
    wire [15:0] result;
    wire        zero;
    wire        carry;
    wire        overflow;
    wire        negative;
    wire        parity;

    integer total;
    integer pass;
    integer fail;

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

    alu_16bit DUT (
        .input_a(a),
        .input_b(b),
        .operation(op),
        .output_result(result),
        .zero_flag(zero),
        .carry_flag(carry),
        .overflow_flag(overflow),
        .negative_flag(negative),
        .parity_flag(parity)
    );

    task verify;
        input [15:0] exp_res;
        input        exp_z;
        input        exp_c;
        input        exp_o;
        input        exp_n;
        input        exp_p;
        input [80:0] msg;
        begin
            total = total + 1;
            #1;
            
            if (result === exp_res && zero === exp_z && carry === exp_c && 
                overflow === exp_o && negative === exp_n && parity === exp_p) begin
                $display("[OK] %0d. %s", total, msg);
                pass = pass + 1;
            end else begin
                $display("[XX] %0d. %s", total, msg);
                $display("     In: A=0x%h, B=0x%h, OP=%b", a, b, op);
                $display("     Exp: R=0x%h Z=%b C=%b O=%b N=%b P=%b", exp_res, exp_z, exp_c, exp_o, exp_n, exp_p);
                $display("     Got: R=0x%h Z=%b C=%b O=%b N=%b P=%b", result, zero, carry, overflow, negative, parity);
                fail = fail + 1;
            end
        end
    endtask

    initial begin
        total = 0;
        pass = 0;
        fail = 0;

        $display("================================");
        $display("    16-bit ALU Test Suite");
        $display("================================\n");

        $display("ARITHMETIC OPERATIONS\n");

        a = 16'h0007; b = 16'h0005; op = OP_ADD; #10;
        verify(16'h000C, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "7 + 5");

        a = 16'h0000; b = 16'h0000; op = OP_ADD; #10;
        verify(16'h0000, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, "0 + 0 zero flag");

        a = 16'hFFFF; b = 16'h0001; op = OP_ADD; #10;
        verify(16'h0000, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, "Max + 1 overflow");

        a = 16'h7FFF; b = 16'h0001; op = OP_ADD; #10;
        verify(16'h8000, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, "Pos overflow");

        a = 16'h8000; b = 16'h8000; op = OP_ADD; #10;
        verify(16'h0000, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, "Neg overflow");

        a = 16'h0009; b = 16'h0003; op = OP_SUB; #10;
        verify(16'h0006, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, "9 - 3");

        a = 16'h0003; b = 16'h0009; op = OP_SUB; #10;
        verify(16'hFFFC, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, "3 - 9 negative");

        a = 16'h0000; b = 16'h0000; op = OP_SUB; #10;
        verify(16'h0000, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, "0 - 0");

        a = 16'h0005; b = 16'h0000; op = OP_INC; #10;
        verify(16'h0006, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, "5 increment");

        a = 16'hFFFF; b = 16'h0000; op = OP_INC; #10;
        verify(16'h0000, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, "Max increment");

        a = 16'h0005; b = 16'h0000; op = OP_DEC; #10;
        verify(16'h0004, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "5 decrement");

        a = 16'h0000; b = 16'h0000; op = OP_DEC; #10;
        verify(16'hFFFF, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, "0 decrement");

        $display("\nLOGICAL OPERATIONS\n");

        a = 16'h00FF; b = 16'hFF00; op = OP_AND; #10;
        verify(16'h0000, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, "AND zero");

        a = 16'h1234; b = 16'h5678; op = OP_AND; #10;
        verify(16'h1230, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "AND patterns");

        a = 16'h00FF; b = 16'hFF00; op = OP_OR; #10;
        verify(16'hFFFF, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, "OR all ones");

        a = 16'h1234; b = 16'h5678; op = OP_XOR; #10;
        verify(16'h444C, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, "XOR patterns");

        a = 16'h00FF; b = 16'h0000; op = OP_NOT; #10;
        verify(16'hFF00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, "NOT");

        a = 16'h0000; b = 16'h0000; op = OP_NAND; #10;
        verify(16'hFFFF, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, "NAND zeros");

        a = 16'hFFFF; b = 16'hFFFF; op = OP_NOR; #10;
        verify(16'h0000, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, "NOR ones");

        $display("\nSHIFT OPERATIONS\n");

        a = 16'h0001; b = 16'h0004; op = OP_SLL; #10;
        verify(16'h0010, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "SLL: 1 << 4");

        a = 16'h8000; b = 16'h0004; op = OP_SRL; #10;
        verify(16'h0800, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "SRL: 0x8000 >> 4");

        a = 16'h8000; b = 16'h0004; op = OP_SRA; #10;
        verify(16'hF800, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, "SRA: sign extend");

        a = 16'hFFFF; b = 16'h0002; op = OP_SRA; #10;
        verify(16'hFFFF, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, "SRA: all ones");

        $display("\nCOMPARISON OPERATIONS\n");

        a = 16'h0005; b = 16'h0005; op = OP_EQ; #10;
        verify(16'h0001, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "Equal true");

        a = 16'h0005; b = 16'h0003; op = OP_EQ; #10;
        verify(16'h0000, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, "Equal false");

        a = 16'h0003; b = 16'h0005; op = OP_SLT; #10;
        verify(16'h0001, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "SLT: 3 < 5");

        a = 16'hFFFE; b = 16'h0001; op = OP_SLT; #10;
        verify(16'h0001, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "SLT: -2 < 1 signed");

        a = 16'hFFFE; b = 16'h0001; op = OP_SLTU; #10;
        verify(16'h0000, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, "SLTU: 65534 < 1");

        $display("\nEDGE CASES\n");

        a = 16'h0001; b = 16'h000F; op = OP_SLL; #10;
        verify(16'h8000, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, "Max shift left");

        a = 16'hAAAA; b = 16'h5555; op = OP_XOR; #10;
        verify(16'hFFFF, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, "Alternating pattern");

        a = 16'h0001; b = 16'h0000; op = OP_AND; #10;
        verify(16'h0000, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, "AND clears all");

        #10;
        $display("\n================================");
        $display("Total: %0d | Pass: %0d | Fail: %0d", total, pass, fail);
        if (fail == 0)
            $display("Result: ALL TESTS PASSED");
        else
            $display("Result: FAILED");
        $display("================================\n");

        $finish;
    end

    initial begin
        $dumpfile("alu_16bit.vcd");
        $dumpvars(0, tb_alu_16bit);
    end

endmodule
