`define Inst(_op, _imm) \
begin                   \
    op = _op;           \
    imm = _imm;         \
end

module decoder_type_i(
    input wire `inst_t     inst,

    output reg `oper_t      op,
    output reg `dword_t      imm,
    output wire `regaddr_t   reg_read_addr,
    output wire `regaddr_t   reg_write_addr
);
/* I-type and L-type use same decoder */

wire `dword_t imm0;
assign reg_read_addr  = inst[19 : 15];
assign reg_write_addr = inst[11 : 7];
assign imm0 = $signed(inst[31 : 20]); /* may can use less wires */

always @(*) begin
    if (inst[6 : 0] == `I_TYPE) begin
        case (inst[14: 12]) 
            3'b000: `Inst(`OP_ADDI , imm0)
            3'b010: `Inst(`OP_SLTI , imm0)
            3'b011: `Inst(`OP_SLTIU, $unsigned(inst[31 : 20]))
            3'b100: `Inst(`OP_XORI , imm0)
            3'b110: `Inst(`OP_ORI  , imm0)
            3'b111: `Inst(`OP_ANDI , imm0)
            3'b001: `Inst(`OP_SLLI , $signed(inst[24 : 20]))
            3'b101: `Inst(`OP_SRLI | inst[31 : 30], $signed(inst[24 : 20]))
            default: `Inst(`OP_NOP, `ZERO)
        endcase 
    end else begin
        case (inst[14: 12]) 
            3'b000: `Inst(`OP_LB , imm0)
            3'b001: `Inst(`OP_LH , imm0)
            3'b010: `Inst(`OP_LW , imm0)
            3'b100: `Inst(`OP_LBU, imm0)
            3'b101: `Inst(`OP_LHU, imm0)
            default: `Inst(`OP_NOP, `ZERO)
        endcase
    end
end
endmodule // decoder_type_i