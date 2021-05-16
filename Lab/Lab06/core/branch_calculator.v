`include "opcodes.v"
`include "env.v"

module branch_calculator (A, B, PC, imm, is_branch, is_jump, branch_type, jump_type, next_pc, bcond);

    input [`WORD_SIZE-1:0] A, B, PC;
    input [`IMMD_SIZE-1:0] imm;
    input is_branch, is_jump;
    input [1:0] branch_type;
    input [1:0] jump_type;
    output [`WORD_SIZE-1:0] next_pc;
    output reg bcond;

    assign next_pc = (is_branch && bcond) ? (PC + imm + 1) : (
        (is_jump) ? (
            (jump_type == `J_JAL || jump_type == `J_JMP) ?
                ({PC[`WORD_SIZE-1:`ADDR_SIZE],4'b0, imm})
                : A
                )
            : (
                PC + 1
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