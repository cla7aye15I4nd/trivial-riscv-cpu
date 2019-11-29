module rs_branch(
    // Allocator
    input `addr_t pc,
    input wire en,
    input wire `sinst_t op,
    input wire `dword_t imm,
    input wire `regtag_t tagx,
    input wire `regtag_t tagy,
    input wire `dword_t datax,
    input wire `dword_t datay,

    // Update signal from alu execuator
    input wire busy_alu0,
    input wire `dword_t alu_data0,

    input wire busy_alu1,
    input wire `dword_t alu_data1,

    input wire busy_ls,
    input wire `dword_t ls_data,

    // To branch module
    output reg `addr_t pc_out,
    output reg `dword_t branch_offset_out,
    output wire branch_busy_out,
    output wire `sinst_t branch_op_out,
    output wire `regtag_t branch_tagx_out,
    output wire `regtag_t branch_tagy_out,
    output wire `dword_t branch_datax_out,
    output wire `dword_t branch_datay_out,

    input wire clk,
    input wire rdy,
    input wire rst
);

reg busy;
reg `dword_t offset;
reg `sinst_t op_branch;
reg `regaddr_t target;
reg `regtag_t tag_rx, tag_ry, tag_w;
reg `dword_t data_rx, data_ry;

assign branch_busy_out = busy;
assign branch_op_out = op_branch;
assign branch_tagx_out = tag_rx;
assign branch_tagy_out = tag_ry;
assign branch_datax_out = data_rx;
assign branch_datay_out = data_ry;

always @(posedge clk) begin
    pc_out <= en ? pc: pc_out;
end

always @(negedge clk) begin
    if (rst) begin
        {busy, op_branch, data_rx, data_ry} = 0;
        {tag_rx, tag_ry} = {`UNLOCKED, `UNLOCKED, `UNLOCKED};
    end else if (rdy) begin
        /* Input instruction exist, update by input or origin value */
        if (en) begin
            busy <= 1;
            op_branch <= op;
            offset <= imm;
            `UPDATE_PAIR(tag_rx, data_rx, tagx, datax)
            `UPDATE_PAIR(tag_ry, data_ry, tagy, datay)
        end else if (busy) begin
            busy <= busy_ls;
            `UPDATE_PAIR(tag_rx, data_rx, tag_rx, data_rx)
            `UPDATE_PAIR(tag_ry, data_ry, tag_ry, data_ry)
        end
    end
end

endmodule //rs_branch