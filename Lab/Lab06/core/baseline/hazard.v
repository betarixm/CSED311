`include "opcodes.v"
`include "env.v"

module hazard_detect(IFID_IR, IFID_M_valid, IDEX_rd, IDEX_M_valid, IDEX_M_reg_write, IDEX_M_mem_read, is_stall);

    input [`WORD_SIZE-1:0] IFID_IR;
    input IFID_M_valid;
    input [1:0]  IDEX_rd;
    input IDEX_M_valid;
    input IDEX_M_reg_write;
    input IDEX_M_mem_read;

    output is_stall;

    // hazard
    // need to wait until past instruction reads memory data

    assign is_stall = IFID_M_valid & IDEX_M_valid & IDEX_M_reg_write & IDEX_M_mem_read & (IDEX_rd == IFID_IR[`RS] || IDEX_rd == IFID_IR[`RT]);

endmodule