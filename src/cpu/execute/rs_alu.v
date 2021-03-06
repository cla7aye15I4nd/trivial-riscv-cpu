module rs_alu(
    // Allocator Input
    input wire en0,
    input wire `addr_t pc0,
    input wire `sinst_t op0,
    input wire `regtag_t tagx0,
    input wire `regtag_t tagy0,
    input wire `regtag_t tagw0,
    input wire `word_t datax0,
    input wire `word_t datay0,
    input wire `regaddr_t addrw0,

    input wire en1,
    input wire `addr_t pc1,
    input wire `sinst_t op1,
    input wire `regtag_t tagx1,
    input wire `regtag_t tagy1,
    input wire `regtag_t tagw1,
    input wire `word_t datax1,
    input wire `word_t datay1,
    input wire `regaddr_t addrw1,

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
    
    output reg alu0_next_busy,
    output reg alu1_next_busy,

    // Output to alu execuator
    output wire `addr_t alu_pc0_out,
    output wire alu_busy0_out,
    output wire `sinst_t alu_op0_out,
    output wire `regtag_t alu_tagx0_out,
    output wire `regtag_t alu_tagy0_out,
    output wire `regtag_t alu_tagw0_out,
    output wire `word_t alu_datax0_out,
    output wire `word_t alu_datay0_out,
    output wire `regaddr_t alu_target0_out,

    output wire `addr_t alu_pc1_out,
    output wire alu_busy1_out,
    output wire `sinst_t alu_op1_out,
    output wire `regtag_t alu_tagx1_out,
    output wire `regtag_t alu_tagy1_out,
    output wire `regtag_t alu_tagw1_out,
    output wire `word_t alu_datax1_out,
    output wire `word_t alu_datay1_out,
    output wire `regaddr_t alu_target1_out,

    input wire clk,
    input wire rdy,
    input wire rst
);

reg busy[0 : `ALU_CNT - 1];
reg `addr_t pc[0 : `ALU_CNT - 1];
reg `sinst_t op[0 : `ALU_CNT - 1];
reg `regtag_t tag_rx[0 : `ALU_CNT - 1];
reg `regtag_t tag_ry[0 : `ALU_CNT - 1];
reg `regtag_t tag_w[0 : `ALU_CNT - 1];
reg `word_t data_rx[0 : `ALU_CNT - 1];
reg `word_t data_ry[0 : `ALU_CNT - 1];
reg `regaddr_t target[0 : `ALU_CNT - 1];

assign alu_busy0_out = busy[0];
assign alu_op0_out = op[0];
assign alu_pc0_out = pc[0];
assign alu_tagx0_out = tag_rx[0];
assign alu_tagy0_out = tag_ry[0];
assign alu_tagw0_out = tag_w[0];
assign alu_datax0_out = data_rx[0];
assign alu_datay0_out = data_ry[0];
assign alu_target0_out = target[0];

assign alu_busy1_out = busy[1];
assign alu_op1_out = op[1];
assign alu_pc1_out = pc[1];
assign alu_tagx1_out = tag_rx[1];
assign alu_tagy1_out = tag_ry[1];
assign alu_tagw1_out = tag_w[1];
assign alu_datax1_out = data_rx[1];
assign alu_datay1_out = data_ry[1];
assign alu_target1_out = target[1];

reg en0_s, en1_s;
reg `sinst_t op0_s, op1_s;
reg `addr_t pc0_s, pc1_s;
reg `regaddr_t addrw0_s, addrw1_s;
reg `regtag_t tagx0_s, tagy0_s, tagx1_s, tagy1_s, tagw0_s, tagw1_s;
reg `word_t datax0_s, datay0_s, datax1_s, datay1_s;

always @(posedge clk) begin
    {en0_s, en1_s} <= {en0, en1};
    {datax0_s, datay0_s, datax1_s, datay1_s} <= {datax0, datay0, datax1, datay1};
    {op0_s, op1_s, pc0_s, pc1_s, addrw0_s, addrw1_s} <= {op0, op1, pc0, pc1, addrw0, addrw1};
    {tagx0_s, tagy0_s, tagx1_s, tagy1_s, tagw0_s, tagw1_s} <= {tagx0, tagy0, tagx1, tagy1, tagw0, tagw1};
    if (en0) begin
        alu0_next_busy <=1;
    end else begin
        alu0_next_busy <= {tag_rx[0], tag_ry[0], tag_w[0]} == {3{`UNLOCKED}} ? 0: busy[0];
    end 

    if (en1) begin
        alu1_next_busy <= 1;
    end else begin
        alu1_next_busy <= {tag_rx[1], tag_ry[1], tag_w[1]} == {3{`UNLOCKED}} ? 0: busy[1];
    end 
end

always @(negedge clk) begin
    if (rst) begin
        {busy[0], pc[0], op[0], data_rx[0], data_ry[0], target[0]} <= 0;
        {busy[1], pc[1], op[1], data_rx[1], data_ry[1], target[1]} <= 0;
        {tag_rx[0], tag_ry[0], tag_w[0]} <= {3{`UNLOCKED}};
        {tag_rx[1], tag_ry[1], tag_w[1]} <= {3{`UNLOCKED}};
    end else /*if (rdy)*/ begin
        /* Input instruction exist, update by input or origin value */
        if (en0_s) begin
            busy[0] <= 1;
            op[0] <= op0_s;
            pc[0] <= pc0_s;
            `UPDATE_PAIR(tag_rx[0], data_rx[0], tagx0_s, datax0_s)
            `UPDATE_PAIR(tag_ry[0], data_ry[0], tagy0_s, datay0_s)
            `UPDATE_VAR(tag_w[0], tagw0_s)
            target[0] <= addrw0_s;
        end else begin
            busy[0] <= busy_alu0;
            `UPDATE_PAIR(tag_rx[0], data_rx[0], tag_rx[0], data_rx[0])
            `UPDATE_PAIR(tag_ry[0], data_ry[0], tag_ry[0], data_ry[0])
            `UPDATE_VAR(tag_w[0], tag_w[0])
        end

        if (en1_s) begin
            busy[1] <= 1;
            op[1] <= op1_s;
            pc[1] <= pc1_s;
            `UPDATE_PAIR(tag_rx[1], data_rx[1], tagx1_s, datax1_s)
            `UPDATE_PAIR(tag_ry[1], data_ry[1], tagy1_s, datay1_s)
            `UPDATE_VAR(tag_w[1], tagw1_s)
            target[1] <= addrw1_s;
        end else begin
            busy[1] <= busy_alu1;
            `UPDATE_PAIR(tag_rx[1], data_rx[1], tag_rx[1], data_rx[1])
            `UPDATE_PAIR(tag_ry[1], data_ry[1], tag_ry[1], data_ry[1])
            `UPDATE_VAR(tag_w[1], tag_w[1])
        end
    end
end

endmodule // rs_alu