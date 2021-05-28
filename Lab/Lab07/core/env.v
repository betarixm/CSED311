`define R0 0
`define R1 1
`define R2 2
`define R3 3

`define NUM_MAX_REGISTER 4

`define OPCODE 15:12
`define RS 11:10
`define RT 9:8
`define RD 7:6
`define FUNC 5:0

`define  QWORD_SIZE   64
`define   WORD_SIZE   16
`define   ADDR_SIZE   12
`define   IMMD_SIZE    8
`define   REG_SIZE     2

`define NOP 16'hf11c

`define INTRPT_BEGIN 1
`define INTRPT_END 2

// WWD $0, but different from real WWD $0 (0xf01c)
