`include "env.v" 
`include "opcodes.v" 

module alu (A, B, func_code, alu_out, overflow_flag);

    input [`WORD_SIZE-1:0] A;
    input [`WORD_SIZE-1:0] B;
    input [2:0] func_code;

    output reg [`WORD_SIZE-1:0] alu_out;
    output reg overflow_flag; 

    always @(*) begin
        case (func_code)
            `FUNC_ADD:  alu_out = A + B;
            `FUNC_SUB:  alu_out = A - B;
            `FUNC_AND:  alu_out = A & B;
            `FUNC_ORR:  alu_out = A | B;
            `FUNC_NOT:  alu_out = ~A;
            `FUNC_TCP:  alu_out = ~A + 1;
            `FUNC_SHL:  alu_out = $signed(A) <<< 1;
            `FUNC_SHR:  alu_out = $signed(A) >>> 1;
            `FUNC_ZRO:  alu_out = `WORD_SIZE'd0;
            `FUNC_IDN:  alu_out = A;
            `FUNC_LHI:  alu_out = {B[`ADDR_SIZE-1:0],`ADDR_SIZE'b0};
            `FUNC_TGT:  alu_out = {A[`WORD_SIZE-1:`ADDR_SIZE],4'b0,B[`IMMD_SIZE-1:0]};
        endcase
    end

    always @(*) begin
        if (func_code == `FUNC_ADD) overflow_flag = ~(A[`WORD_SIZE - 1] ^ B[`WORD_SIZE - 1]) & (A[`WORD_SIZE - 1] ^ alu_out[`WORD_SIZE - 1]);
        else if (func_code == `FUNC_SUB) overflow_flag = (A[`WORD_SIZE - 1] ^ B[`WORD_SIZE - 1]) & (A[`WORD_SIZE - 1] ^ alu_out[`WORD_SIZE - 1]);
        else overflow_flag = 1'b0;
    end

endmodule