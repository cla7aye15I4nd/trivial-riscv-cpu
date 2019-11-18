`include "../../common_defs.vh"
`include "../cpu_defs.vh"

`include "decoder_type_i.v"
`include "decoder_type_r.v"
`include "decoder_type_b.v"
`include "decoder_type_s.v"

module decoder(
    input wire clock,
    input wire `addr_t pc,
    input wire `inst_t inst,

    output reg `oper_t op, 
    output reg `word_t imm,

    output reg `regaddr_t reg_read_addr0,
    output reg `regaddr_t reg_read_addr1,
    output reg `regaddr_t reg_write_addr,

    output reg `memaddr_t mem_read_addr,
    output reg `memaddr_t mem_write_addr
);

wire `oper_t op_i, op_r, op_s, op_b;
wire `word_t imm_i, imm_s, imm_b;
wire `regaddr_t reg_read_addr0_r, reg_read_addr0_s, reg_read_addr0_b;
wire `regaddr_t reg_read_addr1_i, reg_read_addr1_r, reg_read_addr1_s, reg_read_addr1_b;
wire `regaddr_t reg_write_addr_i, reg_write_addr_r;
decoder_type_i decoder_type_i_instance(
    .inst(inst),

    .op(op_i),
    .imm(imm_i),
    .reg_read_addr(reg_read_addr1_i),
    .reg_write_addr(reg_write_addr_i)
);

decoder_type_r decoder_type_r_instance(
    .inst(inst),

    .op(op_r),
    .reg_read_addr0(reg_read_addr0_r),
    .reg_read_addr1(reg_read_addr1_r),
    .reg_write_addr(reg_write_addr_r)
);

decoder_type_s decoder_type_s_instance(
    .inst(inst),

    .op(op_s),
    .imm(imm_s),
    .reg_read_addr0(reg_read_addr0_s),
    .reg_read_addr1(reg_read_addr1_s)
);

decoder_type_b decoder_type_b_instance(
    .inst(inst),

    .op(op_b),
    .imm(imm_b),
    .reg_read_addr0(reg_read_addr0_b),
    .reg_read_addr1(reg_read_addr1_b)
);

always @(posedge clock) begin
    case (inst[6 : 0]) // optype
        `I_TYPE: begin
            op  <= op_i;
            imm <= imm_i;
            reg_read_addr1 <= reg_read_addr1_i;
            reg_write_addr <= reg_write_addr_i;
        end
        `L_TYPE: begin   
            op  <= op_i;
            imm <= imm_i;
            reg_read_addr1 <= reg_read_addr1_i;
            reg_write_addr <= reg_write_addr_i;
        end
        `R_TYPE: begin
            op  <= op_r;
            reg_read_addr0 <= reg_read_addr0_r;
            reg_read_addr1 <= reg_read_addr1_r;
            reg_write_addr <= reg_write_addr_r;
        end
        `S_TYPE: begin
            op  <= op_s;
            imm <= imm_s;
            reg_read_addr0 <= reg_read_addr0_s;
            reg_read_addr1 <= reg_read_addr1_s;
        end
        `B_TYPE: begin
            op  <= op_b;
            imm <= imm_b;
            reg_read_addr0 <= reg_read_addr0_b;
            reg_read_addr1 <= reg_read_addr1_b;
        end
        7'b0110111: begin //LUI
            op <= `OP_LUI;
            imm <= $signed(inst[31 : 12]);
            reg_write_addr <= inst[11 : 7];
        end
        7'b0010111: begin //AUIPC
            op <= `OP_LUI;
            imm <= $signed(inst[31 : 12]);
            reg_write_addr <= inst[11 : 7];
        end
        7'b1101111: begin //JAL
            op <= `OP_JAL;
            imm <= $signed({inst[31 : 31], inst[19 : 12], inst[20 : 20], inst[30: 21]});
            reg_write_addr <= inst[11 : 7];
        end
        7'b1100111: begin //JALR
            op <= `OP_JALR;
            imm <= $signed(inst[31 : 20]);
            reg_read_addr0 <= inst[19 : 15];
            reg_write_addr <= inst[11 : 7];
        end
    endcase
end

endmodule // decoder