`timescale 1ns/1ps

module mips_regfile #(parameter REGS = 32) (
    input  wire        clk,
    input  wire        rst,
    input  wire        write_en,
    input  wire [4:0]  read_a,
    input  wire [4:0]  read_b,
    input  wire [4:0]  write_a,
    input  wire [31:0] write_d,
    output wire [31:0] out_a,
    output wire [31:0] out_b
);

    reg [31:0] mem [0:REGS-1];
    integer i;

    assign out_a = (read_a == 5'b00000) ? 32'h00000000 : mem[read_a];
    assign out_b = (read_b == 5'b00000) ? 32'h00000000 : mem[read_b];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < REGS; i = i + 1)
                mem[i] <= 32'h00000000;
        end else if (write_en && write_a != 5'b00000) begin
            mem[write_a] <= write_d;
        end
    end

endmodule

module mips_alu #(parameter WIDTH = 32) (
    input  wire [WIDTH-1:0] src_a,
    input  wire [WIDTH-1:0] src_b,
    input  wire [2:0]       func,
    output reg  [WIDTH-1:0] res,
    output wire             zero
);

    localparam [2:0] FN_AND = 3'b000;
    localparam [2:0] FN_OR  = 3'b001;
    localparam [2:0] FN_ADD = 3'b010;
    localparam [2:0] FN_SUB = 3'b110;
    localparam [2:0] FN_SLT = 3'b111;
    localparam [2:0] FN_NOR = 3'b100;

    always @(*) begin
        case (func)
            FN_AND: res = src_a & src_b;
            FN_OR:  res = src_a | src_b;
            FN_ADD: res = src_a + src_b;
            FN_SUB: res = src_a - src_b;
            FN_SLT: res = ($signed(src_a) < $signed(src_b)) ? 32'h00000001 : 32'h00000000;
            FN_NOR: res = ~(src_a | src_b);
            default: res = 32'h00000000;
        endcase
    end

    assign zero = (res == 32'h00000000);

endmodule

module mips_alu_dec (
    input  wire [5:0] funct,
    input  wire [1:0] alu_op,
    output reg  [2:0] alu_ctrl
);

    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = 3'b010;
            2'b01: alu_ctrl = 3'b110;
            2'b10: begin
                case (funct)
                    6'b100000: alu_ctrl = 3'b010;
                    6'b100010: alu_ctrl = 3'b110;
                    6'b100100: alu_ctrl = 3'b000;
                    6'b100101: alu_ctrl = 3'b001;
                    6'b101010: alu_ctrl = 3'b111;
                    default:   alu_ctrl = 3'b000;
                endcase
            end
            default: alu_ctrl = 3'b000;
        endcase
    end

endmodule

module mips_ctrl (
    input  wire [5:0] op,
    output reg        reg_w,
    output reg        reg_d,
    output reg        alu_s,
    output reg        branch,
    output reg        mem_w,
    output reg        mem_r,
    output reg        jump,
    output reg [1:0] alu_op
);

    localparam [5:0] OP_RTYPE = 6'b000000;
    localparam [5:0] OP_LW    = 6'b100011;
    localparam [5:0] OP_SW    = 6'b101011;
    localparam [5:0] OP_BEQ   = 6'b000100;
    localparam [5:0] OP_ADDI  = 6'b001000;
    localparam [5:0] OP_ANDI  = 6'b001100;
    localparam [5:0] OP_ORI   = 6'b001101;
    localparam [5:0] OP_J     = 6'b000010;

    always @(*) begin
        reg_w = 1'b0;
        reg_d = 1'b0;
        alu_s = 1'b0;
        branch = 1'b0;
        mem_w = 1'b0;
        mem_r = 1'b0;
        jump = 1'b0;
        alu_op = 2'b00;

        case (op)
            OP_RTYPE: begin
                reg_w = 1'b1;
                reg_d = 1'b1;
                alu_op = 2'b10;
            end
            OP_LW: begin
                reg_w = 1'b1;
                alu_s = 1'b1;
                mem_r = 1'b1;
                alu_op = 2'b00;
            end
            OP_SW: begin
                alu_s = 1'b1;
                mem_w = 1'b1;
                alu_op = 2'b00;
            end
            OP_BEQ: begin
                branch = 1'b1;
                alu_op = 2'b01;
            end
            OP_ADDI: begin
                reg_w = 1'b1;
                alu_s = 1'b1;
                alu_op = 2'b00;
            end
            OP_ANDI: begin
                reg_w = 1'b1;
                alu_s = 1'b1;
                alu_op = 2'b10;
            end
            OP_ORI: begin
                reg_w = 1'b1;
                alu_s = 1'b1;
                alu_op = 2'b10;
            end
            OP_J: begin
                jump = 1'b1;
            end
            default: begin
            end
        endcase
    end

endmodule

module mips_scp (
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] pc,
    input  wire [31:0] instr,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_write,
    output wire        mem_we,
    input  wire [31:0] mem_read
);

    wire [5:0]  op;
    wire [4:0]  rs, rt, rd;
    wire [15:0] imm;
    wire [5:0]  func;
    wire [25:0] jaddr;

    assign op = instr[31:26];
    assign rs = instr[25:21];
    assign rt = instr[20:16];
    assign rd = instr[15:11];
    assign func = instr[5:0];
    assign imm = instr[15:0];
    assign jaddr = instr[25:0];

    wire reg_w, reg_d, alu_s, branch, mem_w, mem_r, jump;
    wire [1:0] alu_op;

    mips_ctrl CTRL (
        .op(op),
        .reg_w(reg_w),
        .reg_d(reg_d),
        .alu_s(alu_s),
        .branch(branch),
        .mem_w(mem_w),
        .mem_r(mem_r),
        .jump(jump),
        .alu_op(alu_op)
    );

    wire [2:0] alu_ctrl;
    mips_alu_dec ALU_DEC (
        .funct(func),
        .alu_op(alu_op),
        .alu_ctrl(alu_ctrl)
    );

    wire [4:0] wr_reg;
    wire [31:0] wr_data;
    wire [31:0] rd1, rd2;

    assign wr_reg = reg_d ? rd : rt;

    mips_regfile #(.REGS(32)) RF (
        .clk(clk),
        .rst(rst),
        .write_en(reg_w),
        .read_a(rs),
        .read_b(rt),
        .write_a(wr_reg),
        .write_d(wr_data),
        .out_a(rd1),
        .out_b(rd2)
    );

    wire [31:0] imm_ext;
    assign imm_ext = {{16{imm[15]}}, imm};

    wire [31:0] alu_b;
    wire [31:0] alu_res;
    wire        alu_zero;

    assign alu_b = alu_s ? imm_ext : rd2;

    mips_alu #(.WIDTH(32)) ALU (
        .src_a(rd1),
        .src_b(alu_b),
        .func(alu_ctrl),
        .res(alu_res),
        .zero(alu_zero)
    );

    assign mem_addr = alu_res;
    assign mem_write = rd2;
    assign mem_we = mem_w;

    assign wr_data = mem_r ? mem_read : alu_res;

    reg [31:0] pc_r;
    wire [31:0] pc_inc;
    wire [31:0] pc_tgt;
    wire [31:0] pc_jump;
    wire        pc_src;

    assign pc = pc_r;
    assign pc_inc = pc_r + 32'h00000004;
    assign pc_tgt = pc_inc + (imm_ext << 2);
    assign pc_jump = {pc_inc[31:28], jaddr, 2'b00};
    assign pc_src = branch & alu_zero;

    wire [31:0] pc_next_val;
    assign pc_next_val = jump ? pc_jump : (pc_src ? pc_tgt : pc_inc);

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_r <= 32'h00000000;
        else
            pc_r <= pc_next_val;
    end

endmodule
