`include "opcodes.v"


// for alu_op
`define ADD_OP    2'b00
`define SUB_OP    2'b01
`define ALU_OP    2'b10

    input [3:0] opcode;
    input [5:0] func_code;
    input clk;

    output reg pc_write_cond, pc_write, i_or_d, mem_read, mem_to_reg, mem_write, ir_write, pc_src;
    //additional control signals. pc_to_reg: to support JAL, JRL. halt: to support HLT. wwd: to support WWD. new_inst: new instruction start
    output reg pc_to_reg, halt, wwd, new_inst;
    output reg [1:0] reg_write, alu_src_A, alu_src_B;
    output reg [1:0] alu_op;


    always @(*) begin
        case (opcode)
            `ADI_OP,
            `LWD_OP,
            `SWD_OP: alu_op = 1b'0;
            `BNE_OP,
            `BEQ_OP,
            `BGZ_OP,
            `BLZ_OP: alu_op = 1b'1;
        endcase
    end

endmodule
