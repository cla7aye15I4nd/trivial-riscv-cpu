module ex_ls(
    input wire `word_t offset_in,
    input wire ls_busy_in,
    input wire `sinst_t ls_op_in,
    input wire `regtag_t ls_tagx_in,
    input wire `regtag_t ls_tagy_in,
    input wire `regtag_t ls_tagw_in,
    input wire `word_t ls_datax_in,
    input wire `word_t ls_datay_in,
    input wire `regaddr_t ls_target_in,

    // to alloctor
    output reg ls_busy_out,
    output wire `regtag_t ls_tagx_out,
    output wire `regtag_t ls_tagy_out,
    output wire `regtag_t ls_tagw_out,
    
    // to regfile
    output reg en,
    output reg `regaddr_t target_out,
    output reg `word_t data_out,

    // to cache
    output reg en_ls,
    output reg         ls_oper,
    output reg `addr_t ls_addr,
    output reg `byte_t ls_size,
    output reg `word_t ls_data,
    
    // from cache
    input wire in_fifo_in, finish,
    input wire `word_t ls_data_in,

    input wire clk,
    input wire rst,
    input wire rdy
);

assign ls_tagx_out  = ls_tagx_in;
assign ls_tagy_out  = ls_tagy_in;
assign ls_tagw_out  = ls_tagw_in;

reg in_fifo;

// memory control
always @(posedge clk) begin
    if (rst) begin
        in_fifo <= 0;
        ls_busy_out <= 0;
    end else if(rdy) begin
        if (ls_busy_in && ls_tagx_in == `UNLOCKED && ls_tagy_in == `UNLOCKED && ls_tagw_in == `UNLOCKED) begin
            target_out <= ls_target_in;
            case (ls_op_in)
                `LB: begin
                    if (finish && in_fifo) begin
                        data_out    <= $signed(ls_data_in[7 : 0]);
                        ls_busy_out <= 0;
                        ls_addr     <= `NULL_PTR;
                        en <= 1;
                        en_ls <= 0;
                        in_fifo <= 0;
                    end else begin
                        en <= 0;
                        ls_busy_out <= 1;
                        ls_oper <= `READ_SIGNAL;
                        ls_addr <= ls_datax_in + ls_datay_in;
                        ls_size <= 1;
                        if (in_fifo_in || in_fifo) begin
                            en_ls <= 0;
                            in_fifo <= 1;
                        end else begin 
                            en_ls <= 1;
                            in_fifo <= 0;          
                        end
                    end
                end
                `LH: begin
                    if (finish && in_fifo) begin
                        data_out    <= $signed({ls_data_in[7 : 0], ls_data_in[15 : 8]});
                        ls_busy_out <= 0;
                        ls_addr     <= `NULL_PTR;
                        en <= 1;
                        en_ls <= 0;
                        in_fifo <= 0;
                    end else begin
                        en <= 0;
                        ls_busy_out <= 1;
                        ls_oper <= `READ_SIGNAL;
                        ls_addr <= ls_datax_in + ls_datay_in;
                        ls_size <= 2;
                        if (in_fifo_in || in_fifo) begin
                            en_ls <= 0;
                            in_fifo <= 1;
                        end else begin 
                            en_ls <= 1;
                            in_fifo <= 0;          
                        end
                    end
                end
                `LW: begin
                    if (finish && in_fifo) begin
                        data_out    <= {ls_data_in[7 : 0], ls_data_in[15 : 8], ls_data_in[23 : 16], ls_data_in[31 : 24]};
                        //$write("## %x\n", {ls_data_in[7 : 0], ls_data_in[15 : 8], ls_data_in[24 : 16], ls_data_in[31 : 24]});
                        ls_busy_out <= 0;
                        ls_addr     <= `NULL_PTR;
                        en <= 1;
                        en_ls <= 0;
                        in_fifo <= 0;
                    end else begin
                        en <= 0;
                        ls_busy_out <= 1;
                        ls_oper <= `READ_SIGNAL;
                        ls_addr <= ls_datax_in + ls_datay_in;
                        ls_size <= 4;
                        if (in_fifo_in || in_fifo) begin
                            en_ls <= 0;
                            in_fifo <= 1;
                        end else begin 
                            en_ls <= 1;
                            in_fifo <= 0;          
                        end
                    end
                end
                `LBU: begin
                    if (finish && in_fifo) begin
                        //$write("LBU: %x %x addr:%x data:%x\n", ls_datax_in, ls_datay_in, ls_datax_in + ls_datay_in, $unsigned(ls_data_in[7 : 0]));
                        data_out    <= $unsigned(ls_data_in[7 : 0]);
                        ls_busy_out <= 0;
                        ls_addr     <= `NULL_PTR;
                        en <= 1;
                        en_ls <= 0;
                        in_fifo <= 0;
                    end else begin
                        en <= 0;
                        ls_busy_out <= 1;
                        ls_oper <= `READ_SIGNAL;
                        ls_addr <= ls_datax_in + ls_datay_in;
                        ls_size <= 1;
                        if (in_fifo_in || in_fifo) begin
                            en_ls <= 0;
                            in_fifo <= 1;
                        end else begin 
                            en_ls <= 1;
                            in_fifo <= 0;          
                        end
                    end
                end
                `LHU: begin
                    if (finish && in_fifo) begin
                        data_out    <= $unsigned({ls_data_in[7 : 0], ls_data_in[15 : 8]});
                        ls_busy_out <= 0;
                        ls_addr     <= `NULL_PTR;
                        en          <= 1;
                        en_ls       <= 0;
                        in_fifo     <= 0;
                    end else begin
                        en          <= 0;
                        ls_busy_out <= 1;
                        ls_oper     <= `READ_SIGNAL;
                        ls_addr     <= ls_datax_in + ls_datay_in;
                        ls_size     <= 1;
                        if (in_fifo_in || in_fifo) begin
                            en_ls   <= 0;
                            in_fifo <= 1;
                        end else begin 
                            en_ls   <= 1;
                            in_fifo <= 0;          
                        end
                    end
                end
                `SB: begin
                    if (in_fifo_in) begin
                        data_out    <= 0;
                        ls_busy_out <= 0;
                        en          <= 0;
                        en_ls       <= 0;
                        // $write("SB: %x %x %x addr:%x data:%x\n", ls_datax_in, ls_datay_in, offset_in, ls_datax_in + offset_in, ls_datay_in);
                    end else begin
                        en <= 0;
                        en_ls   <= 1;
                        ls_oper <= `WRITE_SIGNAL;
                        ls_addr <= ls_datax_in + offset_in;
                        ls_size <= 1;
                        ls_data <= ls_datay_in;
                        ls_busy_out <= 1;
                    end
                end
                `SH: begin
                    if (in_fifo_in) begin
                        data_out    <= 0;
                        ls_busy_out <= 0;
                        en          <= 0;
                        en_ls       <= 0;
                    end else begin
                        en <= 0;
                        en_ls   <= 1;
                        ls_oper <= `WRITE_SIGNAL;
                        ls_addr <= ls_datax_in + offset_in;
                        ls_size <= 2;
                        ls_data <= ls_datay_in;
                        ls_busy_out <= 1;
                    end
                end
                `SW: begin
                    if (in_fifo_in) begin
                        data_out    <= 0;
                        ls_busy_out <= 0;
                        en          <= 0;
                        en_ls       <= 0;
                    end else begin
                        en <= 0;
                        en_ls   <= 1;
                        ls_oper <= `WRITE_SIGNAL;
                        ls_addr <= ls_datax_in + offset_in;
                        ls_size <= 4;
                        ls_data <= ls_datay_in;
                        ls_busy_out <= 1;
                    end
                end
                default: begin
                    data_out    <= 0;
                    target_out <= `ZERO;
                    ls_busy_out <= 0;
                    in_fifo <= 0;
                    en  <= 0;
                    en_ls <= 0;
                end
            endcase
        end else begin
            data_out    <= 0;
            target_out <= `ZERO;
            ls_busy_out <= ls_busy_in;
            in_fifo <= 0;
            en  <= 0;
            en_ls <= 0;
        end 
    end
end

endmodule //ex_ls