module rs_ls(
    // Allocator
    input wire en,
    input wire `sinst_t op,
    input wire `word_t imm,
    input wire `regtag_t tagx,
    input wire `regtag_t tagy,
    input wire `regtag_t tagw,
    input wire `word_t datax,
    input wire `word_t datay,
    input wire `regaddr_t addrw,

    // Update signal from alu execuator
    input wire en_alu0,
    input wire busy_alu0,
    input wire `word_t alu_data0,

    input wire en_alu1,
    input wire busy_alu1,
    input wire `word_t alu_data1,

    input wire en_ls,
    input wire busy_ls,
    input wire `word_t ls_data,

    output reg ls_next_busy,

    // To ls module
    output wire ls_busy_out,
    output wire `word_t ls_offset_out,
    output wire `sinst_t ls_op_out,
    output wire `regtag_t ls_tagx_out,
    output wire `regtag_t ls_tagy_out,
    output wire `regtag_t ls_tagw_out,
    output wire `word_t ls_datax_out,
    output wire `word_t ls_datay_out,
    output wire `regaddr_t ls_target_out,

    // output reg enw2,
    // output reg `regaddr_t regaddr2,
    // output reg `regtag_t  regtag2,

    input wire clk,
    input wire rdy,
    input wire rst
);

reg busy;
reg `sinst_t op_ls;
reg `regaddr_t target;
reg `regtag_t tag_rx, tag_ry, tag_w;
reg `word_t data_rx, data_ry, offset_ls;

assign ls_busy_out = busy;
assign ls_offset_out = offset_ls;
assign ls_op_out = op_ls;
assign ls_tagx_out = tag_rx;
assign ls_tagy_out = tag_ry;
assign ls_tagw_out = tag_w;
assign ls_datax_out = data_rx;
assign ls_datay_out = data_ry;
assign ls_target_out = target;

always @(posedge clk) begin
    if (en) begin
        ls_next_busy <= 1;
    end else begin
        ls_next_busy <= busy;
    end
end

always @(negedge clk) begin
    if (rst) begin
        {busy, op_ls, target, data_rx, data_ry} = 0;
        {tag_rx, tag_ry, tag_w} = {`UNLOCKED, `UNLOCKED, `UNLOCKED};
    end else if (rdy) begin
        /* Input instruction exist, update by input or origin value */
        if (en) begin
            busy <= 1;
            op_ls <= op;
            offset_ls <= imm;
            `UPDATE_PAIR(tag_rx, data_rx, tagx, datax)
            `UPDATE_PAIR(tag_ry, data_ry, tagy, datay)
            `UPDATE_VAR(tag_w, tagw)
            target <= addrw;
        end else begin
            busy <= busy_ls;
            `UPDATE_PAIR(tag_rx, data_rx, tag_rx, data_rx)
            `UPDATE_PAIR(tag_ry, data_ry, tag_ry, data_ry)
            `UPDATE_VAR(tag_w, tag_w)
        end
    end
end

endmodule //rs_ls