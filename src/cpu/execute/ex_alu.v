module ex_alu(
    // input wire after_in,
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
    output reg alu_busy_out,
    
    // to regfile
    output reg en, 
    output reg `regaddr_t target_out,
    output reg `word_t data_out,

    // to cpu if
    output reg en_jmp,
    output reg `addr_t jmp_addr,

    input wire clk,
    input wire rdy
);

always @(posedge clk) begin
    if (alu_busy_in && alu_tagx_in == `UNLOCKED && alu_tagy_in == `UNLOCKED && alu_tagw_in == `UNLOCKED) begin
        en <= 1;
        alu_busy_out <= 0;
        target_out <= alu_target_in;
        case (alu_op_in)
        `ADD  : begin 
            en_jmp <= 0; 
            jmp_addr <= `ZERO; 
            data_out <= $signed(alu_datax_in) + $signed(alu_datay_in);
        end
        `SUB  : begin 
            en_jmp <= 0; 
            jmp_addr <= `ZERO; 
            data_out <= $signed(alu_datax_in) - $signed(alu_datay_in);        
        end
        `SLL  : begin 
            en_jmp <= 0; 
            jmp_addr <= `ZERO; 
            data_out <= alu_datax_in << alu_datay_in[4 : 0];          
        end
        `SLT  : begin 
            en_jmp <= 0; 
            jmp_addr <= `ZERO; 
            data_out <= $signed(alu_datax_in) < $signed(alu_datay_in) ? 1 : 0;
        end
        `SLTU : begin 
            en_jmp <= 0; 
            jmp_addr <= `ZERO; 
            data_out <= alu_datax_in < alu_datay_in ? 1 : 0;
        end
        `XOR  : begin 
            en_jmp <= 0; 
            jmp_addr <= `ZERO; 
            data_out <= $signed(alu_datax_in) ^ $signed(alu_datay_in);        
        end
        `SRL  : begin 
            en_jmp <= 0; 
            jmp_addr <= `ZERO; 
            data_out <= alu_datax_in >> alu_datay_in[4 : 0];          
        end
        `SRA  : begin 
            en_jmp <= 0; 
            jmp_addr <= `ZERO; 
            data_out <= $signed(alu_datax_in) >>> alu_datay_in[4 : 0];          
        end
        `OR   : begin 
            en_jmp <= 0; 
            jmp_addr <= `ZERO; 
            data_out <= $signed(alu_datax_in) | $signed(alu_datay_in);        
        end
        `AND  : begin 
            en_jmp <= 0; 
            jmp_addr <= `ZERO; 
            data_out <= $signed(alu_datax_in) & $signed(alu_datay_in);        
        end
        `LUI  : begin 
            en_jmp <= 0; 
            jmp_addr <= `ZERO; 
            data_out <= alu_datax_in;                                           
        end
        `AUIPC: begin 
            en_jmp <= 0; 
            jmp_addr <= `ZERO; 
            data_out <= alu_datax_in + pc_in;                                   
        end
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
        default : begin 
            en_jmp <= 0;
            data_out <= `ZERO;
            jmp_addr <= `ZERO;
        end
        endcase
    end else begin
        en <= 0;
        en_jmp <= 0;
        data_out <= `ZERO;
        alu_busy_out <= alu_busy_in;
        target_out <= `ZERO;
    end
end

endmodule // ex_alu