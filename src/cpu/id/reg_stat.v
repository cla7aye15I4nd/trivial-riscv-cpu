`include "../../common_defs.vh"
`include "../cpu_defs.vh"

`define READ_VAR_DEFINE(_en_r, _reg_read_addr, _data, _lock)\
    input wire _en_r,                                       \
    input wire `regaddr_t _reg_read_addr,                   \
    output reg `word_t _data,                               \
    output reg `regtag_t _lock,

`define WRITE_VAR_DEFINE(_en_w, _reg_write_addr, _write_data)   \
    input wire _en_w,                                           \
    input wire `regaddr_t _reg_write_addr,                      \
    input wire `word_t _write_data,

`define REG_OUTPUT(_en_r, _reg_read_addr, _data, _lock) \
if (_en_r) begin                                        \
    _lock <= lock[_reg_read_addr];                      \
    _data <= lock[_reg_read_addr] == UNLOCKED ? data[_reg_read_addr]: _reg_read_addr;   \ 
end

`define REG_WRITE(_en_w, _reg_write_addr, _data)    \
if (_en_w) begin                                    \
    data[_reg_write_addr] <= _data;                 \
end

module reg_stat(
    `READ_VAR_DEFINE(en_r0, reg_read_addr0, read_data0, lock0)
    `READ_VAR_DEFINE(en_r1, reg_read_addr1, read_data1, lock1)
    `READ_VAR_DEFINE(en_r2, reg_read_addr2, read_data2, lock2)
    `READ_VAR_DEFINE(en_r3, reg_read_addr3, read_data3, lock3)
    
    `WRITE_VAR_DEFINE(en_w0, reg_write_addr0, write_data0)
    `WRITE_VAR_DEFINE(en_w1, reg_write_addr1, write_data1)
    // `WRITE_VAR_DEFINE(en_w2, reg_write_addr2, write_data2)
    // `WRITE_VAR_DEFINE(en_w3, reg_write_addr3, write_data3)

    input wire clk,
    input wire rst
);

reg `word_t data[0 : `REG_COUNT-1];
reg `regtag_t lock[0 : `REG_COUNT-1];
integer i;

always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < `REG_COUNT; i = i + 1) begin
            data[i] <= `ZERO_WORD;
            lock[i] <= `UNLOCKED;
        end
    end else begin
        `REG_OUTPUT(en_r0, reg_read_addr0, read_data0, lock0)
        `REG_OUTPUT(en_r1, reg_read_addr1, read_data1, lock1)
        `REG_OUTPUT(en_r2, reg_read_addr2, read_data2, lock2)
        `REG_OUTPUT(en_r3, reg_read_addr3, read_data3, lock3)

        `REG_WRITE(en_w0, reg_write_addr0, write_data0)
        `REG_WRITE(en_w1, reg_write_addr1, write_data1)
        `REG_WRITE(en_w2, reg_write_addr2, write_data2)
        `REG_WRITE(en_w3, reg_write_addr3, write_data3)
    end
end
 
endmodule // reg_stat