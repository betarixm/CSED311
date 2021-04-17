`include "opcodes.v"

// for alu_op
`define ADD_OP 2'b00
`define SUB_OP 2'b01
`define ALU_OP 2'b10

module alu_control_unit(funct, opcode, ALUOp, clk, funcCode, branchType);
    input [1:0] ALUOp;
    input clk;
    input [6-1:0] funct;
    input [4-1:0] opcode;

    output reg [4-1:0] funcCode;
    output reg [2-1:0] branchType;

    always @(*) begin
        if (ALUOp == `ADD_OP) begin
            funcCode = `FUNC_ADD;
        end
        else if (ALUOp == `SUB_OP) begin
            funcCode = `FUNC_SUB; 
        end
        else begin
            case (opcode)
                `ALU_OP,
                `JPR_OP, 
                `JRL_OP, 
                `HLT_OP, 
                `WWD_OP: begin 
                    case (funct)
                        `INST_FUNC_ADD: funcCode = `FUNC_ADD;
                        `INST_FUNC_SUB: funcCode = `FUNC_SUB;
                        `INST_FUNC_AND: funcCode = `FUNC_AND;
                        `INST_FUNC_ORR: funcCode = `FUNC_ORR;
                        `INST_FUNC_NOT: funcCode = `FUNC_NOT;
                        `INST_FUNC_TCP: funcCode = `FUNC_TCP;
                        `INST_FUNC_SHL: funcCode = `FUNC_SHL;
                        `INST_FUNC_SHR: funcCode = `FUNC_SHR;
                        `INST_FUNC_JPR: funcCode = `FUNC_IDN;
                        `INST_FUNC_JRL: funcCode = `FUNC_IDN;
                        `INST_FUNC_WWD: funcCode = `FUNC_IDN;
                        `INST_FUNC_HLT: funcCode = `FUNC_ZRO;
                    endcase
                end
                `ADI_OP: funcCode = `FUNC_ADD;
                `ORI_OP: funcCode = `FUNC_ORR;
                `LHI_OP: funcCode = `FUNC_LHI;
                `JMP_OP: funcCode = `FUNC_TGT;
                `JAL_OP: funcCode = `FUNC_TGT;
                `LWD_OP: funcCode = `FUNC_ADD;
                `SWD_OP: funcCode = `FUNC_ADD;
                `BNE_OP: funcCode = `FUNC_OFT;
                `BEQ_OP: funcCode = `FUNC_OFT;
                `BGZ_OP: funcCode = `FUNC_OFT;
                `BLZ_OP: funcCode = `FUNC_OFT;
            endcase
        end

        case (opcode)
            `BNE_OP: branchType = `BRANCH_NE;
            `BEQ_OP: branchType = `BRANCH_EQ;
            `BGZ_OP: branchType = `BRANCH_GZ;
            `BLZ_OP: branchType = `BRANCH_LZ;
        endcase
    end

endmodule