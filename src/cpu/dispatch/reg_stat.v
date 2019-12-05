module reg_stat(
    input wire `word_t imm0, imm1,
    `READ_VAR_DEFINE(en_rx0, addrx0, datax0, tagx0)
    `READ_VAR_DEFINE(en_ry0, addry0, datay0, tagy0)
    `READ_VAR_DEFINE(en_rx1, addrx1, datax1, tagx1)
    `READ_VAR_DEFINE(en_ry1, addry1, datay1, tagy1)
    
    input en_rw0,
    input wire `regaddr_t addrw0,
    output wire `regtag_t tagw0,

    input en_rw1,
    input wire `regaddr_t addrw1,
    output wire `regtag_t tagw1,

    `WRITE_VAR_DEFINE(en_w0, reg_write_addr0, write_data0)
    `WRITE_VAR_DEFINE(en_w1, reg_write_addr1, write_data1)
    `WRITE_VAR_DEFINE(en_w2, reg_write_addr2, write_data2)

    `WRITE_TAG_DEFINE(en_mod0, reg_addr0, reg_tag0)
    // `WRITE_TAG_DEFINE(en_mod1, reg_addr1, reg_tag1)
    // `WRITE_TAG_DEFINE(en_mod2, reg_addr2, reg_tag2)

    input wire clk,
    input wire rst,
    input wire rdy
);

integer i;
reg `word_t data[0 : `REG_COUNT-1];
reg `regtag_t tag[0 : `REG_COUNT-1];

wire `regtag_t tagdebug;
assign tagdebug = tag[14];

assign datax0 = en_rx0 ? data[addrx0]: imm0;
assign datay0 = en_ry0 ? data[addry0]: imm0;
assign tagx0  = en_rx0 ? tag [addrx0]: `UNLOCKED;
assign tagy0  = en_ry0 ? tag [addry0]: `UNLOCKED;
assign tagw0  = en_rw0 ? tag [addrw0]: `UNLOCKED;

assign datax1 = en_rx1 ? data[addrx1]: imm1;
assign datay1 = en_ry1 ? data[addry1]: imm1;
assign tagx1  = en_rx1 ? tag [addrx1]: `UNLOCKED;
assign tagy1  = en_ry1 ? tag [addry1]: `UNLOCKED;
assign tagw1  = en_rw1 ? tag [addrw1]: `UNLOCKED;

always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < `REG_COUNT; i = i + 1) begin
            data[i] <= `ZERO;
            tag[i] <= `UNLOCKED;
        end
    end else if(rdy) begin
        if (en_mod0 && reg_addr0 > 0) tag[reg_addr0] <= reg_tag0;
        // if (en_mod1 && reg_addr1 > 0) tag[reg_addr1] <= reg_tag1;
        
        if (en_w0 && reg_write_addr0 > 0
            && (~en_mod0 || reg_write_addr0 != reg_addr0)
            //&& (~en_mod1 || reg_write_addr0 != reg_addr1)
            ) begin
            {data[reg_write_addr0], tag[reg_write_addr0]} <= {write_data0, `UNLOCKED};
        end

        if (en_w1 && reg_write_addr1 > 0
            && (~en_mod0 || reg_write_addr1 != reg_addr0)
            //&& (~en_mod1 || reg_write_addr1 != reg_addr1)
            ) begin
            {data[reg_write_addr1], tag[reg_write_addr1]} <= {write_data1, `UNLOCKED};
        end

        if (en_w2 && reg_write_addr2 > 0
            && (~en_mod0 || reg_write_addr2 != reg_addr0)
            //&& (~en_mod1 || reg_write_addr2 != reg_addr1)
            ) begin
            {data[reg_write_addr2], tag[reg_write_addr2]} <= {write_data2, `UNLOCKED};
        end
    end
end
 
endmodule // reg_stat