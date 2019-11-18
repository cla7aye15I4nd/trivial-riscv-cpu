`include "../../common_defs.vh"
`include "../cpu_defs.vh"

module decoder_type_b (
    input  wire `inst_t     inst,

    output reg `oper_t      op,
    output wire `word_t      imm,
    output wire `regaddr_t   reg_read_addr0,
    output wire `regaddr_t   reg_read_addr1
);

assign reg_read_addr0 = inst[19 : 15];
assign reg_read_addr1 = inst[24 : 20];
assign imm            = $signed({inst[31 : 31], inst[7 : 7], inst[30 : 25], inst[11 : 8]});

always @ (*) begin
    case (inst[14: 12]) 
        3'b000: op = `OP_BEQ;
        3'b001: op = `OP_BNE;
        3'b100: op = `OP_BLT;
        3'b101: op = `OP_BGE;
        3'b110: op = `OP_BLTU;
        3'b111: op = `OP_BGEU;
        default: op = `OP_NOP;
    endcase
end
endmodule // decoder_type_s