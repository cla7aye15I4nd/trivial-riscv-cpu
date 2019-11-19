/* common datatype config */
`define byte_t  [7 : 0]
`define half_t  [15: 0]
`define word_t  [31: 0]

/* cpu data struct*/
`define oper_t  [7 : 0]
`define inst_t  [31: 0]
`define addr_t  [16: 0]
`define memaddr_t  [16: 0]

/* register config */
`define REG_COUNT       32
`define REG_ADDR_WIDTH  5
`define REG_DATA_WIDTH  32
`define regaddr_t       [`REG_ADDR_WIDTH - 1: 0]

/* signal */
`define WRITE_ENABLE    1`b1
`define WRITE_DISNABLE  1`b0

/* constant */
`define ZERO_WORD 32'h00000000
`define NULL_PTR  17'b0000_0000_0000_0000_0