`include "common_defs.vh"
`include "cpu/cpu_defs.vh"

`include "cpu/id/decoder_type_i.v"
`include "cpu/id/decoder_type_r.v"
`include "cpu/id/decoder_type_b.v"
`include "cpu/id/decoder_type_s.v"

`define SET_SIGNAL(x, y, z) \
    en_rx <= x;             \
    en_ry <= y;             \
    en_w  <= z;

module decoder(
    input wire clk,
    input wire rdy,

    input wire hit,
    input wire `addr_t pc,
    input wire `inst_t inst,

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
    pc_out <= pc;
    if (rdy) begin
        if (hit == 0) begin
            op <= `OP_NOP;
            `SET_SIGNAL(0, 0, 0);
        end else begin
            case (inst[6 : 0]) // optype
                `I_TYPE: begin
                    op  <= op_i;
                    imm <= imm_i;
                    `SET_SIGNAL(0, 1, 1);
                    reg_read_addry <= reg_read_addry_i;
                    reg_write_addr <= reg_write_addr_i;
                end
                `L_TYPE: begin   
                    op  <= op_i;
                    imm <= imm_i;
                    `SET_SIGNAL(0, 1, 1);
                    reg_read_addry <= reg_read_addry_i;
                    reg_write_addr <= reg_write_addr_i;
                end
                `R_TYPE: begin
                    op  <= op_r;
                    `SET_SIGNAL(1, 1, 1);
                    reg_read_addrx <= reg_read_addrx_r;
                    reg_read_addry <= reg_read_addry_r;
                    reg_write_addr <= reg_write_addr_r;
                end
                `S_TYPE: begin
                    op  <= op_s;
                    imm <= imm_s;
                    `SET_SIGNAL(1, 1, 0);
                    reg_read_addrx <= reg_read_addrx_s;
                    reg_read_addry <= reg_read_addry_s;
                end
                `B_TYPE: begin
                    op  <= op_b;
                    imm <= imm_b;
                    `SET_SIGNAL(1, 1, 0);
                    reg_read_addrx <= reg_read_addrx_b;
                    reg_read_addry <= reg_read_addry_b;
                end
                7'b0110111: begin //LUI
                    op <= `OP_LUI;
                    imm <= {inst[31 : 12], {12{1'b0}}};
                    reg_write_addr <= inst[11 : 7];
                    `SET_SIGNAL(0, 0, 1);
                end
                7'b0010111: begin //AUIPC
                    op <= `OP_AUIPC;
                    imm <= {inst[31 : 12], {12{1'b0}}};
                    reg_write_addr <= inst[11 : 7];
                    `SET_SIGNAL(0, 0, 1);
                end
                7'b1101111: begin //JAL
                    op <= `OP_JAL;
                    imm <= $signed({inst[31 : 31], inst[19 : 12], inst[20 : 20], inst[30: 21], 1'b0});
                    reg_write_addr <= inst[11 : 7];
                    `SET_SIGNAL(0, 0, 1);
                end
                7'b1100111: begin //JALR
                    op <= `OP_JALR;
                    imm <= $signed(inst[31 : 20]);
                    reg_read_addrx <= inst[19 : 15];
                    reg_write_addr <= inst[11 : 7];
                    `SET_SIGNAL(1, 0, 1);
                end
            endcase
        end
    end
end

endmodule // decoder