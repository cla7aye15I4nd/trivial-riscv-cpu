`include "common_defs.vh"
`include "cpu/cpu_defs.vh"

`define READ_VAR_DEFINE(_en_r, _reg_read_addr, _data, _lock)\
    input wire _en_r,                                       \
    input wire `regaddr_t _reg_read_addr,                   \
    output reg `word_t _data,                               \
    output reg `regtag_t _lock,

`define WRITE_VAR_DEFINE(_en_w, _reg_write_addr, _write_data)   \
    input wire _en_w,                                           \
    input wire `regaddr_t _reg_write_addr,                      \
    input wire `word_t _write_data,

`define WRITE_TAG_DEFINE(_en_w, _reg_write_addr, _write_data)   \
    input wire _en_w,                                           \
    input wire `regaddr_t _reg_write_addr,                      \
    input wire `regtag_t _write_data,

`define FROM_WRITE(addr) (en_mod0 && reg_addr0 == addr) ? reg_tag0 : (en_mod1 && reg_addr1 == addr) ? reg_tag1

`define REG_OUTPUT(_en_r, _reg_read_addr, _data, _lock) \
if (_en_r) begin                                        \
    _lock = `FROM_WRITE(_reg_read_addr) : lock[_reg_read_addr];                                                        \
    _data = (`FROM_WRITE(_reg_read_addr) : lock[_reg_read_addr]) == `UNLOCKED ? data[_reg_read_addr]: _reg_read_addr;  \ 
end 

`define REG_WRITE(_en_w, _reg_write_addr, _data)    \
if (_en_w) begin                                    \
    lock[_reg_write_addr] <= `UNLOCKED;             \
    data[_reg_write_addr] <= _data;                 \
end

`define REG_TAG_WRITE(_en_w, _addr, _tag)   \
if (_en_w) begin                            \
    lock[_addr] <= _tag;                    \
end

module reg_stat(
    input wire `word_t imm0, imm1,
    `READ_VAR_DEFINE(en_rx0, reg_read_addrx0, read_datax0, lockx0)
    `READ_VAR_DEFINE(en_ry0, reg_read_addry0, read_datay0, locky0)
    `READ_VAR_DEFINE(en_rx1, reg_read_addrx1, read_datax1, lockx1)
    `READ_VAR_DEFINE(en_ry1, reg_read_addry1, read_datay1, locky1)
    
    input en_rw0,
    input wire `regaddr_t addrw0,
    output reg `regtag_t lockw0,

    input en_rw1,
    input wire `regaddr_t addrw1,
    output reg `regtag_t lockw1,

    // From Execute and L/S
    // Update Data (no conflict)
    `WRITE_VAR_DEFINE(en_w0, reg_write_addr0, write_data0)
    `WRITE_VAR_DEFINE(en_w1, reg_write_addr1, write_data1)
    `WRITE_VAR_DEFINE(en_w2, reg_write_addr2, write_data2)

    // From allocator
    // Update Tag (no conflict)
    `WRITE_TAG_DEFINE(en_mod0, reg_addr0, reg_tag0)
    `WRITE_TAG_DEFINE(en_mod1, reg_addr1, reg_tag1)

    input wire clk,
    input wire rst,
    input wire rdy
);

reg `word_t data[0 : `REG_COUNT-1];
reg `regtag_t lock[0 : `REG_COUNT-1];
integer i;

always @(*) begin
    if(rst == 0 && rdy) begin
        `REG_OUTPUT(en_rx0, reg_read_addrx0, read_datax0, lockx0) else {read_datax0, lockx0} = {imm0, `UNLOCKED};
        `REG_OUTPUT(en_ry0, reg_read_addry0, read_datay0, locky0) else {read_datay0, locky0} = {`ZERO_WORD, `UNLOCKED};
        `REG_OUTPUT(en_rx1, reg_read_addrx1, read_datax1, lockx1) else {read_datax1, lockx1} = {imm1, `UNLOCKED};
        `REG_OUTPUT(en_ry1, reg_read_addry1, read_datay1, locky1) else {read_datay1, locky1} = {`ZERO_WORD, `UNLOCKED};

        if (en_rw0) begin
            lockw0 = `FROM_WRITE(addrw0) : lock[addrw0];
        end
        if (en_rw1) begin
            lockw1 = `FROM_WRITE(addrw1) : lock[addrw1];
        end
    end
end

always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < `REG_COUNT; i = i + 1) begin
            data[i] <= `ZERO_WORD;
            lock[i] <= `UNLOCKED;
        end
    end else begin
        `REG_TAG_WRITE(en_mod0, reg_addr0, reg_tag0)
        `REG_TAG_WRITE(en_mod1, reg_addr1, reg_tag1)
    end
end

always @(negedge clk) begin
    if (rdy && rst == 0) begin
        `REG_WRITE(en_w0, reg_write_addr0, write_data0)
        `REG_WRITE(en_w1, reg_write_addr1, write_data1)
        `REG_WRITE(en_w2, reg_write_addr2, write_data2)
    end
end
 
endmodule // reg_stat