`include "../../common_defs.vh"
`include "../cpu_defs.vh"

module decoder_type_r (
    input  wire `inst_t     inst,

    output reg `oper_t      op,
    output wire `regaddr_t   reg_read_addr0,
    output wire `regaddr_t   reg_read_addr1,
    output wire `regaddr_t   reg_write_addr
);
assign reg_read_addr0 = inst[19 : 15];
assign reg_read_addr1 = inst[24 : 20];
assign reg_write_addr = inst[11 : 7];

always @(*) begin
    case (inst[14: 12]) 
        3'b000: op = `OP_ADD | inst[31 : 30];
        3'b001: op = `OP_SLL;
        3'b010: op = `OP_SLT;
        3'b011: op = `OP_SLTU;
        3'b100: op = `OP_XOR;
        3'b101: op = `OP_SRL | inst[31 : 30];
        3'b110: op = `OP_OR;
        3'b111: op = `OP_AND;
        default: op = `OP_NOP;
    endcase
end
endmodule // decoder_type_r