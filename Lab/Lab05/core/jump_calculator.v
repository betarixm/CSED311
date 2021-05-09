`include "opcodes.v"
`include "env.v"

module jump_calculator (A, PC, imm, jump_type, next_pc);

    input [`WORD_SIZE-1:0] A, PC;
    input [`IMMD_SIZE-1:0] imm;
    input [1:0] jump_type;
    output reg [`WORD_SIZE-1:0] next_pc;

    always @(*) begin
        case (jump_type)
            `J_JMP,
            `J_JAL: next_pc = {PC[`WORD_SIZE-1:`ADDR_SIZE],4'b0, imm};
            `J_JPR,
            `J_JRL: next_pc = A;
        endcase
    end

endmodule