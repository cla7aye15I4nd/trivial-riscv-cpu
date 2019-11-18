`include "../../common_defs.vh"
`include "../cpu_defs.vh"

module decoder_type_s (
    input  wire `inst_t     inst,

    output reg  `oper_t      op,
    output wire `word_t      imm,
    output wire `regaddr_t   reg_read_addr0,
    output wire `regaddr_t   reg_read_addr1
);

assign reg_read_addr0 = inst[19 : 15];
assign reg_read_addr1 = inst[24 : 20];
assign imm            = $signed(inst[31 : 25]);

always @(*) begin
    case (inst[14: 12]) 
        3'b000: op = `OP_SB;
        3'b001: op = `OP_SH;
        3'b010: op = `OP_SW;
        default: op = `OP_NOP;
    endcase
end
endmodule // decoder_type_s