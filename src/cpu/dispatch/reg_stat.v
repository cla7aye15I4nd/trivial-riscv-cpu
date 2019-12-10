module reg_stat(
    input wire `word_t imm0,
    `READ_VAR_DEFINE(en_rx0, addrx0, datax0, tagx0)
    `READ_VAR_DEFINE(en_ry0, addry0, datay0, tagy0)
    // input wire `word_t imm1,
    // `READ_VAR_DEFINE(en_rx1, addrx1, datax1, tagx1)
    // `READ_VAR_DEFINE(en_ry1, addry1, datay1, tagy1)
    
    input en_rw0,
    input wire `regaddr_t addrw0,
    output wire `regtag_t tagw0,

    // input en_rw1,
    // input wire `regaddr_t addrw1,
    // output wire `regtag_t tagw1,

    `WRITE_VAR_DEFINE(en_w0, reg_write_addr0, write_data0)
    `WRITE_VAR_DEFINE(en_w1, reg_write_addr1, write_data1)
    `WRITE_VAR_DEFINE(en_w2, reg_write_addr2, write_data2)

    input wire en_mod0,
    input wire `regtag_t reg_tag0,
    input wire `regaddr_t reg_addr0,
    // `WRITE_TAG_DEFINE(en_mod1, reg_addr1, reg_tag1)

    input wire clk,
    input wire rst,
    input wire rdy
);

integer i;
wire mod0, flag0, flag1, flag2;
reg `word_t data[0 : `REG_COUNT-1];
reg `regtag_t tag[0 : `REG_COUNT-1];

assign {datax0, tagx0} = en_rx0 ? {data[addrx0], tag[addrx0]}: {imm0, `UNLOCKED};
assign {datay0, tagy0} = en_ry0 ? {data[addry0], tag[addry0]}: {imm0, `UNLOCKED};
assign tagw0  = en_rw0 ? tag [addrw0]: `UNLOCKED;

// assign datax1 = en_rx1 ? data[addrx1]: imm1;
// assign datay1 = en_ry1 ? data[addry1]: imm1;
// assign tagx1  = en_rx1 ? tag [addrx1]: `UNLOCKED;
// assign tagy1  = en_ry1 ? tag [addry1]: `UNLOCKED;
// assign tagw1  = en_rw1 ? tag [addrw1]: `UNLOCKED;

assign mod0 = en_mod0 && reg_addr0 > 0;
assign flag0 = en_w0 && reg_write_addr0 > 0 && tag[reg_write_addr0] == `ALU_MASTER && (~en_mod0 || reg_write_addr0 != reg_addr0);
assign flag1 = en_w1 && reg_write_addr1 > 0 && tag[reg_write_addr1] == `ALU_SALVER && (~en_mod0 || reg_write_addr1 != reg_addr0);
assign flag2 = en_w2 && reg_write_addr2 > 0 && tag[reg_write_addr2] == `LOAD_STORE && (~en_mod0 || reg_write_addr2 != reg_addr0);
            
always @(posedge clk) begin
    if (rst || ~rdy) begin
        for (i = 0; i < `REG_COUNT; i = i + 1) begin
            data[i] <= `ZERO;
            tag[i] <= `UNLOCKED;
        end
    end else begin
        if (mod0) tag[reg_addr0] <= reg_tag0;
        
        if (flag0) {data[reg_write_addr0], tag[reg_write_addr0]} <= {write_data0, `UNLOCKED};
        if (flag1) {data[reg_write_addr1], tag[reg_write_addr1]} <= {write_data1, `UNLOCKED};
        if (flag2) {data[reg_write_addr2], tag[reg_write_addr2]} <= {write_data2, `UNLOCKED};

        // {datax0, tagx0} <= en_rx0 ? ((mod0  && reg_addr0 == addrx0)        ? {`ZERO, reg_tag0}:
        //                              (flag0 && reg_write_addr0 == addrx0) ? {write_data0, `UNLOCKED}:
        //                              (flag1 && reg_write_addr1 == addrx0) ? {write_data1, `UNLOCKED}:
        //                              (flag2 && reg_write_addr2 == addrx0) ? {write_data2, `UNLOCKED}:
        //                              {data[addrx0], tag[addrx0]}) : {imm0, `UNLOCKED};

        // {datay0, tagy0} <= en_ry0 ? ((mod0  && reg_addr0 == addry0)       ? {`ZERO, reg_tag0}:
        //                              (flag0 && reg_write_addr0 == addry0) ? {write_data0, `UNLOCKED}:
        //                              (flag1 && reg_write_addr1 == addry0) ? {write_data1, `UNLOCKED}:
        //                              (flag2 && reg_write_addr2 == addry0) ? {write_data2, `UNLOCKED}:
        //                              {data[addry0], tag[addry0]}) : {imm0, `UNLOCKED};
    end
end
 
endmodule // reg_stat