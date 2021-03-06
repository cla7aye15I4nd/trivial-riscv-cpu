/* common datatype config */
`define byte_t  [7 : 0]
`define half_t  [15: 0]
`define word_t  [31: 0]

/* cpu data struct*/
`define oper_t  [7 : 0]
`define inst_t  [31: 0]
`define addr_t  [17: 0]

/* register config */
`define REG_COUNT       32
`define REG_ADDR_WIDTH  5
`define REG_DATA_WIDTH  32
`define regaddr_t       [`REG_ADDR_WIDTH - 1: 0]

/* signal */
`define READ_SIGNAL     0
`define WRITE_SIGNAL    1

/* constant */
`define ZERO 32'h00000000
`define NULL_PTR  17'b1111_1111_1111_1111_1