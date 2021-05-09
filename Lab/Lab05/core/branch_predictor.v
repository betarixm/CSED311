`include "opcodes.v" 
`include "env.v"

`define TRUE   1'b1
`define FALSE  1'b0

`define STRONG_TAKEN 2'b11
`define WEAKLY_TAKEN 2'b10
`define WEAKLY_NOT_TAKEN 2'b01
`define STRONG_NOT_TAKEN 2'b00

module branch_predictor(clk, reset_n, is_flush, opcode, calculated_pc, current_pc, next_pc, imm);
    input clk;
    input reset_n;
    input is_flush;
    input [3:0] opcode;
    input [`WORD_SIZE-1:0] calculated_pc;
    input [`WORD_SIZE-1:0] current_pc; // PC from branch resolve stage
    input [`WORD_SIZE-1:0] imm;

    output reg [`WORD_SIZE-1:0] next_pc;

    reg[1:0] state;

    wire is_branch;
    wire is_correct;

    initial begin
        state = `WEAKLY_TAKEN;
    end

    assign is_branch = (opcode == `BNE_OP) || (opcode == `BEQ_OP) || (opcode == `BGZ_OP) || (opcode == `BLZ_OP);
    assign is_correct = calculated_pc == next_pc;

    always @(posedge clk) begin
        case(state)
            `STRONG_TAKEN:
                state <= (is_correct) ? (`STRONG_TAKEN) : (`WEAKLY_TAKEN);
            `WEAKLY_TAKEN:
                state <= (is_correct) ? (`STRONG_TAKEN) : (`WEAKLY_NOT_TAKEN);
            `WEAKLY_NOT_TAKEN:
                state <= (is_correct) ? (`STRONG_NOT_TAKEN) : (`WEAKLY_TAKEN);
            `STRONG_NOT_TAKEN:
                state <= (is_correct) ? (`STRONG_NOT_TAKEN) : (`WEAKLY_NOT_TAKEN);
        endcase

        next_pc <= (state[1]) ? (current_pc + 1 + imm) : (current_pc + 1);
    end
    
endmodule
