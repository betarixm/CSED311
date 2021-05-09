`include "opcodes.v"
`include "env.v"

module branch_calculator (A, B, PC, imm, branch_type, jump_type, next_pc, bcond);

    input [`WORD_SIZE-1:0] A, B, PC;
    input [`WORD_SIZE-1:0] imm;
    input [1:0] branch_type;
    input [1:0] jump_type;
    output [`WORD_SIZE-1:0] next_pc;
    output reg bcond;

    assign next_pc = (bcond) ? (PC + imm + 1) : (
        (jump_type == `J_JAL || jump_type == `J_JMP) ? ({PC[15:12], imm[11:0]}) : (
            (jump_type == `J_JPR || jump_type == `J_JRL) ? (A) : (
                PC + 1
            )
        )
    );

    always @(*) begin
        case (branch_type)
            `BRANCH_NE: bcond = (A != B);
            `BRANCH_EQ: bcond = (A == B);
            `BRANCH_GZ: bcond = ($signed(A) > 0);
            `BRANCH_LZ: bcond = ($signed(A) < 0);
        endcase
    end

endmodule