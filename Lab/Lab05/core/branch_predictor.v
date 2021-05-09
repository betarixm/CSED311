`include "opcodes.v" 
`include "env.v"

module branch_predictor(clk, reset_n, is_flush, is_BJ_type, caculated_pc, current_PC, next_PC);

    input clk;
    input reset_n;
    input is_flush;
    input is_BJ_type;
    input [`WORD_SIZE-1:0] caculated_pc;
    input [`WORD_SIZE-1:0] current_PC; // PC from branch resolve stage

    output [`WORD_SIZE-1:0] next_PC;

    assign next_PC = current_PC + 1;

    //TODO: implement branch predictor

endmodule
