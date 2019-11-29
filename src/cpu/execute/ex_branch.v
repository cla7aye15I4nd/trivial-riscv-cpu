module ex_branch(
    input wire `addr_t pc_in,
    input wire `dword_t offset_in,
    input wire branch_busy_in,
    input wire `sinst_t branch_op_in,
    input wire `regtag_t branch_tagx_in,
    input wire `regtag_t branch_tagy_in,
    input wire `dword_t branch_datax_in,
    input wire `dword_t branch_datay_in,

    // to alloctor
    output wire branch_busy_out,
    output wire `regtag_t branch_tagx_out,
    output wire `regtag_t branch_tagy_out,
    
    // to if
    output reg en,
    output reg `dword_t dest_out,

    input wire clk,
    input wire rdy
);

assign branch_tagx_out  = branch_tagx_in;
assign branch_tagy_out  = branch_tagy_in;
assign branch_busy_out = (
                        branch_busy_in == 0 || 
                        (
                            branch_busy_in && 
                            branch_tagx_in == `UNLOCKED && 
                            branch_tagy_in == `UNLOCKED
                        )
                    ) ? 0 : 1;
                    
assign jump = pc_in + offset_in;
assign remain = pc_in + 4;

always @(posedge clk) begin
    if (rdy) begin
        if (branch_busy_in && branch_tagx_in == `UNLOCKED && branch_tagy_in == `UNLOCKED) begin
            case (branch_op_in)
                `BEQ : begin
                    dest_out = branch_datax_in == branch_datay_in ? jump : remain;
                    en = branch_datax_in == branch_datay_in ? 1: 0;
                end
                `BNE : begin
                    dest_out = branch_datax_in != branch_datay_in ? jump : remain;
                    en = branch_datax_in != branch_datay_in ? 1: 0;
                end
                `BLT : begin
                    dest_out = $signed(branch_datax_in) < $signed(branch_datay_in) ? jump : remain;
                    en = $signed(branch_datax_in) < $signed(branch_datay_in) ? 1: 0;
                end
                `BGE : begin
                    dest_out = $signed(branch_datax_in) >= $signed(branch_datay_in) ? jump : remain;
                    en = $signed(branch_datax_in) >= $signed(branch_datay_in) ? 1: 0;
                end
                `BLTU : begin
                    dest_out = branch_datax_in < branch_datay_in ? jump : remain;
                    en = branch_datax_in < branch_datay_in ? 1: 0;
                end
                `BGEU : begin
                    dest_out = branch_datax_in >= branch_datay_in ? jump : remain;
                    en = branch_datax_in >= branch_datay_in ? 1: 0;
                end
            endcase
        end
    end
end

endmodule //ex_branch