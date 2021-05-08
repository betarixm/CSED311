`include "opcodes.v" 

module alu (A, B, func_code, branch_type, alu_out, overflow_flag, bcond);

    input [`WORD_SIZE-1:0] A;
    input [`WORD_SIZE-1:0] B;
    input [2:0] func_code;
    input [1:0] branch_type; 

    output reg [`WORD_SIZE-1:0] alu_out;
    output reg overflow_flag; 
    output reg bcond;

    always @(*) begin
        case (func_code)
            `FUNC_ADD:  C = A + B;
            `FUNC_SUB:  C = A - B;
            `FUNC_AND:  C = A & B;
            `FUNC_ORR:  C = A | B;
            `FUNC_NOT:  C = ~A;
            `FUNC_TCP:  C = ~A + 1;
            `FUNC_SHL:  C = $signed(A) <<< 1;
            `FUNC_SHR:  C = $signed(A) >>> 1;
            `FUNC_ZRO:  C = `NumBits'd0;
            `FUNC_IDN:  C = A;
            `FUNC_LHI:  C = {B[`ADDR_SIZE-1:0],`ADDR_SIZE'b0};
            `FUNC_TGT:  C = {A[`WORD_SIZE-1:`ADDR_SIZE],4'b0,B[`IMMD_SIZE-1:0]};
        endcase
    end

    always @(*) begin
        if (func_code == `FUNC_ADD) overflow_flag = ~(A[`NumBits - 1] ^ B[`NumBits - 1]) & (A[`NumBits - 1] ^ C[`NumBits - 1]);
        else if (func_code == `FUNC_SUB) overflow_flag = (A[`NumBits - 1] ^ B[`NumBits - 1]) & (A[`NumBits - 1] ^ C[`NumBits - 1]);
        else overflow_flag = 1'b0;
    end

endmodule