module reg_stat(
    input wire `word_t imm0,
    `READ_VAR_DEFINE(en_rx0, addrx0, datax0, tagx0)
    `READ_VAR_DEFINE(en_ry0, addry0, datay0, tagy0)
    
    input en_rw0,
    input wire `regaddr_t addrw0,
    output wire `regtag_t tagw0,

    `WRITE_VAR_DEFINE(en_w0, reg_write_addr0, write_data0)
    `WRITE_VAR_DEFINE(en_w1, reg_write_addr1, write_data1)
    `WRITE_VAR_DEFINE(en_wM, reg_write_addrM, write_dataM)

    input wire en_mod0,
    input wire `regtag_t reg_tag0,
    input wire `regaddr_t reg_addr0,

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

assign mod0 = en_mod0 && reg_addr0;
assign flag0 = en_w0 && reg_write_addr0 && tag[reg_write_addr0] == `ALU_MASTER && (~en_mod0 || reg_write_addr0 != reg_addr0);
assign flag1 = en_w1 && reg_write_addr1 && tag[reg_write_addr1] == `ALU_SALVER && (~en_mod0 || reg_write_addr1 != reg_addr0);
assign flagM = en_wM && reg_write_addrM && tag[reg_write_addrM] == `LOAD_STORE && (~en_mod0 || reg_write_addrM != reg_addr0);
            
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
        if (flagM) {data[reg_write_addrM], tag[reg_write_addrM]} <= {write_dataM, `UNLOCKED};
    end
end
 
endmodule // reg_stat