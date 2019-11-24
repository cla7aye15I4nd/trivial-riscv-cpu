module ex_alu(
    input wire alu_busy_in,
    input wire `sinst_t alu_op_in,
    input wire `regtag_t alu_tagx_in,
    input wire `regtag_t alu_tagy_in,
    input wire `regtag_t alu_tagw_in,
    input wire `word_t alu_datax_in,
    input wire `word_t alu_datay_in,
    input wire `regaddr_t alu_target_in,

    // to alloctor
    output wire alu_busy_out,
    output wire `regtag_t alu_tagx_out,
    output wire `regtag_t alu_tagy_out,
    output wire `regtag_t alu_tagw_out,
    
    // to regfile
    output wire en,
    output wire `regaddr_t target_out,
    output reg `word_t data_out
);

assign alu_tagx_out  = alu_tagx_in;
assign alu_tagy_out  = alu_tagy_in;
assign alu_tagw_out  = alu_tagw_in;
assign target_out = alu_target_in;
assign alu_busy_out = (alu_busy_in && alu_tagx_in == `UNLOCKED && alu_tagy_in == `UNLOCKED && alu_tagw_in == `UNLOCKED) ? 0 : 1;
assign en = (alu_busy_in && alu_tagx_in == `UNLOCKED && alu_tagy_in == `UNLOCKED && alu_tagw_in == `UNLOCKED) ? 1 : 0;

always @(*) begin
    if (alu_busy_in && alu_tagx_in == `UNLOCKED && alu_tagy_in == `UNLOCKED && alu_tagw_in == `UNLOCKED) begin
        case (alu_op_in)
        `ADD  : data_out = $signed(alu_datax_in) +   $signed(alu_datay_in);
        `SUB  : data_out = $signed(alu_datax_in) -   $signed(alu_datay_in);
        `SLL  : data_out = alu_datax_in          <<  alu_datay_in[4 : 0];
        `SLT  : data_out = $signed(alu_datax_in) <   $signed(alu_datay_in) ? 1 : 0;
        `SLTU : data_out = alu_datax_in          <   alu_datay_in          ? 1 : 0;
        `XOR  : data_out = $signed(alu_datax_in) ^   $signed(alu_datay_in);
        `SRL  : data_out = alu_datax_in          >>  alu_datay_in[4 : 0];
        `SRA  : data_out = $signed(alu_datax_in) >>> alu_datay_in[4 : 0];
        `OR   : data_out = $signed(alu_datax_in) |   $signed(alu_datay_in);
        `LUI  : data_out = alu_datax_in;
        endcase
    end
end

endmodule // ex_alu