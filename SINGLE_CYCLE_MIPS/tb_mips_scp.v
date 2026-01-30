`timescale 1ns/1ps

module tb_mips_scp;

    reg         clk;
    reg         rst;
    wire [31:0] pc;
    wire [31:0] mem_addr;
    wire [31:0] mem_write;
    wire        mem_we;

    reg [31:0] iram [0:255];
    reg [31:0] dram [0:255];
    wire [31:0] instr;
    reg [31:0] mem_read;

    integer cycle;
    integer max_cyc;

    function [31:0] make_rtype;
        input [5:0] fn;
        input [4:0] r_s, r_t, r_d;
        begin
            make_rtype = {6'b000000, r_s, r_t, r_d, 5'b00000, fn};
        end
    endfunction

    function [31:0] make_itype;
        input [5:0] op;
        input [4:0] r_s, r_t;
        input [15:0] i_val;
        begin
            make_itype = {op, r_s, r_t, i_val};
        end
    endfunction

    function [31:0] make_jtype;
        input [5:0] op;
        input [25:0] j_addr;
        begin
            make_jtype = {op, j_addr};
        end
    endfunction

    mips_scp DUT (
        .clk(clk),
        .rst(rst),
        .pc(pc),
        .instr(instr),
        .mem_addr(mem_addr),
        .mem_write(mem_write),
        .mem_we(mem_we),
        .mem_read(mem_read)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    assign instr = iram[pc[9:2]];

    always @(posedge clk) begin
        if (mem_we) begin
            dram[mem_addr[9:2]] <= mem_write;
            $display("[%0t] WRITE: Addr=0x%h, Data=0x%h", $time, mem_addr, mem_write);
        end
    end

    always @(*) begin
        mem_read = dram[mem_addr[9:2]];
    end

    initial begin
        $display("====================================================");
        $display("      Single-Cycle MIPS Processor Test");
        $display("====================================================\n");

        iram[0]  = make_itype(6'b001000, 5'd0, 5'd1, 16'd8);
        iram[1]  = make_itype(6'b001000, 5'd0, 5'd2, 16'd12);
        iram[2]  = make_itype(6'b001000, 5'd0, 5'd3, 16'd4);
        iram[3]  = make_itype(6'b001000, 5'd0, 5'd4, 16'hFFFD);

        iram[4]  = make_rtype(6'b100000, 5'd1, 5'd2, 5'd5);
        iram[5]  = make_rtype(6'b100010, 5'd2, 5'd3, 5'd6);

        iram[6]  = make_rtype(6'b100100, 5'd1, 5'd2, 5'd7);
        iram[7]  = make_rtype(6'b100101, 5'd1, 5'd2, 5'd8);

        iram[8]  = make_rtype(6'b101010, 5'd1, 5'd2, 5'd9);
        iram[9]  = make_rtype(6'b101010, 5'd2, 5'd1, 5'd10);

        iram[10] = make_itype(6'b101011, 5'd0, 5'd5, 16'd0);
        iram[11] = make_itype(6'b101011, 5'd0, 5'd6, 16'd4);
        iram[12] = make_itype(6'b101011, 5'd0, 5'd9, 16'd8);

        iram[13] = make_itype(6'b100011, 5'd0, 5'd11, 16'd0);
        iram[14] = make_itype(6'b100011, 5'd0, 5'd12, 16'd4);

        iram[15] = make_itype(6'b000100, 5'd1, 5'd1, 16'd1);
        iram[16] = make_itype(6'b001000, 5'd0, 5'd13, 16'd999);
        iram[17] = make_itype(6'b001000, 5'd0, 5'd13, 16'd100);

        iram[18] = make_itype(6'b000100, 5'd1, 5'd2, 16'd1);
        iram[19] = make_itype(6'b001000, 5'd0, 5'd14, 16'd200);

        iram[20] = make_jtype(6'b000010, 26'd21);

        rst = 1'b1;
        cycle = 0;
        max_cyc = 30;
        #20;
        rst = 1'b0;

        $display("Starting execution...\n");
        $display("Cyc  PC       Instr       OP    Halted");
        $display("---- -------- ----------- ---- ------");

        while (cycle < max_cyc) begin
            @(posedge clk);
            $display("%3d  0x%06h  0x%08h  %b", 
                     cycle, pc, instr, instr[31:26]);
            cycle = cycle + 1;
        end

        $display("\n====================================================");
        $display("Register Values:");
        $display("  $1  = 0x%08h (exp: 0x00000008 = 8)", DUT.RF.mem[1]);
        $display("  $2  = 0x%08h (exp: 0x0000000C = 12)", DUT.RF.mem[2]);
        $display("  $3  = 0x%08h (exp: 0x00000004 = 4)", DUT.RF.mem[3]);
        $display("  $4  = 0x%08h (exp: 0xFFFFFFFD = -3)", DUT.RF.mem[4]);
        $display("  $5  = 0x%08h (exp: 0x00000014 = 20)", DUT.RF.mem[5]);
        $display("  $6  = 0x%08h (exp: 0x00000008 = 8)", DUT.RF.mem[6]);
        $display("  $7  = 0x%08h", DUT.RF.mem[7]);
        $display("  $8  = 0x%08h", DUT.RF.mem[8]);
        $display("  $9  = 0x%08h (exp: 0x00000001)", DUT.RF.mem[9]);
        $display("  $10 = 0x%08h (exp: 0x00000000)", DUT.RF.mem[10]);
        $display("  $11 = 0x%08h (exp: 0x00000014)", DUT.RF.mem[11]);
        $display("  $12 = 0x%08h (exp: 0x00000008)", DUT.RF.mem[12]);
        $display("  $13 = 0x%08h (exp: 0x00000064 = 100)", DUT.RF.mem[13]);
        $display("  $14 = 0x%08h (exp: 0x000000C8 = 200)", DUT.RF.mem[14]);

        $display("\nMemory Values:");
        $display("  Mem[0] = 0x%08h (exp: 0x00000014 = 20)", dram[0]);
        $display("  Mem[1] = 0x%08h (exp: 0x00000008 = 8)", dram[1]);
        $display("  Mem[2] = 0x%08h (exp: 0x00000001)", dram[2]);

        if (DUT.RF.mem[5] == 32'h00000014 && 
            DUT.RF.mem[6] == 32'h00000008 && 
            DUT.RF.mem[9] == 32'h00000001 &&
            dram[0] == 32'h00000014) begin
            $display("\nResult: PASSED");
        end else begin
            $display("\nResult: FAILED");
        end

        $display("Total Cycles: %0d", cycle);
        $display("====================================================\n");

        $finish;
    end

    initial begin
        $dumpfile("mips_scp.vcd");
        $dumpvars(0, tb_mips_scp);
    end

endmodule
