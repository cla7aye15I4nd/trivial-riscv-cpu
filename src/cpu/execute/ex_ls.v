module ex_ls(
    input wire `dword_t offset_in,
    input wire ls_busy_in,
    input wire `sinst_t ls_op_in,
    input wire `regtag_t ls_tagx_in,
    input wire `regtag_t ls_tagy_in,
    input wire `regtag_t ls_tagw_in,
    input wire `dword_t ls_datax_in,
    input wire `dword_t ls_datay_in,
    input wire `regaddr_t ls_target_in,

    // to alloctor
    output reg ls_busy_out,
    output wire `regtag_t ls_tagx_out,
    output wire `regtag_t ls_tagy_out,
    output wire `regtag_t ls_tagw_out,
    
    // to regfile
    output reg en,
    output wire `regaddr_t target_out,
    output reg `dword_t data_out,

    // to cache
    output reg en_ls,
    output reg r_nw_out,
    output reg `addr_t ls_addr,
    output reg `byte_t ls_size,
    output reg `dword_t ls_data_out,

    // from cache
    input wire finish,
    input wire `word_t ls_data_in,

    input wire clk
);

assign ls_tagx_out  = ls_tagx_in;
assign ls_tagy_out  = ls_tagy_in;
assign ls_tagw_out  = ls_tagw_in;
assign target_out = ls_target_in;

// memory control
always @(posedge clk) begin
    if (ls_busy_in && ls_tagx_in == `UNLOCKED && ls_tagy_in == `UNLOCKED && ls_tagw_in == `UNLOCKED) begin
        case (ls_op_in)
            `LB: begin
                if (finish) begin
                    data_out <= $signed(ls_data_in[7 : 0]);
                    ls_busy_out <= 0;
                    en <= 1;
                    en_ls <= 0;
                end else begin
                    en_ls <= 1;
                    r_nw_out <= `READ_SIGNAL;
                    ls_addr <= ls_datax_in + ls_datay_in;
                    ls_size <= 1;
                    ls_busy_out <= 1;
                    en <= 0;
                end
            end
            `LH: begin
                if (finish) begin
                    data_out <= $signed(ls_data_in[15 : 0]);
                    ls_busy_out <= 0;
                    en <= 1;
                    en_ls <= 0;
                end else begin
                    en_ls <= 1;
                    r_nw_out <= `READ_SIGNAL;
                    ls_addr <= ls_datax_in + ls_datay_in;
                    ls_size <= 2;
                    ls_busy_out <= 1;
                    en <= 0;
                end
            end
            `LW: begin
                if (finish) begin
                    data_out <= $signed(ls_data_in);
                    ls_busy_out <= 0;
                    en <= 1;
                    en_ls <= 0;
                end else begin
                    en_ls <= 1;
                    r_nw_out <= `READ_SIGNAL;
                    ls_addr <= ls_datax_in + ls_datay_in;
                    ls_size <= 4;
                    ls_busy_out <= 1;
                    en <= 0;
                end
            end
            `LBU: begin
                if (finish) begin
                    data_out <= $unsigned(ls_data_in[7 : 0]);
                    ls_busy_out <= 0;
                    en <= 1;
                    en_ls <= 0;
                end else begin
                    en_ls <= 1;
                    r_nw_out <= `READ_SIGNAL;
                    ls_addr <= ls_datax_in + ls_datay_in;
                    ls_size <= 1;
                    ls_busy_out <= 1;
                    en <= 0;
                end
            end
            `LHU: begin
                if (finish) begin
                    data_out <= $signed(ls_data_in[15 : 0]);
                    ls_busy_out <= 0;
                    en <= 1;
                    en_ls <= 0;
                end else begin
                    en_ls <= 1;
                    r_nw_out <= `READ_SIGNAL;
                    ls_addr <= ls_datax_in + ls_datay_in;
                    ls_size <= 2;
                    ls_busy_out <= 1;
                    en <= 0;
                end
            end
            `SB: begin
                if (finish) begin
                    ls_busy_out <= 0;
                    en <= 1;
                    en_ls <= 0;
                end else begin
                    en_ls <= 1;
                    r_nw_out <= `WRITE_SIGNAL;
                    ls_addr <= ls_datax_in + offset_in;
                    ls_data_out <= ls_datay_in;
                    ls_size <= 1;
                    ls_busy_out <= 1;
                    en <= 0;
                end
            end
            `SH: begin
                if (finish) begin
                    ls_busy_out <= 0;
                    en <= 1;
                    en_ls <= 0;
                end else begin
                    en_ls <= 1;
                    r_nw_out <= `WRITE_SIGNAL;
                    ls_addr <= ls_datax_in + offset_in;
                    ls_data_out <= ls_datay_in;
                    ls_size <= 2;
                    ls_busy_out <= 1;
                    en <= 0;
                end
            end
            `SW: begin
                if (finish) begin
                    ls_busy_out <= 0;
                    en <= 1;
                    en_ls <= 0;
                end else begin
                    en_ls <= 1;
                    r_nw_out <= `WRITE_SIGNAL;
                    ls_addr <= ls_datax_in + offset_in;
                    ls_data_out <= ls_datay_in;
                    ls_size <= 4;
                    ls_busy_out <= 1;
                    en <= 0;
                end
            end
        endcase
    end else begin
        ls_busy_out <= 0;
        en <= 0;
        en_ls <= 0;
    end
end

endmodule //ex_ls