`timescale 1ns/1ps

module regfile_32bit (
    input  wire        clk,
    input  wire        rst,
    input  wire        write_en,
    input  wire [4:0]  write_addr,
    input  wire [4:0]  read_addr_1,
    input  wire [4:0]  read_addr_2,
    input  wire [31:0] write_data,
    output wire [31:0] read_data_1,
    output wire [31:0] read_data_2
);

    reg [31:0] regs [0:7];
    integer i;

    assign read_data_1 = (read_addr_1 == 5'b00000) ? 32'h00000000 : regs[read_addr_1[2:0]];
    assign read_data_2 = (read_addr_2 == 5'b00000) ? 32'h00000000 : regs[read_addr_2[2:0]];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1)
                regs[i] <= {29'b0, i[2:0]};
        end else if (write_en && write_addr != 5'b00000) begin
            regs[write_addr[2:0]] <= write_data;
        end
    end

endmodule

module alu_32bit (
    input  wire [31:0] val_a,
    input  wire [31:0] val_b,
    input  wire [3:0]  ctrl_op,
    output reg  [31:0] val_out,
    output wire        zero_out
);

    localparam [3:0] ALU_ADD = 4'b0000;
    localparam [3:0] ALU_SUB = 4'b0001;
    localparam [3:0] ALU_AND = 4'b0010;
    localparam [3:0] ALU_OR  = 4'b0011;
    localparam [3:0] ALU_XOR = 4'b0100;
    localparam [3:0] ALU_SLL = 4'b0101;
    localparam [3:0] ALU_SRL = 4'b0110;
    localparam [3:0] ALU_SLT = 4'b0111;

    always @(*) begin
        case (ctrl_op)
            ALU_ADD: val_out = val_a + val_b;
            ALU_SUB: val_out = val_a - val_b;
            ALU_AND: val_out = val_a & val_b;
            ALU_OR: val_out = val_a | val_b;
            ALU_XOR: val_out = val_a ^ val_b;
            ALU_SLL: val_out = val_a << val_b[4:0];
            ALU_SRL: val_out = val_a >> val_b[4:0];
            ALU_SLT: val_out = ($signed(val_a) < $signed(val_b)) ? 32'h00000001 : 32'h00000000;
            default: val_out = 32'h00000000;
        endcase
    end

    assign zero_out = (val_out == 32'h00000000);

endmodule

module ctrl_unit (
    input  wire [4:0] instr_op,
    output reg        do_regwr,
    output reg        do_memrd,
    output reg        do_memwr,
    output reg        alu_use_imm,
    output reg        wb_from_mem,
    output reg        do_branch,
    output reg        do_jump,
    output reg        do_halt,
    output reg [3:0]  alu_func
);

    localparam [4:0] OP_ADD  = 5'b00000;
    localparam [4:0] OP_SUB  = 5'b00001;
    localparam [4:0] OP_AND  = 5'b00010;
    localparam [4:0] OP_OR   = 5'b00011;
    localparam [4:0] OP_XOR  = 5'b00100;
    localparam [4:0] OP_ADDI = 5'b01000;
    localparam [4:0] OP_ANDI = 5'b01001;
    localparam [4:0] OP_ORI  = 5'b01010;
    localparam [4:0] OP_LW   = 5'b01011;
    localparam [4:0] OP_SW   = 5'b01100;
    localparam [4:0] OP_BEQ  = 5'b01101;
    localparam [4:0] OP_JMP  = 5'b01110;
    localparam [4:0] OP_HALT = 5'b11111;

    always @(*) begin
        do_regwr = 1'b0;
        do_memrd = 1'b0;
        do_memwr = 1'b0;
        alu_use_imm = 1'b0;
        wb_from_mem = 1'b0;
        do_branch = 1'b0;
        do_jump = 1'b0;
        do_halt = 1'b0;
        alu_func = 4'b0000;

        case (instr_op)
            OP_ADD: begin
                do_regwr = 1'b1;
                alu_func = 4'b0000;
            end
            OP_SUB: begin
                do_regwr = 1'b1;
                alu_func = 4'b0001;
            end
            OP_AND: begin
                do_regwr = 1'b1;
                alu_func = 4'b0010;
            end
            OP_OR: begin
                do_regwr = 1'b1;
                alu_func = 4'b0011;
            end
            OP_XOR: begin
                do_regwr = 1'b1;
                alu_func = 4'b0100;
            end
            OP_ADDI: begin
                do_regwr = 1'b1;
                alu_use_imm = 1'b1;
                alu_func = 4'b0000;
            end
            OP_ANDI: begin
                do_regwr = 1'b1;
                alu_use_imm = 1'b1;
                alu_func = 4'b0010;
            end
            OP_ORI: begin
                do_regwr = 1'b1;
                alu_use_imm = 1'b1;
                alu_func = 4'b0011;
            end
            OP_LW: begin
                do_regwr = 1'b1;
                do_memrd = 1'b1;
                wb_from_mem = 1'b1;
                alu_use_imm = 1'b1;
                alu_func = 4'b0000;
            end
            OP_SW: begin
                do_memwr = 1'b1;
                alu_use_imm = 1'b1;
                alu_func = 4'b0000;
            end
            OP_BEQ: begin
                do_branch = 1'b1;
                alu_func = 4'b0001;
            end
            OP_JMP: begin
                do_jump = 1'b1;
            end
            OP_HALT: begin
                do_halt = 1'b1;
            end
            default: begin
            end
        endcase
    end

endmodule

module cpu_32bit (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] instr,
    input  wire [31:0] mem_data_in,
    output wire [31:0] pc_out,
    output wire [31:0] mem_addr_out,
    output wire [31:0] mem_data_out,
    output wire        mem_we,
    output wire        mem_re,
    output wire        cpu_halted
);

    wire [4:0]  op_code;
    wire [4:0]  dst_reg;
    wire [4:0]  src_reg_1;
    wire [4:0]  src_reg_2;
    wire [20:0] imm_value;
    wire [31:0] imm_ext;

    assign op_code = instr[31:27];
    assign dst_reg = instr[26:22];
    assign src_reg_1 = instr[21:17];
    assign src_reg_2 = instr[16:12];
    assign imm_value = instr[20:0];
    assign imm_ext = {{11{imm_value[20]}}, imm_value};

    wire do_regwr, do_memrd, do_memwr, alu_use_imm, wb_from_mem, do_branch, do_jump, halted_sig;
    wire [3:0] alu_func;

    ctrl_unit CTRL (
        .instr_op(op_code),
        .do_regwr(do_regwr),
        .do_memrd(do_memrd),
        .do_memwr(do_memwr),
        .alu_use_imm(alu_use_imm),
        .wb_from_mem(wb_from_mem),
        .do_branch(do_branch),
        .do_jump(do_jump),
        .do_halt(halted_sig),
        .alu_func(alu_func)
    );

    wire [31:0] src_val_1, src_val_2;
    regfile_32bit REGS (
        .clk(clk),
        .rst(rst),
        .write_en(do_regwr & ~cpu_halted),
        .write_addr(dst_reg),
        .read_addr_1(src_reg_1),
        .read_addr_2(src_reg_2),
        .write_data(wb_data),
        .read_data_1(src_val_1),
        .read_data_2(src_val_2)
    );

    wire [31:0] alu_in_2;
    wire [31:0] alu_out;
    wire        alu_zero;

    assign alu_in_2 = alu_use_imm ? imm_ext : src_val_2;

    alu_32bit ALU (
        .val_a(src_val_1),
        .val_b(alu_in_2),
        .ctrl_op(alu_func),
        .val_out(alu_out),
        .zero_out(alu_zero)
    );

    assign mem_addr_out = alu_out;
    assign mem_data_out = src_val_2;
    assign mem_we = do_memwr & ~cpu_halted;
    assign mem_re = do_memrd & ~cpu_halted;

    wire [31:0] wb_data;
    assign wb_data = wb_from_mem ? mem_data_in : alu_out;

    reg [31:0] pc_reg;
    wire [31:0] pc_next_seq;
    wire [31:0] pc_next_branch;
    wire [31:0] pc_next_jump;
    wire        take_branch;

    assign pc_out = pc_reg;
    assign pc_next_seq = pc_reg + 32'h00000004;
    assign pc_next_branch = pc_reg + (imm_ext << 2);
    assign pc_next_jump = imm_ext;
    assign take_branch = do_branch & alu_zero;

    wire [31:0] pc_next_val;
    assign pc_next_val = do_jump ? pc_next_jump : (take_branch ? pc_next_branch : pc_next_seq);

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_reg <= 32'h00000000;
        else if (~cpu_halted)
            pc_reg <= pc_next_val;
    end

    reg halted_reg;
    always @(posedge clk or posedge rst) begin
        if (rst)
            halted_reg <= 1'b0;
        else if (halted_sig)
            halted_reg <= 1'b1;
    end

    assign cpu_halted = halted_reg;

endmodule
