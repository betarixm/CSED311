`include "opcodes.v" 
`include "env.v"

`define TRUE   1'b1
`define FALSE  1'b0

module branch_predictor(clk, reset_n, is_flush, opcode, calculated_pc, current_pc, is_branch, is_jump, next_pc);
    input clk;
    input reset_n;
    input is_flush;
    input [3:0] opcode;
    input [`WORD_SIZE-1:0] calculated_pc;
    input [`WORD_SIZE-1:0] current_pc; // PC from branch resolve stage
    input is_branch, is_jump;
    output [`WORD_SIZE-1:0] next_pc;

    // Always Not Taken
    assign next_pc = current_pc + 1;
    
endmodule
