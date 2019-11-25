module ex_ls(
    input wire ls_busy_in,
    input wire `sinst_t ls_op_in,
    input wire `regtag_t ls_tagx_in,
    input wire `regtag_t ls_tagy_in,
    input wire `regtag_t ls_tagw_in,
    input wire `word_t ls_datax_in,
    input wire `word_t ls_datay_in,
    input wire `regaddr_t ls_target_in,

    // to alloctor
    output wire ls_busy_out,
    output wire `regtag_t ls_tagx_out,
    output wire `regtag_t ls_tagy_out,
    output wire `regtag_t ls_tagw_out,
    
    // to regfile
    output wire en,
    output wire `regaddr_t target_out,
    output reg `word_t data_out,

    input wire clk
);

assign ls_tagx_out  = ls_tagx_in;
assign ls_tagy_out  = ls_tagy_in;
assign ls_tagw_out  = ls_tagw_in;
assign target_out = ls_target_in;
assign ls_busy_out = (
                        ls_busy_in == 0 || 
                        (
                            ls_busy_in && 
                            ls_tagx_in == `UNLOCKED && 
                            ls_tagy_in == `UNLOCKED && 
                            ls_tagw_in == `UNLOCKED &&
                            ls_op_in[3] == 0
                        )
                    ) ? 0 : 1;
assign en = (
                ls_busy_in && 
                ls_tagx_in == `UNLOCKED && 
                ls_tagy_in == `UNLOCKED && 
                ls_tagw_in == `UNLOCKED &&
                ls_op_in[3] == 0
            ) ? 1 : 0;

always @(posedge clk) begin
    
end

endmodule //ex_ls