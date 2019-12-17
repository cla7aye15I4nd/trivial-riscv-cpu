module allocator(
    // Waiting alloc
    input wire `oper_t op0_in,
    input wire `addr_t pc0_in,
    input wire `word_t imm0_in, datax0_in, datay0_in, 
    input wire `regtag_t tagx0_in, tagy0_in, tagw0_in,
    input wire `regaddr_t addrw0_in,

    // input wire `oper_t op1_in,
    // input wire `addr_t pc1_in,
    // input wire `word_t imm1_in, datax1_in, datay1_in, 
    // input wire `regtag_t tagx1_in, tagy1_in, tagw1_in,
    // input wire `regaddr_t addrw1_in,
    
    // current alu state
    input wire alu0_busy_in,
    input wire alu1_busy_in,
    input wire alu2_busy_in,
    input wire ls_busy_in,
    input wire branch_busy_in,

    // issue
    output reg alu0_en_out,
    output reg `addr_t alu0_pc_out,
    output reg `sinst_t alu0_op_out,
    output reg `regtag_t alu0_tagx_out,
    output reg `regtag_t alu0_tagy_out,
    output reg `regtag_t alu0_tagw_out,
    output reg `word_t alu0_datax_out,
    output reg `word_t alu0_datay_out,
    output reg `regaddr_t alu0_addrw_out,

    output reg alu1_en_out,
    output reg `addr_t alu1_pc_out,
    output reg `sinst_t alu1_op_out,
    output reg `regtag_t alu1_tagx_out,
    output reg `regtag_t alu1_tagy_out,
    output reg `regtag_t alu1_tagw_out,
    output reg `word_t alu1_datax_out,
    output reg `word_t alu1_datay_out,
    output reg `regaddr_t alu1_addrw_out,

    output reg alu2_en_out,
    output reg `addr_t alu2_pc_out,
    output reg `sinst_t alu2_op_out,
    output reg `regtag_t alu2_tagx_out,
    output reg `regtag_t alu2_tagy_out,
    output reg `regtag_t alu2_tagw_out,
    output reg `word_t alu2_datax_out,
    output reg `word_t alu2_datay_out,
    output reg `regaddr_t alu2_addrw_out,

    output reg ls_en_out,
    output reg `sinst_t ls_op_out,
    output reg `word_t ls_offset_out,
    output reg `regtag_t ls_tagx_out,
    output reg `regtag_t ls_tagy_out,
    output reg `regtag_t ls_tagw_out,
    output reg `word_t ls_datax_out,
    output reg `word_t ls_datay_out,
    output reg `regaddr_t ls_addrw_out,

    output reg branch_en_out,
    output reg `addr_t branch_pc_out,
    output reg `word_t branch_offset_out,
    output reg `sinst_t branch_op_out,
    output reg `regtag_t branch_tagx_out,
    output reg `regtag_t branch_tagy_out,
    output reg `word_t branch_datax_out,
    output reg `word_t branch_datay_out,

    `WRITE_VAR_DEFINE(en_mw0, reg_write_addr0, write_data0)
    `WRITE_VAR_DEFINE(en_mw1, reg_write_addr1, write_data1)
    `WRITE_VAR_DEFINE(en_mw2, reg_write_addr2, write_data2)
    `WRITE_VAR_DEFINE(en_mw3, reg_write_addr3, write_data3)

    output reg en_mod0, 
    output reg `regaddr_t reg_addr0,
    output reg `regtag_t reg_tag0,

    // output reg en_mod1, 
    // output reg `regaddr_t reg_addr1,
    // output reg `regtag_t reg_tag1,

    output reg issue0,
    input wire clk,
    input wire rst
);

