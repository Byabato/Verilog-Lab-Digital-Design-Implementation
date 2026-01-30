`timescale 1ns/1ps

module tb_rca_32bit;

    reg  [31:0] a;
    reg  [31:0] b;
    reg         c_in;
    reg         sub_mode;
    wire [31:0] sum_result;
    wire        c_out;
    wire        ovf_flag;

    integer tests_run;
    integer tests_pass;
    integer tests_fail;

    rca_32bit DUT (
        .operand_a(a),
        .operand_b(b),
        .carry_in(c_in),
        .subtract_mode(sub_mode),
        .result(sum_result),
        .carry_out(c_out),
        .overflow(ovf_flag)
    );

    task test_case;
        input [31:0] exp_sum;
        input        exp_cout;
        input        exp_ovf;
        input [100:0] desc;
        begin
            tests_run = tests_run + 1;
            #10;
            
            if (sum_result === exp_sum && c_out === exp_cout && ovf_flag === exp_ovf) begin
                $display("[PASS] %0d: %s", tests_run, desc);
                tests_pass = tests_pass + 1;
            end else begin
                $display("[FAIL] %0d: %s", tests_run, desc);
                $display("  Input: A=0x%h, B=0x%h, Cin=%b, Mode=%b", a, b, c_in, sub_mode);
                $display("  Expected: Sum=0x%h, Cout=%b, Ovf=%b", exp_sum, exp_cout, exp_ovf);
                $display("  Got:      Sum=0x%h, Cout=%b, Ovf=%b", sum_result, c_out, ovf_flag);
                tests_fail = tests_fail + 1;
            end
        end
    endtask

    initial begin
        tests_run = 0;
        tests_pass = 0;
        tests_fail = 0;
        sub_mode = 1'b0;
        c_in = 1'b0;

        $display("====================================================");
        $display("         32-bit Ripple Carry Adder Test");
        $display("====================================================\n");

        $display("--- Addition Mode Tests ---");
        a = 32'h00000000; b = 32'h00000000; sub_mode = 0;
        test_case(32'h00000000, 1'b0, 1'b0, "Zero plus zero");

        a = 32'h00001000; b = 32'h00002000; sub_mode = 0;
        test_case(32'h00003000, 1'b0, 1'b0, "Simple addition");

        a = 32'hFFFFFFFF; b = 32'h00000001; sub_mode = 0;
        test_case(32'h00000000, 1'b1, 1'b0, "Max value plus one");

        a = 32'h7FFFFFFF; b = 32'h00000001; sub_mode = 0;
        test_case(32'h80000000, 1'b0, 1'b1, "Signed overflow (pos+pos=neg)");

        a = 32'h80000000; b = 32'h80000000; sub_mode = 0;
        test_case(32'h00000000, 1'b1, 1'b1, "Signed overflow (neg+neg=pos)");

        a = 32'hFFFFFFFF; b = 32'hFFFFFFFF; sub_mode = 0;
        test_case(32'hFFFFFFFE, 1'b1, 1'b0, "Large negative values");

        a = 32'hAAAAAAAA; b = 32'h55555555; sub_mode = 0;
        test_case(32'hFFFFFFFF, 1'b0, 1'b0, "Pattern test");

        c_in = 1'b1;
        a = 32'h00000000; b = 32'h00000000; sub_mode = 0;
        test_case(32'h00000001, 1'b0, 1'b0, "Zero plus zero with carry in");
        c_in = 1'b0;

        $display("\n--- Subtraction Mode Tests ---");
        a = 32'h00000005; b = 32'h00000003; sub_mode = 1;
        test_case(32'h00000002, 1'b0, 1'b0, "5 minus 3");

        a = 32'h00000003; b = 32'h00000005; sub_mode = 1;
        test_case(32'hFFFFFFFE, 1'b1, 1'b0, "3 minus 5 (negative result)");

        a = 32'h00000000; b = 32'h00000000; sub_mode = 1;
        test_case(32'h00000000, 1'b0, 1'b0, "Zero minus zero");

        a = 32'h80000000; b = 32'h00000001; sub_mode = 1;
        test_case(32'h7FFFFFFF, 1'b1, 1'b1, "Min signed minus one");

        a = 32'h7FFFFFFF; b = 32'h80000000; sub_mode = 1;
        test_case(32'hFFFFFFFF, 1'b1, 1'b0, "Max signed minus min signed");

        $display("\n--- Edge Cases ---");
        a = 32'hFFFFFFFF; b = 32'h00000000; sub_mode = 0;
        test_case(32'hFFFFFFFF, 1'b0, 1'b0, "Max plus zero");

        a = 32'h00000001; b = 32'hFFFFFFFF; sub_mode = 0;
        test_case(32'h00000000, 1'b1, 1'b0, "One plus max");

        a = 32'h12345678; b = 32'h87654321; sub_mode = 1;
        test_case(32'hEACF1357, 1'b0, 1'b0, "Random subtraction");

        $display("\n====================================================");
        $display("                   Test Summary");
        $display("====================================================");
        $display("Total: %0d | Pass: %0d | Fail: %0d", tests_run, tests_pass, tests_fail);
        
        if (tests_fail == 0)
            $display("Result: ALL TESTS PASSED");
        else
            $display("Result: SOME TESTS FAILED");
        $display("====================================================\n");

        $finish;
    end

    initial begin
        $dumpfile("rca_32bit.vcd");
        $dumpvars(0, tb_rca_32bit);
    end

endmodule
