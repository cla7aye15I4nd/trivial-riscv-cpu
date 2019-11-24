module rs_alu(
    // Allocator Input
    input wire `addr_t pc0,
    input wire en0,
    input wire `sinst_t op0,
    input wire `regtag_t tagx0,
    input wire `regtag_t tagy0,
    input wire `regtag_t tagw0,
    input wire `word_t datax0,
    input wire `word_t datay0,
    input wire `addr_t addrw0,

    input wire `addr_t pc1,
    input wire en1,
    input wire `sinst_t op1,
    input wire `regtag_t tagx1,
    input wire `regtag_t tagy1,
    input wire `regtag_t tagw1,
    input wire `word_t datax1,
    input wire `word_t datay1,
    input wire `addr_t addrw1,

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

    // Output to alu execuator
    output wire pc0_out,
    output reg alu_busy0_out,
    output reg `sinst_t alu_op0_out,
    output reg `regtag_t alu_tagx0_out,
    output reg `regtag_t alu_tagy0_out,
    output reg `regtag_t alu_tagw0_out,
    output reg `word_t alu_datax0_out,
    output reg `word_t alu_datay0_out,
    output reg `regaddr_t alu_target0_out,

    output wire pc1_out,
    output reg alu_busy1_out,
    output reg `sinst_t alu_op1_out,
    output reg `regtag_t alu_tagx1_out,
    output reg `regtag_t alu_tagy1_out,
    output reg `regtag_t alu_tagw1_out,
    output reg `word_t alu_datax1_out,
    output reg `word_t alu_datay1_out,
    output reg `regaddr_t alu_target1_out,

    input wire clk,
    input wire rdy,
    input wire rst
);

assign pc0_out = pc0;
assign pc1_out = pc1;

reg busy[0 : `ALU_CNT - 1];
reg `sinst_t op[0 : `ALU_CNT - 1];
reg `regtag_t tag_rx[0 : `ALU_CNT - 1];
reg `regtag_t tag_ry[0 : `ALU_CNT - 1];
reg `regtag_t tag_w[0 : `ALU_CNT - 1];
reg `word_t data_rx[0 : `ALU_CNT - 1];
reg `word_t data_ry[0 : `ALU_CNT - 1];
reg `regaddr_t target[0 : `ALU_CNT - 1];

integer i;
always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < `ALU_CNT; i = i + 1) begin
            {busy[i], op[i], data_rx[i], data_ry[i], target[i]} <= 0;
            {tag_rx[i], tag_ry[i], tag_w[i]} = {`UNLOCKED, `UNLOCKED, `UNLOCKED};
        end
    end else if(rdy) begin
        alu_busy0_out <= busy[0];
        alu_op0_out <= op[0];
        alu_tagx0_out <= tag_rx[0];
        alu_tagy0_out <= tag_ry[0];
        alu_tagw0_out <= tag_w[0];
        alu_datax0_out <= data_rx[0];
        alu_datay0_out <= data_ry[0];
        alu_target0_out <= target[0];

        alu_busy1_out <= busy[1];
        alu_op1_out <= op[1];
        alu_tagx1_out <= tag_rx[1];
        alu_tagy1_out <= tag_ry[1];
        alu_tagw1_out <= tag_w[1];
        alu_datax1_out <= data_rx[1];
        alu_datay1_out <= data_ry[1];
        alu_target1_out <= target[1];
    end
end

`define UPDATE_PAIR(_tag, _data, tag, data) {_tag, _data} <= (busy_alu0 == 0 && tag == alu_tag0) ? {`UNLOCKED, alu_data0} : (busy_alu1 == 0 && tag == alu_tag1) ? {`UNLOCKED, alu_data1} : {tag, data};
`define UPDATE_VAR(_tag, tag) _tag <= (busy_alu0 == 0 && tag == alu_tag0) ? `UNLOCKED : (busy_alu1 == 0 && tag == alu_tag1) ? `UNLOCKED : tag;
// `define UPDATE_PAIR(_tag, _data, tag, data) {_tag, _data} <= (busy_alu0 == 0 && tag == alu_tag0) ? {`UNLOCKED, alu_data0} : (busy_alu1 == 0 && tag == alu_tag1) ? {`UNLOCKED, alu_data1} : (busy_ls == 0 && tag == ls_tag) ? {`UNLOCKED, ls_data} : {tag, data};
// `define UPDATE_VAR(_tag, tag) _tag <= (busy_alu0 == 0 && tag == alu_tag0) ? `UNLOCKED : (busy_alu1 == 0 && tag == alu_tag1) ? `UNLOCKED : (busy_ls == 0 && tag == ls_tag) ? `UNLOCKED : tag;
always @(negedge clk) begin
    if (rst == 0 && rdy) begin
        /* Input instruction exist, update by input or origin value */
        if (en0) begin
            busy[0] <= 1;
            op[0] <= op0;
            `UPDATE_PAIR(tag_rx[0], data_rx[0], tagx0, datax0)
            `UPDATE_PAIR(tag_ry[0], data_ry[0], tagy0, datay0)
            `UPDATE_VAR(tag_w[0], tagw0)
            target[0] <= addrw0;
        end else if (busy[0]) begin
            busy[0] <= busy_alu0;
            op[0] <= op0;
            `UPDATE_PAIR(tag_rx[0], data_rx[0], tag_rx[0], data_rx[0])
            `UPDATE_PAIR(tag_ry[0], data_ry[0], tag_ry[0], data_ry[0])
            `UPDATE_VAR(tag_w[0], tag_w[0])
            target[0] <= addrw0;
        end

        if (en1) begin
            busy[1] <= 1;
            op[1] <= op1;
            `UPDATE_PAIR(tag_rx[1], data_rx[1], tagx1, datax1)
            `UPDATE_PAIR(tag_ry[1], data_ry[1], tagy1, datay1)
            `UPDATE_VAR(tag_w[1], tagw1)
            target[1] <= addrw1;
        end else if (busy[1]) begin
            busy[1] <= busy_alu1;
            op[1] <= op1;
            `UPDATE_PAIR(tag_rx[1], data_rx[1], tag_rx[1], data_rx[1])
            `UPDATE_PAIR(tag_ry[1], data_ry[1], tag_ry[1], data_ry[1])
            `UPDATE_VAR(tag_w[1], tag_w[1])
            target[1] <= addrw1;
        end
    end
end

endmodule // rs_alu