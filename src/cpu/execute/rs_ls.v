module rs_ls(
    // Allocator
    input wire en,
    input wire `sinst_t op,
    input wire `regtag_t tagx,
    input wire `regtag_t tagy,
    input wire `regtag_t tagw,
    input wire `word_t datax,
    input wire `word_t datay,
    input wire `addr_t addrw,

    // Update signal from alu execuator
    input wire busy_alu0,
    input wire `regtag_t alu_tag0,
    input wire `word_t alu_data0,

    input wire busy_alu1,
    input wire `regtag_t alu_tag1,
    input wire `word_t alu_data1,

    input wire busy_ls,
    input wire `regtag_t ls_tag,
    input wire `word_t ls_data,

    // To ls module
    output wire ls_busy_out,
    output wire `sinst_t ls_op_out,
    output wire `regtag_t ls_tagx_out,
    output wire `regtag_t ls_tagy_out,
    output wire `regtag_t ls_tagw_out,
    output wire `word_t ls_datax_out,
    output wire `word_t ls_datay_out,
    output wire `regaddr_t ls_target_out,

    input wire clk,
    input wire rdy,
    input wire rst
);

reg busy;
reg `sinst_t op_ls;
reg `regaddr_t target;
reg `regtag_t tag_rx, tag_ry, tag_w;
reg `word_t data_rx, data_ry;

assign ls_busy_out = busy;
assign ls_op_out = op_ls;
assign ls_tagx_out = tag_rx;
assign ls_tagy_out = tag_ry;
assign ls_tagw_out = tag_w;
assign ls_datax_out = data_rx;
assign ls_datay_out = data_ry;
assign ls_target_out = target;

always @(posedge clk) begin
    if (rst) begin
        {busy, op_ls, target, data_rx, data_ry} = 0;
        {tag_rx, tag_ry, tag_w} = {`UNLOCKED, `UNLOCKED, `UNLOCKED};
    end
end

`define UPDATE_PAIR(_tag, _data, tag, data) {_tag, _data} <= (busy_alu0 == 0 && tag == alu_tag0) ? {`UNLOCKED, alu_data0} : (busy_alu1 == 0 && tag == alu_tag1) ? {`UNLOCKED, alu_data1} : (busy_ls == 0 && tag == ls_tag) ? {`UNLOCKED, ls_data} : {tag, data};
`define UPDATE_VAR(_tag, tag) _tag <= (busy_alu0 == 0 && tag == alu_tag0) ? `UNLOCKED : (busy_alu1 == 0 && tag == alu_tag1) ? `UNLOCKED : (busy_ls == 0 && tag == ls_tag) ? `UNLOCKED : tag;

always @(negedge clk) begin
    if (rst == 0 && rdy) begin
        /* Input instruction exist, update by input or origin value */
        if (en) begin
            busy <= 1;
            op_ls <= op;
            `UPDATE_PAIR(tag_rx, data_rx, tagx, datax)
            `UPDATE_PAIR(tag_ry, data_ry, tagy, datay)
            `UPDATE_VAR(tag_w, tagw)
            target <= addrw;
        end else if (busy) begin
            busy <= busy_ls;
            `UPDATE_PAIR(tag_rx, data_rx, tag_rx, data_rx)
            `UPDATE_PAIR(tag_ry, data_ry, tag_ry, data_ry)
            `UPDATE_VAR(tag_w, tag_w)
        end
    end
end

endmodule //rs_ls