module allocator(
    input wire branch_mode,

    // Waiting alloc
    input wire `oper_t op0_in,
    input wire `addr_t pc0_in,
    input wire `word_t imm0_in, datax0_in, datay0_in, 
    input wire `regtag_t tagx0_in, tagy0_in, tagw0_in,
    input wire `regaddr_t addrx0_in, addry0_in, addrw0_in,

    input wire `oper_t op1_in,
    input wire `addr_t pc1_in,
    input wire `word_t imm1_in, datax1_in, datay1_in, 
    input wire `regtag_t tagx1_in, tagy1_in, tagw1_in,
    input wire `regaddr_t addrx1_in, addry1_in, addrw1_in,
    
    // current alu state
    input wire alu0_busy_in,
    input wire `regtag_t alu0_tagx_in,
    input wire `regtag_t alu0_tagy_in,
    input wire `regtag_t alu0_tagw_in,

    input wire alu1_busy_in,
    input wire `regtag_t alu1_tagx_in,
    input wire `regtag_t alu1_tagy_in,
    input wire `regtag_t alu1_tagw_in,

    input wire ls_busy_in,
    input wire `regtag_t ls_tagx_in,
    input wire `regtag_t ls_tagy_in,
    input wire `regtag_t ls_tagw_in,

    input wire branch_busy_in,
    input wire `regtag_t branch_tagx_in,
    input wire `regtag_t branch_tagy_in,

    // issue
    output reg alu0_en_out,
    output reg `addr_t alu0_pc_out,
    output reg `sinst_t alu0_op_out,
    output reg `regtag_t alu0_tagx_out,
    output reg `regtag_t alu0_tagy_out,
    output reg `regtag_t alu0_tagw_out,
    output reg `word_t alu0_datax_out,
    output reg `word_t alu0_datay_out,
    output reg `regaddr_t alu0_addrx_out,
    output reg `regaddr_t alu0_addry_out,
    output reg `regaddr_t alu0_addrw_out,

    output reg alu1_en_out,
    output reg `addr_t alu1_pc_out,
    output reg `sinst_t alu1_op_out,
    output reg `regtag_t alu1_tagx_out,
    output reg `regtag_t alu1_tagy_out,
    output reg `regtag_t alu1_tagw_out,
    output reg `word_t alu1_datax_out,
    output reg `word_t alu1_datay_out,
    output reg `regaddr_t alu1_addrx_out,
    output reg `regaddr_t alu1_addry_out,
    output reg `regaddr_t alu1_addrw_out,

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

    output reg en_mod0, 
    output reg `regaddr_t reg_addr0,
    output reg `regtag_t reg_tag0,

    output reg en_mod1, 
    output reg `regaddr_t reg_addr1,
    output reg `regtag_t reg_tag1,

    output reg issue0, issue1,
    input wire clk,
    input wire rst,
    input wire rdy
);

reg `oper_t op0;
reg `addr_t pc0;
reg en_rx0, en_ry0, en_w0;
reg `word_t imm0, datax0, datay0;
reg `regtag_t tagx0, tagy0, tagw0;
reg `regaddr_t addrx0, addry0, addrw0;

reg `oper_t op1;
reg `addr_t pc1;
reg en_rx1, en_ry1, en_w1;
reg `word_t imm1, datax1, datay1;
reg `regtag_t tagx1, tagy1, tagw1;
reg `regaddr_t addrx1, addry1, addrw1;

`define SET_STATUE(w, x, y, z) \
    alu0_en_out = w;           \
    alu1_en_out = x;           \
    ls_en_out   = y;           \
    branch_en_out = z;

always @(negedge clk) begin
    if (rst) begin
        issue0 <= 1;
        issue1 <= 1;
        op0    <= `OP_NOP;
        op1    <= `OP_NOP;
    end else begin
        if (issue0) begin
            op0 <= op0_in;
            pc0 <= pc0_in;
            imm0 <= imm0_in;
            
            {datax0, tagx0} <= (en_mw0 && reg_write_addr0 == addrx0_in) ? {write_data0, `UNLOCKED}:
                               (en_mw1 && reg_write_addr1 == addrx0_in) ? {write_data1, `UNLOCKED}: 
                               (en_mw2 && reg_write_addr2 == addrx0_in) ? {write_data2, `UNLOCKED}: 
                                                                          {datax0_in, tagx0_in};
            
            {datay0, tagy0} <= (en_mw0 && reg_write_addr0 == addry0_in) ? {write_data0, `UNLOCKED}:
                               (en_mw1 && reg_write_addr1 == addry0_in) ? {write_data1, `UNLOCKED}: 
                               (en_mw2 && reg_write_addr2 == addry0_in) ? {write_data2, `UNLOCKED}: 
                                                                          {datay0_in, tagy0_in};
            
            tagw0 <= (en_mw0 && reg_write_addr0 == addrw0_in) ? `UNLOCKED:
                     (en_mw1 && reg_write_addr1 == addrw0_in) ? `UNLOCKED: 
                     (en_mw2 && reg_write_addr2 == addrw0_in) ? `UNLOCKED: 
                                                                tagw0_in;

            {addrx0, addry0, addrw0} <= {addrx0_in, addry0_in, addrw0_in};

            // if (issue1) begin 
            //     op1 <= op1_in;
            //     pc1 <= pc1_in;
            //     {imm1, datax1, datay1} <= {imm1_in, datax1_in, datay1_in};
            //     {tagx1, tagy1, tagw1} <= {tagx1_in, tagy1_in, tagw1_in};
            //     {addrx1, addry1, addrw1} <= {addrx1_in, addry1_in, addrw1_in};
            // end
        end
    end
end

always @(*) begin
    en_mod1 = 0;
    reg_addr1 = 0;
    reg_tag1 = `UNLOCKED;
    case (op0[7 : 4])
    4'b0001, 4'b0010, 4'b0101, 4'b1101: begin
        if (alu0_busy_in == 0 || {alu0_busy_in, alu0_tagx_in, alu0_tagy_in, alu0_tagw_in} == {1'b1, {3{`UNLOCKED}}}) begin
            issue0          = 1;
            alu0_op_out     = op0[3 : 0];
            // alu0_tagx_out   = tagx0;
            // alu0_datax_out  = datax0;
            {alu0_datax_out, alu0_tagx_out} = (en_mw0 && reg_write_addr0 == addrx0) ? {write_data0, `UNLOCKED}:
                                              (en_mw1 && reg_write_addr1 == addrx0) ? {write_data1, `UNLOCKED}: 
                                              (en_mw2 && reg_write_addr2 == addrx0) ? {write_data2, `UNLOCKED}: 
                                                                                      {datax0, tagx0};     
            {alu0_datay_out, alu0_tagy_out} = (en_mw0 && reg_write_addr0 == addry0) ? {write_data0, `UNLOCKED}:
                                              (en_mw1 && reg_write_addr1 == addry0) ? {write_data1, `UNLOCKED}: 
                                              (en_mw2 && reg_write_addr2 == addry0) ? {write_data2, `UNLOCKED}: 
                                                                                      {datay0, tagy0};              
            alu0_tagw_out   = (en_mw0 && reg_write_addr0 == addrw0) ? `UNLOCKED:
                              (en_mw1 && reg_write_addr1 == addrw0) ? `UNLOCKED: 
                              (en_mw2 && reg_write_addr2 == addrw0) ? `UNLOCKED: 
                                                                        tagw0;
            alu0_addrx_out  = addrx0;
            alu0_addry_out  = addry0;
            alu0_addrw_out  = addrw0;
            alu0_pc_out     = pc0;
            en_mod0 = 1;
            reg_addr0 = addrw0;
            reg_tag0 = `ALU_MASTER;
            `SET_STATUE(1, 0, 0, 0);
        end else if (alu1_busy_in == 0 || {alu1_busy_in, alu1_tagx_in, alu1_tagy_in, alu1_tagw_in} == {1'b1, {3{`UNLOCKED}}}) begin
            issue1          = 1;
            alu1_op_out     = op0[3 : 0];
            {alu1_datax_out, alu1_tagx_out} = (en_mw0 && reg_write_addr0 == addrx1) ? {write_data0, `UNLOCKED}:
                                              (en_mw1 && reg_write_addr1 == addrx1) ? {write_data1, `UNLOCKED}: 
                                              (en_mw2 && reg_write_addr2 == addrx1) ? {write_data2, `UNLOCKED}: 
                                                                                      {datax1, tagx1};     
            {alu1_datay_out, alu1_tagy_out} = (en_mw0 && reg_write_addr0 == addry1) ? {write_data0, `UNLOCKED}:
                                              (en_mw1 && reg_write_addr1 == addry1) ? {write_data1, `UNLOCKED}: 
                                              (en_mw2 && reg_write_addr2 == addry1) ? {write_data2, `UNLOCKED}: 
                                                                                      {datay1, tagy1};              
            alu1_tagw_out   = (en_mw0 && reg_write_addr0 == addrw1) ? `UNLOCKED:
                              (en_mw1 && reg_write_addr1 == addrw1) ? `UNLOCKED: 
                              (en_mw2 && reg_write_addr2 == addrw1) ? `UNLOCKED: 
                                                                        tagw1; 
            alu1_addrw_out  = addrw0;
            alu1_pc_out     = pc0_in;
            `SET_STATUE(0, 1, 0, 0);
        end else begin
            `SET_STATUE(0, 0, 0, 0);
            issue0 = 0;
            en_mod0 = 0;
            reg_addr0 = 0;
            reg_tag0 = `UNLOCKED;
        end
    end
    4'b0011, 4'b1001: begin
        if (ls_busy_in == 0) begin
            issue0        = 1;
            ls_op_out     = op0[3 : 0];
            ls_offset_out = imm0;
            {ls_datax_out, ls_tagx_out} = (en_mw0 && reg_write_addr0 == addrx0) ? {write_data0, `UNLOCKED}:
                                          (en_mw1 && reg_write_addr1 == addrx0) ? {write_data1, `UNLOCKED}: 
                                          (en_mw2 && reg_write_addr2 == addrx0) ? {write_data2, `UNLOCKED}: 
                                                                                  {datax0, tagx0}; 
            {ls_datay_out, ls_tagy_out} = (en_mw0 && reg_write_addr0 == addry0) ? {write_data0, `UNLOCKED}:
                                          (en_mw1 && reg_write_addr1 == addry0) ? {write_data1, `UNLOCKED}: 
                                          (en_mw2 && reg_write_addr2 == addry0) ? {write_data2, `UNLOCKED}: 
                                                                                  {datay0, tagy0}; 
            ls_tagw_out   = op0[7 : 4] == 4'b1001 ? (
                                            (en_mw0 && reg_write_addr0 == addrw0) ? `UNLOCKED:
                                            (en_mw1 && reg_write_addr1 == addrw0) ? `UNLOCKED: 
                                            (en_mw2 && reg_write_addr2 == addrw0) ? `UNLOCKED: 
                                                                                    tagw0
                                        ) : `UNLOCKED;
            ls_addrw_out  = addrw0;
            en_mod0 = 1;
            reg_addr0 = addrw0;
            reg_tag0 = `LOAD_STORE;
            `SET_STATUE(0, 0, 1, 0);
        end else begin
            `SET_STATUE(0, 0, 0, 0);
            issue0 = 0;
            en_mod0 = 0;
            reg_addr0 = 0;
            reg_tag0 = `UNLOCKED;
        end
    end
    4'b0100: begin 
        en_mod0 = 0;
        reg_addr0 = 0;
        reg_tag0 = `UNLOCKED;
        if (branch_busy_in == 0 || {branch_busy_in, branch_tagx_in, branch_tagy_in} == {1'b1, {2{`UNLOCKED}}}) begin
            issue0              = 1;
            branch_op_out       = op0[3 : 0];
            branch_pc_out       = pc0;
            branch_offset_out   = imm0;
            branch_tagx_out     = tagx0;
            branch_datax_out    = datax0;
            branch_tagy_out     = tagy0;
            branch_datay_out    = datay0;
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
        reg_addr0 = 0;
        reg_tag0 = `UNLOCKED;
    end
    endcase
end
endmodule // allocator