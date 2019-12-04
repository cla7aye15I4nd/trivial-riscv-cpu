module rs_branch(
    // Allocator
    input `addr_t pc,
    input wire en,
    input wire `sinst_t op,
    input wire `word_t imm,
    input wire `regtag_t tagx,
    input wire `regtag_t tagy,
    input wire `word_t datax,
    input wire `word_t datay,

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

    input wire busy_branch,
    output reg branch_next_busy,

    // To branch module
    output wire `addr_t pc_out,
    output wire `word_t branch_offset_out,
    output wire branch_busy_out,
    output wire `sinst_t branch_op_out,
    output wire `regtag_t branch_tagx_out,
    output wire `regtag_t branch_tagy_out,
    output wire `word_t branch_datax_out,
    output wire `word_t branch_datay_out,

    input wire clk,
    input wire rdy,
    input wire rst
);

reg busy;
reg `addr_t pc_s;
reg `word_t offset;
reg `sinst_t op_branch;
reg `regaddr_t target;
reg `regtag_t tag_rx, tag_ry, tag_w;
reg `word_t data_rx, data_ry;

assign pc_out = pc_s;
assign branch_offset_out = offset;
assign branch_busy_out = busy;
assign branch_op_out = op_branch;
assign branch_tagx_out = tag_rx;
assign branch_tagy_out = tag_ry;
assign branch_datax_out = data_rx;
assign branch_datay_out = data_ry;

always @(posedge clk) begin
    if (en) begin
        branch_next_busy <= 1;
    end else if (busy) begin
        branch_next_busy <= {tag_rx, tag_ry, tag_w} == {3{`UNLOCKED}} ? 0: 1;
    end else begin
        branch_next_busy <= 0;
    end
end

always @(negedge clk) begin
    if (rst) begin
        pc_s <= `ZERO;
        {busy, op_branch, offset, data_rx, data_ry} <= 0;
        {tag_rx, tag_ry} <= {`UNLOCKED, `UNLOCKED, `UNLOCKED};
    end else if (rdy) begin
        /* Input instruction exist, update by input or origin value */
        if (en) begin
            busy <= 1;
            pc_s <= pc;
            op_branch <= op;
            offset <= imm;
            `UPDATE_PAIR(tag_rx, data_rx, tagx, datax)
            `UPDATE_PAIR(tag_ry, data_ry, tagy, datay)
        end else begin
            busy <= busy_branch;
            `UPDATE_PAIR(tag_rx, data_rx, tag_rx, data_rx)
            `UPDATE_PAIR(tag_ry, data_ry, tag_ry, data_ry)
        end
    end
end

endmodule //rs_branch