`define SET_STATUE(a, b, c, d, e)   \
    alu0_en_out = a;                \
    alu1_en_out = b;                \
    alu2_en_out = c;                \
    ls_en_out   = d;                \
    branch_en_out = e;

wire `word_t new_datax, new_datay;
wire `regtag_t new_tagx, new_tagy, new_tagw;
assign {new_datax, new_tagx} = (en_mw0 && tagx0_in == `ALU_MASTER) ? {write_data0, `UNLOCKED}:
                               (en_mw1 && tagx0_in == `ALU_SALVER) ? {write_data1, `UNLOCKED}: 
                               (en_mw2 && tagx0_in == `LOAD_STORE) ? {write_data2, `UNLOCKED}: 
                               (en_mw3 && tagx0_in == `ALU_MISAKA) ? {write_data3, `UNLOCKED}: 
                                                                     {datax0_in, tagx0_in};
assign {new_datay, new_tagy} = (en_mw0 && tagy0_in == `ALU_MASTER) ? {write_data0, `UNLOCKED}:
                               (en_mw1 && tagy0_in == `ALU_SALVER) ? {write_data1, `UNLOCKED}: 
                               (en_mw2 && tagy0_in == `LOAD_STORE) ? {write_data2, `UNLOCKED}: 
                               (en_mw3 && tagy0_in == `ALU_MISAKA) ? {write_data3, `UNLOCKED}: 
                                                                     {datay0_in, tagy0_in};                                                            
assign new_tagw = (en_mw0 && tagw0_in == `ALU_MASTER) ? `UNLOCKED:
                  (en_mw1 && tagw0_in == `ALU_SALVER) ? `UNLOCKED: 
                  (en_mw2 && tagw0_in == `LOAD_STORE) ? `UNLOCKED: 
                  (en_mw3 && tagw0_in == `ALU_MISAKA) ? `UNLOCKED: 
                                                        tagw0_in;

always @(*) begin
    alu0_op_out     = op0_in[3 : 0];
    {alu0_datax_out, alu0_tagx_out} = {new_datax, new_tagx};  
    {alu0_datay_out, alu0_tagy_out} = {new_datay, new_tagy};           
    alu0_tagw_out   = new_tagw;
    alu0_addrw_out  = addrw0_in;
    alu0_pc_out     = pc0_in;

    alu1_op_out     = op0_in[3 : 0];
    {alu1_datax_out, alu1_tagx_out} = {new_datax, new_tagx};
    {alu1_datay_out, alu1_tagy_out} = {new_datay, new_tagy};           
    alu1_tagw_out  = new_tagw;
    alu1_addrw_out  = addrw0_in;
    alu1_pc_out     = pc0_in;

    alu2_op_out     = op0_in[3 : 0];
    {alu2_datax_out, alu2_tagx_out} = {new_datax, new_tagx};
    {alu2_datay_out, alu2_tagy_out} = {new_datay, new_tagy};           
    alu2_tagw_out  = new_tagw;
    alu2_addrw_out  = addrw0_in;
    alu2_pc_out     = pc0_in;

    ls_op_out     = op0_in[3 : 0];
    ls_offset_out = imm0_in;
    {ls_datax_out, ls_tagx_out} = {new_datax, new_tagx};
    {ls_datay_out, ls_tagy_out} = {new_datay, new_tagy};
    ls_tagw_out   = op0_in[7 : 4] == 4'b1001 ? new_tagw: `UNLOCKED;
    ls_addrw_out  = addrw0_in;
    
    branch_op_out       = op0_in[3 : 0];
    branch_pc_out       = pc0_in;
    branch_offset_out   = imm0_in;
    {branch_datax_out, branch_tagx_out} = {new_datax, new_tagx};
    {branch_datay_out, branch_tagy_out} = {new_datay, new_tagy};

    reg_addr0 = addrw0_in;

    case (op0_in[7 : 4])
    4'b0001, 4'b0010, 4'b0101, 4'b1101: begin
        if (alu0_busy_in == 0) begin
            issue0          = 1;
            en_mod0 = 1;
            reg_tag0 = `ALU_MASTER;
            `SET_STATUE(1, 0, 0, 0);
        end else if (alu1_busy_in == 0) begin
            issue0          = 1;
            en_mod0 = 1;
            reg_tag0 = `ALU_SALVER;
            `SET_STATUE(0, 1, 0, 0);
        end else if (alu2_busy_in == 0) begin
            issue0          = 1;
            en_mod0 = 1;
            reg_tag0 = `ALU_MISAKA;
            `SET_STATUE(0, 1, 0, 0);
        end else begin
            `SET_STATUE(0, 0, 0, 0);
            reg_tag0 = 0;
            issue0 = 0;
            en_mod0 = 0;
        end
    end
    4'b0011, 4'b1001: begin
        reg_tag0 = `LOAD_STORE;
        if (ls_busy_in == 0) begin
            issue0        = 1;
            en_mod0 = 1;
            `SET_STATUE(0, 0, 1, 0);
        end else begin
            `SET_STATUE(0, 0, 0, 0);
            issue0 = 0;
            en_mod0 = 0;
        end
    end
    4'b0100: begin 
        reg_tag0 = `BRANCH_SEL;
        en_mod0 = 0;
        if (branch_busy_in == 0) begin
            issue0 = 1;
            `SET_STATUE(0, 0, 0, 1);
        end else begin
            `SET_STATUE(0, 0, 0, 0);
            issue0 = 0;
        end
    end
    default: begin
        `SET_STATUE(0, 0, 0, 0);
        issue0 = 1;
        en_mod0 = 0;
        reg_tag0 = 0;
    end
    endcase
end
endmodule // allocator