`timescale 1ns/1ps

module tb_cpu_32bit;

    reg         clk;
    reg         rst;
    wire [31:0] pc;
    wire [31:0] mem_addr;
    wire [31:0] mem_data_out;
    wire        mem_we;
    wire        mem_re;
    wire        halted;

    reg [31:0] instr_mem [0:255];
    reg [31:0] data_mem [0:255];
    reg [31:0] instr;
    reg [31:0] mem_data_in;

    integer cycle;
    integer max_cycles;

    function [31:0] encode_rtype;
        input [4:0] op, dst, src1, src2;
        begin
            encode_rtype = {op, dst, src1, src2, 12'b0};
        end
    endfunction

    function [31:0] encode_itype;
        input [4:0] op, dst, src1;
        input [20:0] imm;
        begin
            encode_itype = {op, dst, src1, imm};
        end
    endfunction

    cpu_32bit DUT (
        .clk(clk),
        .rst(rst),
        .instr(instr),
        .mem_data_in(mem_data_in),
        .pc_out(pc),
        .mem_addr_out(mem_addr),
        .mem_data_out(mem_data_out),
        .mem_we(mem_we),
        .mem_re(mem_re),
        .cpu_halted(halted)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(*) begin
        instr = instr_mem[pc[9:2]];
    end

    always @(posedge clk) begin
        if (mem_we) begin
            data_mem[mem_addr[9:2]] <= mem_data_out;
            $display("[%0t] WRITE: Addr=0x%h Data=0x%h", $time, mem_addr, mem_data_out);
        end
    end

    always @(*) begin
        if (mem_re)
            mem_data_in = data_mem[mem_addr[9:2]];
        else
            mem_data_in = 32'h00000000;
    end

    initial begin
        $display("====================================================");
        $display("           32-bit CPU Test");
        $display("====================================================\n");

        instr_mem[0] = encode_itype(5'b01000, 5'd1, 5'd0, 21'd15);
        instr_mem[1] = encode_itype(5'b01000, 5'd2, 5'd0, 21'd25);
        instr_mem[2] = encode_rtype(5'b00000, 5'd3, 5'd1, 5'd2);
        instr_mem[3] = encode_rtype(5'b00001, 5'd4, 5'd2, 5'd1);
        instr_mem[4] = encode_rtype(5'b00010, 5'd5, 5'd1, 5'd2);
        instr_mem[5] = encode_rtype(5'b00011, 5'd6, 5'd1, 5'd2);
        instr_mem[6] = encode_rtype(5'b00100, 5'd7, 5'd1, 5'd2);
        instr_mem[7] = encode_itype(5'b01100, 5'd0, 5'd0, 21'd0);
        instr_mem[8] = encode_itype(5'b01100, 5'd0, 5'd0, 21'd4);
        instr_mem[9] = encode_itype(5'b01011, 5'd1, 5'd0, 21'd0);
        instr_mem[10] = {5'b11111, 27'b0};

        rst = 1'b1;
        cycle = 0;
        max_cycles = 50;
        #20;
        rst = 1'b0;

        $display("Starting execution...\n");
        $display("Cycle  PC       Instr       Halted");
        $display("------ -------- ----------- ------");

        while (!halted && cycle < max_cycles) begin
            @(posedge clk);
            $display("%5d  0x%06h  0x%08h    %b", cycle, pc, instr, halted);
            cycle = cycle + 1;
        end

        $display("\n====================================================");
        $display("Register File State:");
        $display("  R0 = 0x%08h (always 0)", DUT.REGS.regs[0]);
        $display("  R1 = 0x%08h (expected: 0x0000000F = 15)", DUT.REGS.regs[1]);
        $display("  R2 = 0x%08h (expected: 0x00000019 = 25)", DUT.REGS.regs[2]);
        $display("  R3 = 0x%08h (expected: 0x0000001E = 30)", DUT.REGS.regs[3]);
        $display("  R4 = 0x%08h (expected: 0x0000000A = 10)", DUT.REGS.regs[4]);
        $display("  R5 = 0x%08h", DUT.REGS.regs[5]);
        $display("  R6 = 0x%08h", DUT.REGS.regs[6]);
        $display("  R7 = 0x%08h", DUT.REGS.regs[7]);

        $display("\nMemory State:");
        $display("  Mem[0] = 0x%08h", data_mem[0]);
        $display("  Mem[1] = 0x%08h", data_mem[1]);

        if (DUT.REGS.regs[3] == 32'h0000001E && DUT.REGS.regs[4] == 32'h0000000A) begin
            $display("\nResult: PASSED");
        end else begin
            $display("\nResult: FAILED");
        end

        $display("Total Cycles: %0d", cycle);
        $display("====================================================\n");

        $finish;
    end

    initial begin
        $dumpfile("cpu_32bit.vcd");
        $dumpvars(0, tb_cpu_32bit);
    end

endmodule
