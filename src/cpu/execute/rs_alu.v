module rs_alu(
    // Allocator Input
    input wire `addr_t pc0,
    input wire en0,
    input wire `sinst_t op0,
    input wire `regtag_t tagx0,
    input wire `regtag_t tagy0,
    input wire `regtag_t tagw0,
    input wire `dword_t datax0,
    input wire `dword_t datay0,
    input wire `addr_t addrw0,

    input wire `addr_t pc1,
    input wire en1,
    input wire `sinst_t op1,
    input wire `regtag_t tagx1,
    input wire `regtag_t tagy1,
    input wire `regtag_t tagw1,
    input wire `dword_t datax1,
    input wire `dword_t datay1,
    input wire `addr_t addrw1,

    // Update signal from alu execuator
    input wire busy_alu0,
    input wire `dword_t alu_data0,

    input wire busy_alu1,
    input wire `dword_t alu_data1,

    input wire busy_ls,
    input wire `dword_t ls_data,

    // Output to alu execuator
    output reg `addr_t pc0_out,
    output wire alu_busy0_out,
    output wire `sinst_t alu_op0_out,
    output wire `regtag_t alu_tagx0_out,
    output wire `regtag_t alu_tagy0_out,
    output wire `regtag_t alu_tagw0_out,
    output wire `dword_t alu_datax0_out,
    output wire `dword_t alu_datay0_out,
    output wire `regaddr_t alu_target0_out,

    output reg `addr_t pc1_out,
    output wire alu_busy1_out,
    output wire `sinst_t alu_op1_out,
    output wire `regtag_t alu_tagx1_out,
    output wire `regtag_t alu_tagy1_out,
    output wire `regtag_t alu_tagw1_out,
    output wire `dword_t alu_datax1_out,
    output wire `dword_t alu_datay1_out,
    output wire `regaddr_t alu_target1_out,

    input wire clk,
    input wire rdy,
    input wire rst
);

reg busy[0 : `ALU_CNT - 1];
reg `sinst_t op[0 : `ALU_CNT - 1];
reg `regtag_t tag_rx[0 : `ALU_CNT - 1];
reg `regtag_t tag_ry[0 : `ALU_CNT - 1];
reg `regtag_t tag_w[0 : `ALU_CNT - 1];
reg `dword_t data_rx[0 : `ALU_CNT - 1];
reg `dword_t data_ry[0 : `ALU_CNT - 1];
reg `regaddr_t target[0 : `ALU_CNT - 1];

assign alu_busy0_out = busy[0];
assign alu_op0_out = op[0];
assign alu_tagx0_out = tag_rx[0];
assign alu_tagy0_out = tag_ry[0];
assign alu_tagw0_out = tag_w[0];
assign alu_datax0_out = data_rx[0];
assign alu_datay0_out = data_ry[0];
assign alu_target0_out = target[0];

assign alu_busy1_out = busy[1];
assign alu_op1_out = op[1];
assign alu_tagx1_out = tag_rx[1];
assign alu_tagy1_out = tag_ry[1];
assign alu_tagw1_out = tag_w[1];
assign alu_datax1_out = data_rx[1];
assign alu_datay1_out = data_ry[1];
assign alu_target1_out = target[1];

integer i;
always @(posedge clk) begin
    pc0_out <= en0 ? pc0: pc0_out;
    pc1_out <= en1 ? pc1: pc1_out;
end

always @(negedge clk) begin
    if (rst) begin
        for (i = 0; i < `ALU_CNT; i = i + 1) begin
            {busy[i], op[i], data_rx[i], data_ry[i], target[i]} <= 0;
            {tag_rx[i], tag_ry[i], tag_w[i]} = {`UNLOCKED, `UNLOCKED, `UNLOCKED};
        end
    end else if (rst == 0 && rdy) begin
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
            `UPDATE_PAIR(tag_rx[0], data_rx[0], tag_rx[0], data_rx[0])
            `UPDATE_PAIR(tag_ry[0], data_ry[0], tag_ry[0], data_ry[0])
            `UPDATE_VAR(tag_w[0], tag_w[0])
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
            `UPDATE_PAIR(tag_rx[1], data_rx[1], tag_rx[1], data_rx[1])
            `UPDATE_PAIR(tag_ry[1], data_ry[1], tag_ry[1], data_ry[1])
            `UPDATE_VAR(tag_w[1], tag_w[1])
        end
    end
end

endmodule // rs_alu