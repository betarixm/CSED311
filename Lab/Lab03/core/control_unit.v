`include "opcodes.v" 	   

module control_unit (instr, alu_src, alu_op, reg_write, mem_read, mem_to_reg, mem_write, PCtoReg, jp, branch);
    input [`WORD_SIZE-1:0] instr;
    output reg alu_src;
    output reg [3-1:0] alu_op;
    output reg reg_write;
    output reg mem_read;
    output reg mem_to_reg;
    output reg mem_write;
    output reg PCtoReg;
    output reg jp;
    output reg branch;

    reg isItype;
    reg isStore;
    wire isLoad;
    wire isBR;

    assign alu_src = isItype || isStore;
    assign reg_write = !isStore && !isBR;
    assign mem_read = isLoad;
    assign mem_to_reg = isLoad;
    assign mem_write = isStore;
    assign branch = isBR;

    always @(*) begin
        case (instr[`WORD_SIZE-1:`WORD_SIZE-4]) // opcode
            `ALU_OP: begin
                case (instr[5:0]) // func_code
                    `INST_FUNC_ADD: alu_op = `FUNC_ADD;
                    `INST_FUNC_SUB: alu_op = `FUNC_SUB;
                    `INST_FUNC_AND: alu_op = `FUNC_AND;
                    `INST_FUNC_ORR: alu_op = `FUNC_ORR;
                    `INST_FUNC_NOT: alu_op = `FUNC_NOT;
                    `INST_FUNC_TCP: alu_op = `FUNC_TCP;
                    `INST_FUNC_SHL: alu_op = `FUNC_SHL;
                    `INST_FUNC_SHR: alu_op = `FUNC_SHR;
                endcase
            end
            `ADI_OP,
            `ORI_OP,
            `LHI_OP: begin
                isItype = 1;
            end
            `ADI_OP: alu_op = `FUNC_ADD;
            `ORI_OP: alu_op = `FUNC_ORR;
            `LHI_OP: alu_op = `FUNC_SHL;

            `LWD_OP: begin
                isItype = 1;
                isLoad = 1;
                alu_op = `FUNC_ADD;
            end
            `SWD_OP: begin
                isStore = 1;
                alu_op = `FUNC_ADD;
            end

            `BNE_OP,
            `BEQ_OP,
            `BGZ_OP,
            `BLZ_OP: begin
                isBR = 1;
                alu_op = `FUNC_SUB;
            end
            
            `JMP_OP: begin
                jp = 1;
                alu_op = `FUNC_AND;
            end
            `JAL_OP: begin
                jp = 1;
                PCtoReg = 1;
                alu_op = `FUNC_AND;
            end
            `JPR_OP: begin
                case (instr[5:0]) // func_code
                    `INST_FUNC_JPR: begin
                        jp = 1;
                    end
                endcase
            end
            `JRL_OP: begin
                case (instr[5:0]) // func_code
                    `INST_FUNC_JRL: begin
                        jp = 1;
                        PCtoReg = 1;
                    end
                endcase
            end
        endcase
    end 


endmodule