module ex_alu(
    input wire `addr_t pc_in,
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
    output reg `word_t data_out,

    // to cpu if
    output reg en_jmp,
    output reg `addr_t jmp_addr,

    input wire clk
);

assign alu_tagx_out  = alu_tagx_in;
assign alu_tagy_out  = alu_tagy_in;
assign alu_tagw_out  = alu_tagw_in;
assign target_out = alu_target_in;
assign alu_busy_out = (
                        alu_busy_in == 0 ||
                        (
                            alu_busy_in && 
                            alu_tagx_in == `UNLOCKED && 
                            alu_tagy_in == `UNLOCKED && 
                            alu_tagw_in == `UNLOCKED
                        )
                    ) ? 0 : 1;
assign en = (
                alu_busy_in &&
                alu_tagx_in == `UNLOCKED && 
                alu_tagy_in == `UNLOCKED && 
                alu_tagw_in == `UNLOCKED
            ) ? 1 : 0;

always @(posedge clk) begin
    if (alu_busy_in && alu_tagx_in == `UNLOCKED && alu_tagy_in == `UNLOCKED && alu_tagw_in == `UNLOCKED) begin
        case (alu_op_in)
        `ADD  : begin en_jmp <= 0; data_out <= $signed(alu_datax_in) +   $signed(alu_datay_in);        end
        `SUB  : begin en_jmp <= 0; data_out <= $signed(alu_datax_in) -   $signed(alu_datay_in);        end
        `SLL  : begin en_jmp <= 0; data_out <= alu_datax_in          <<  alu_datay_in[4 : 0];          end
        `SLT  : begin en_jmp <= 0; data_out <= $signed(alu_datax_in) <   $signed(alu_datay_in) ? 1 : 0;end
        `SLTU : begin en_jmp <= 0; data_out <= alu_datax_in          <   alu_datay_in          ? 1 : 0;end
        `XOR  : begin en_jmp <= 0; data_out <= $signed(alu_datax_in) ^   $signed(alu_datay_in);        end
        `SRL  : begin en_jmp <= 0; data_out <= alu_datax_in          >>  alu_datay_in[4 : 0];          end
        `SRA  : begin en_jmp <= 0; data_out <= $signed(alu_datax_in) >>> alu_datay_in[4 : 0];          end
        `OR   : begin en_jmp <= 0; data_out <= $signed(alu_datax_in) |   $signed(alu_datay_in);        end
        `LUI  : begin en_jmp <= 0; data_out <= alu_datax_in;                                           end
        `AUIPC: begin en_jmp <= 0; data_out <= alu_datax_in + pc_in;                                   end
        `JAL  : begin
            en_jmp <= 1;
            data_out <= pc_in + 4;
            jmp_addr <= pc_in + alu_datax_in;
        end
        `JALR : begin
            en_jmp <= 1;
            data_out <= pc_in + 4;
            jmp_addr <= (alu_datax_in + alu_datay_in) & 32'hfffffffe;
        end
        endcase
    end
end

endmodule // ex_alu