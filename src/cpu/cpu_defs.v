`ifndef CPU_DEFS_H
`define CPU_DEFS_H

/* I-type Instructions (0001) */
`define I_TYPE      7'b0010011
`define OP_ADDI     8'b0001_0000
`define OP_SLTI     8'b0001_0010
`define OP_SLTIU    8'b0001_0100
`define OP_XORI     8'b0001_0110
`define OP_ORI      8'b0001_1000
`define OP_ANDI     8'b0001_1010
`define OP_SLLI     8'b0001_1100
`define OP_SRLI     8'b0001_1110 
`define OP_SRAI     8'b0001_1111 // special mask

/* L-type Instructions (1001) */
`define L_TYPE      7'b0000011
`define OP_LB       8'b1001_0000
`define OP_LH       8'b1001_0001
`define OP_LW       8'b1001_0010
`define OP_LBU      8'b1001_0011
`define OP_LHU      8'b1001_0100

/* R-type Instructions (0010) */
`define R_TYPE      7'b0110011
`define OP_ADD      8'b0010_0000
`define OP_SUB      8'b0010_0001 // special mask
`define OP_SLT      8'b0010_0010
`define OP_SLTU     8'b0010_0100
`define OP_XOR      8'b0010_0110
`define OP_OR       8'b0010_1000
`define OP_AND      8'b0010_1010
`define OP_SLL      8'b0010_1100
`define OP_SRL      8'b0010_1110
`define OP_SRA      8'b0010_1111

/* S-type Instructions (0011) */
`define S_TYPE      7'b0100011
`define OP_SB       8'b0011_1101
`define OP_SH       8'b0011_1110
`define OP_SW       8'b0011_1111

/* B-type Instructions (0100) */
`define B_TYPE      7'b1100011
`define OP_BEQ      8'b0100_0000
`define OP_BNE      8'b0100_0001
`define OP_BLT      8'b0100_0010
`define OP_BGE      8'b0100_0011
`define OP_BLTU     8'b0100_0100
`define OP_BGEU     8'b0100_0101

/* other */
`define OP_LUI      8'b0101_0111
`define OP_AUIPC    8'b0101_0011
`define OP_JAL      8'b1101_0101
`define OP_JALR     8'b1101_1001

/* Exception */
`define OP_INVALID  8'b0000_0000
`define OP_NOP      8'b1111_1111

/* Register tag */
`define ALU_CNT         2
`define BRANCH_CNT      1
`define LS_CNT          1

`define ALU_MASTER      2'b00
`define ALU_SALVER      2'b01
`define LOAD_STORE      2'b10

`define REG_TAG_WIDTH   2
`define EXE_CNT         8
`define regtag_t        [`REG_TAG_WIDTH - 1: 0]
`define UNLOCKED        2'b11

/* alu instruction */
`define sinst_t     [3 : 0]
`define ADD         4'b0000
`define SUB         4'b0001
`define SLT         4'b0010
`define SLTU        4'b0100
`define XOR         4'b0110
`define OR          4'b1000
`define AND         4'b1010
`define SLL         4'b1100
`define SRL         4'b1110
`define SRA         4'b1111
`define LUI         4'b0111
`define AUIPC       4'b0011
`define JAL         4'b0101
`define JALR        4'b1001

`define BEQ         4'b0000
`define BNE         4'b0001
`define BLT         4'b0010
`define BGE         4'b0011
`define BLTU        4'b0100
`define BGEU        4'b0101
/* ls instrucion */
`define LB          4'b0000
`define LH          4'b0001
`define LW          4'b0010
`define LBU         4'b0011
`define LHU         4'b0100
`define SB          4'b1101
`define SH          4'b1110
`define SW          4'b1111

`define STK         5
`define STKSIZE     2**`STK
/* reorder buffer */
`define COMMON_MODE 0
`define JUMP_MODE   1

/* useful marco */
`define UPDATE_PAIR(_tag, _data, tag, data)                                     \
    {_tag, _data} <= (en_alu0 && tag == `ALU_MASTER) ? {`UNLOCKED, alu_data0} : \
                     (en_alu1 && tag == `ALU_SALVER) ? {`UNLOCKED, alu_data1} : \
                     (en_ls   && tag == `LOAD_STORE) ? {`UNLOCKED, ls_data}   : \
                     {tag, data};
                     
`define UPDATE_VAR(_tag, tag)                               \
    _tag <= (en_alu0 && tag == `ALU_MASTER) ? `UNLOCKED :   \
            (en_alu1 && tag == `ALU_SALVER) ? `UNLOCKED :   \
            (en_ls   && tag == `LOAD_STORE) ? `UNLOCKED   : \
            tag;

`define UPDATE_PAIR_W(_tag, _data, tag, data)                                  \
    {_tag, _data} = (en_alu0 && tag == `ALU_MASTER) ? {`UNLOCKED, alu_data0} : \
                    (en_alu1 && tag == `ALU_SALVER) ? {`UNLOCKED, alu_data1} : \
                    (en_ls   && tag == `LOAD_STORE) ? {`UNLOCKED, ls_data}   : \
                    {tag, data};
                     
`define UPDATE_VAR_W(_tag, tag)                         \
    _tag = (en_alu0 && tag == `ALU_MASTER) ? `UNLOCKED: \
        (en_alu1 && tag == `ALU_SALVER) ? `UNLOCKED:    \
        (en_ls   && tag == `LOAD_STORE) ? `UNLOCKED:    \
        tag;

`define READ_VAR_DEFINE(_en_r, _reg_read_addr, _data, _lock)\
    input wire _en_r,                                       \
    input wire `regaddr_t _reg_read_addr,                   \
    output wire `word_t _data,                              \
    output wire `regtag_t _lock,

`define WRITE_VAR_DEFINE(_en_w, _reg_write_addr, _write_data)   \
    input wire _en_w,                                           \
    input wire `regaddr_t _reg_write_addr,                      \
    input wire `word_t _write_data,

`define REV(inst) {inst[7 : 0], inst[15 : 8], inst[23: 16], inst[31 : 24]}

`endif