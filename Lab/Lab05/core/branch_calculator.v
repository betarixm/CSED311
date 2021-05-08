`include "opcodes.v"

module branch_calculator (A, B, C)

    input [`WORD_SIZE-1:0] A, B;
    output [`WORD_SIZE-1:0] C;
    
    assign C = A + B[`IMMD_SIZE-1:0] + 1;

endmodule