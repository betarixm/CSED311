`include "opcodes.v"
`include "env.v"

module branch_calculator (A, B, PC, imm, branch_type, next_pc, bcond);

    input [`WORD_SIZE-1:0] A, B, PC;
    input [`IMMD_SIZE-1:0] imm;
    input [1:0] branch_type;
    output [`WORD_SIZE-1:0] next_pc;
    output reg bcond;

    assign next_pc = (bcond) ? (PC + imm + 1) : (PC + 1);

    always @(*) begin
        case (branch_type)
            `BRANCH_NE: bcond = (A != B);
            `BRANCH_EQ: bcond = (A == B);
            `BRANCH_GZ: bcond = ($signed(A) >  0);
            `BRANCH_LZ: bcond = ($signed(A) <  0);
        endcase
    end

endmodule