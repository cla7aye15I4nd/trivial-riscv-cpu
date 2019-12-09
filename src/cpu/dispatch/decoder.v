`define SET_SIGNAL(x, y, z) \
    en_rx = x;             \
    en_ry = y;             \
    en_w  = z;

module decoder(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire hit,
    input wire issue,
    input wire `addr_t pc_in,
    input wire `inst_t inst_in,

    output reg `addr_t pc_out,
    output reg `oper_t op, 
    output reg `word_t imm,
    output reg en_rx,
    output reg en_ry,
    output reg en_w,
    output reg `regaddr_t reg_read_addrx,
    output reg `regaddr_t reg_read_addry,
    output reg `regaddr_t reg_write_addr
);

reg `addr_t pc;
reg `inst_t inst;
wire `oper_t op_i, op_r, op_s, op_b;
wire `word_t imm_i, imm_s, imm_b;
wire `regaddr_t reg_read_addrx_r, reg_read_addrx_s, reg_read_addrx_b;
wire `regaddr_t reg_read_addry_i, reg_read_addry_r, reg_read_addry_s, reg_read_addry_b;
wire `regaddr_t reg_write_addr_i, reg_write_addr_r;

decoder_type_i decoder_type_i_instance(
    .inst(inst),

    .op(op_i),
    .imm(imm_i),
    .reg_read_addr(reg_read_addry_i),
    .reg_write_addr(reg_write_addr_i)
);

decoder_type_r decoder_type_r_instance(
    .inst(inst),

    .op(op_r),
    .reg_read_addrx(reg_read_addrx_r),
    .reg_read_addry(reg_read_addry_r),
    .reg_write_addr(reg_write_addr_r)
);

decoder_type_s decoder_type_s_instance(
    .inst(inst),

    .op(op_s),
    .imm(imm_s),
    .reg_read_addrx(reg_read_addrx_s),
    .reg_read_addry(reg_read_addry_s)
);

decoder_type_b decoder_type_b_instance(
    .inst(inst),

    .op(op_b),
    .imm(imm_b),
    .reg_read_addrx(reg_read_addrx_b),
    .reg_read_addry(reg_read_addry_b)
);

always @(posedge clk) begin
    if (rst) begin
        pc <= `ZERO;
        inst <= `ZERO;
    end else /*if(rdy)*/ begin
        if (issue) begin
            if (hit) begin
                pc <= pc_in;
                inst <= inst_in;
            end else begin
                pc <= 0;
                inst <= `OP_NOP;
            end
        end
    end
end

always @(*) begin
    pc_out = pc;
    case (inst[6 : 0]) // optype
        `I_TYPE, `L_TYPE: begin
            op  = op_i;
            imm = imm_i;            
            reg_read_addrx = reg_read_addry_i;
            reg_read_addry = `ZERO;
            reg_write_addr = reg_write_addr_i;
            `SET_SIGNAL(1, 0, 1);
        end
        `R_TYPE: begin
            op  = op_r;
            imm = `ZERO;            
            reg_read_addrx = reg_read_addrx_r;
            reg_read_addry = reg_read_addry_r;
            reg_write_addr = reg_write_addr_r;
            `SET_SIGNAL(1, 1, 1);
        end
        `S_TYPE: begin
            op  = op_s;
            imm = imm_s;            
            reg_read_addrx = reg_read_addrx_s;
            reg_read_addry = reg_read_addry_s;
            reg_write_addr = `ZERO;
            `SET_SIGNAL(1, 1, 0);
        end
        `B_TYPE: begin
            op  = op_b;
            imm = imm_b;
            reg_read_addrx = reg_read_addrx_b;
            reg_read_addry = reg_read_addry_b;
            reg_write_addr = `ZERO;
            `SET_SIGNAL(1, 1, 0);
        end
        7'b0110111: begin //LUI
            op = `OP_LUI;
            imm = {inst[31 : 12], {12{1'b0}}};
            reg_read_addrx = `ZERO;
            reg_read_addry = `ZERO;
            reg_write_addr = inst[11 : 7];
            `SET_SIGNAL(0, 0, 1);
        end
        7'b0010111: begin //AUIPC
            op = `OP_AUIPC;
            imm = {inst[31 : 12], {12{1'b0}}};
            reg_read_addrx = `ZERO;
            reg_read_addry = `ZERO;
            reg_write_addr = inst[11 : 7];
            `SET_SIGNAL(0, 0, 1);
        end
        7'b1101111: begin //JAL
            op = `OP_JAL;
            imm = $signed({inst[31 : 31], inst[19 : 12], inst[20 : 20], inst[30: 21], 1'b0});
            reg_read_addrx = `ZERO;
            reg_read_addry = `ZERO;
            reg_write_addr = inst[11 : 7];
            `SET_SIGNAL(0, 0, 1);
        end
        7'b1100111: begin //JALR
            op = `OP_JALR;
            imm = $signed(inst[31 : 20]);
            reg_read_addrx = `ZERO;
            reg_read_addry = inst[19 : 15];
            reg_write_addr = inst[11 : 7];
            `SET_SIGNAL(0, 1, 1);
        end
        default: begin
            op = `OP_NOP;
            imm = `ZERO;
            reg_read_addrx = `ZERO;
            reg_read_addry = `ZERO;
            reg_write_addr = `ZERO;
            `SET_SIGNAL(0, 0, 0);
        end
    endcase
end

endmodule // decoder