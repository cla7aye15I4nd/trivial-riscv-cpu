module ex_branch(
    input wire `addr_t pc_in,
    input wire `word_t offset_in,
    input wire branch_busy_in,
    input wire `sinst_t branch_op_in,
    input wire `regtag_t branch_tagx_in,
    input wire `regtag_t branch_tagy_in,
    input wire `word_t branch_datax_in,
    input wire `word_t branch_datay_in,

    // to alloctor
    output wire branch_busy_out,
    
    // to if
    // input wire `word_t predict,
    output reg en,
    output reg `word_t dest_out,

    input wire clk,
    input wire rdy
);

assign branch_busy_out = (
                        branch_busy_in == 0 || 
                        (
                            branch_busy_in && 
                            branch_tagx_in == `UNLOCKED && 
                            branch_tagy_in == `UNLOCKED
                        )
                    ) ? 0 : 1;

wire `word_t jump, remain;                    
assign jump = pc_in + offset_in;
assign remain = pc_in + 4;

always @(posedge clk) begin
    if (rdy) begin
        if (branch_busy_in && branch_tagx_in == `UNLOCKED && branch_tagy_in == `UNLOCKED) begin
            case (branch_op_in)
                `BEQ : begin                    
                    dest_out <= branch_datax_in == branch_datay_in ? jump : remain;
                    en <= 1;
                end
                `BNE : begin
                    dest_out <= branch_datax_in != branch_datay_in ? jump : remain;
                    en <= 1;
                end
                `BLT : begin
                    dest_out <= $signed(branch_datax_in) < $signed(branch_datay_in) ? jump : remain;
                    en <= 1;
                end
                `BGE : begin
                    dest_out <= $signed(branch_datax_in) >= $signed(branch_datay_in) ? jump : remain;
                    en <= 1;
                end
                `BLTU : begin
                    dest_out <= branch_datax_in < branch_datay_in ? jump : remain;
                    en <= 1;
                end
                `BGEU : begin
                    dest_out <= branch_datax_in >= branch_datay_in ? jump : remain;
                    en <= 1;
                end
                default : begin
                    dest_out <= `ZERO;
                    en <= 0;
                end
            endcase
        end else begin
            dest_out <= `ZERO;
            en <= 0;
        end
    end
end

endmodule //ex_branch