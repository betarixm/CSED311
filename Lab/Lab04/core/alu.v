`include "opcodes.v"

`define NumBits 16

module alu (A, B, func_code, branch_type, C, overflow_flag, bcond);
    input [`NumBits-1:0] A; //input data A
    input [`NumBits-1:0] B; //input data B
    input [3-1:0] func_code; //function code for the operation
    input [2-1:0] branch_type; //branch type for bne, beq, bgz, blz
    output reg [`NumBits-1:0] C; //output data C
    output reg overflow_flag; 
    output reg bcond; //1 if branch condition met, else 0

    always @(*) begin
        case (func_code)
            `FUNC_ADD:  C = A + B;
            `FUNC_SUB:  C = A - B;
            `FUNC_AND:  C = A & B;
            `FUNC_ORR:  C = A | B;
            `FUNC_NOT:  C = ~A;
            `FUNC_TCP:  C = ~A + 1;
            `FUNC_SHL:  C = $signed(A) <<< 1;
            `FUNC_SHR : C = $signed(A) >>> 1;
        endcase

        if (func_code == `FUNC_ADD) overflow_flag = ~(A[`NumBits - 1] ^ B[`NumBits - 1]) & (A[`NumBits - 1] ^ C[`NumBits - 1]);
        else if (func_code == `FUNC_SUB) overflow_flag = (A[`NumBits - 1] ^ B[`NumBits - 1]) & (A[`NumBits - 1] ^ C[`NumBits - 1]);
        else overflow_flag = 1'b0;

        case (branch_type)
            `BRANCH_NE: bcond = (C != 0);
            `BRANCH_EQ: bcond = (C == 0);
            `BRANCH_GZ: bcond = (C  > 0);
            `BRANCH_LZ: bcond = (C  < 0);
        endcase
    end
endmodule