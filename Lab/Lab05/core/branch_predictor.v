`include "opcodes.v" 
`include "env.v"

`define TRUE   1'b1
`define FALSE  1'b0

module branch_predictor(clk, reset_n, is_flush, opcode, calculated_pc, current_pc, next_pc, imm);
    input clk;
    input reset_n;
    input is_flush;
    input [3:0] opcode;
    input [`WORD_SIZE-1:0] calculated_pc;
    input [`WORD_SIZE-1:0] current_pc; // PC from branch resolve stage
    input [`WORD_SIZE-1:0] imm;

    output [`WORD_SIZE-1:0] next_pc;

    wire is_branch = (opcode == `BNE_OP) || (opcode == `BEQ_OP) || (opcode == `BGZ_OP) || (opcode == `BLZ_OP);
    wire is_imm_jump = (opcode == `JAL_OP) || (opcode == `JMP_OP);
    wire is_reg_jump = (opcode == `JRL_OP) || (opcode == `JPR_OP);

    // Always Taken
    assign next_pc = (is_branch) ? (current_pc + 1 + imm) : (
        (is_imm_jump) ? ({current_pc[15:12], imm[11:0]}) : (
            (is_reg_jump) ? (`WORD_SIZE'b0) : (
                current_pc + 1
            )
        )
    );
    
endmodule
