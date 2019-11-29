module decoder_type_s (
    input  wire `inst_t     inst,

    output reg  `oper_t      op,
    output wire `dword_t      imm,
    output wire `regaddr_t   reg_read_addrx,
    output wire `regaddr_t   reg_read_addry
);

assign reg_read_addrx = inst[19 : 15];
assign reg_read_addry = inst[24 : 20];
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