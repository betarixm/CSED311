`include "opcodes.v" 

// for reg_write_dest
`define RD_W      2'b00
`define RT_W      2'b01
`define TWO_W     2'b10


module control_unit (opcode, funct, clk, reset_n,mem_read, mem_to_reg, mem_write, pc_to_reg, halt, wwd, reg_write, reg_write_dest, func_code, branch_type);

	input [3:0] opcode;
    input [6-1:0] funct;
	input clk;
	input reset_n;
	

	output reg reg_write, mem_read, mem_to_reg, mem_write;
  	//additional control signals. pc_to_reg: to support JAL, JRL. halt: to support HLT. wwd: to support WWD.
  	output reg pc_to_reg, halt, wwd;
  	output reg [1:0] reg_write_dest;
    output reg [4-1:0] func_code;
    output reg [2-1:0] branch_type;

	reg is_rtype, is_itype, is_load, is_store, is_jrel, is_jreg, is_jwrite, is_jump, is_branch, is_lhi, is_wwd, is_halt;

	
	always @(*) begin
        //////////////////////////
        // Classify Instruction //
        //////////////////////////
        is_rtype = `FALSE;
        is_itype = `FALSE;
        is_load = `FALSE;
        is_store = `FALSE;
        is_jrel = `FALSE;
        is_jreg = `FALSE;
        is_jwrite = `FALSE;
        is_jump = `FALSE;
        is_branch = `FALSE;
        is_lhi = `FALSE;
        is_wwd = `FALSE;
        is_halt = `FALSE;
        case (opcode)
            `ADI_OP,
            `ORI_OP: begin
                is_itype = `TRUE;
            end
            `LHI_OP: begin
                is_itype = `TRUE;
                is_lhi = `TRUE;
            end
            `LWD_OP: begin
                is_itype = `TRUE;
                is_load = `TRUE;
            end
            `SWD_OP: begin
                is_itype = `TRUE;
                is_store = `TRUE;
            end
            `BNE_OP,
            `BEQ_OP,
            `BGZ_OP,
            `BLZ_OP: begin
                is_branch = `TRUE;
            end
            `JMP_OP: begin
                is_jump = `TRUE;
                is_jrel = `TRUE;
            end
            `JAL_OP: begin
                is_jump = `TRUE;
                is_jrel = `TRUE;
                is_jwrite = `TRUE;
            end
            `ALU_OP,
            `JPR_OP,
            `JRL_OP,
            `WWD_OP,
            `HLT_OP: begin
                case (funct)
                    `INST_FUNC_ADD,
                    `INST_FUNC_SUB,
                    `INST_FUNC_AND,
                    `INST_FUNC_ORR,
                    `INST_FUNC_NOT,
                    `INST_FUNC_TCP,
                    `INST_FUNC_SHL,
                    `INST_FUNC_SHR: is_rtype = `TRUE;

                    `INST_FUNC_JPR: begin
                        is_jump = `TRUE;
                        is_jreg = `TRUE;
                    end
                    `INST_FUNC_JRL: begin
                        is_jump = `TRUE;
                        is_jreg = `TRUE;
                        is_jwrite = `TRUE;
                    end
                    `INST_FUNC_WWD: is_wwd = `TRUE;
                    `INST_FUNC_HLT: is_halt = `TRUE;
                endcase
            end
        endcase
    end


    always @(*) begin
        case (opcode)
        `ADI_OP: func_code = `FUNC_ADD;
        `ORI_OP: func_code = `FUNC_ORR;
        `LHI_OP: func_code = `FUNC_LHI;
        `JMP_OP: func_code = `FUNC_TGT;
        `JAL_OP: func_code = `FUNC_TGT;
        `LWD_OP: func_code = `FUNC_ADD;
        `SWD_OP: func_code = `FUNC_ADD;
        `BNE_OP: branchType = `BRANCH_NE;
        `BEQ_OP: branchType = `BRANCH_EQ;
        `BGZ_OP: branchType = `BRANCH_GZ;
        `BLZ_OP: branchType = `BRANCH_LZ;
        `ALU_OP,
        `JPR_OP, 
        `JRL_OP, 
        `HLT_OP, 
        `WWD_OP: begin 
            case (funct)
                `INST_FUNC_ADD: func_code = `FUNC_ADD;
                `INST_FUNC_SUB: func_code = `FUNC_SUB;
                `INST_FUNC_AND: func_code = `FUNC_AND;
                `INST_FUNC_ORR: func_code = `FUNC_ORR;
                `INST_FUNC_NOT: func_code = `FUNC_NOT;
                `INST_FUNC_TCP: func_code = `FUNC_TCP;
                `INST_FUNC_SHL: func_code = `FUNC_SHL;
                `INST_FUNC_SHR: func_code = `FUNC_SHR;
                `INST_FUNC_JPR: func_code = `FUNC_IDN;
                `INST_FUNC_JRL: func_code = `FUNC_IDN;
                `INST_FUNC_WWD: func_code = `FUNC_IDN;
                `INST_FUNC_HLT: func_code = `FUNC_ZRO;
            endcase
        end
        endcase
    end



    assign reg_write = !is_store && is_branch;
    assign mem_read = is_load;
    assign mem_to_reg = is_load;
    assign mem_write = is_store;
    assign pc_to_reg = is_jreg;
    assign reg_write_dest = (is_lhi | is_itype) ? `RT_W : (is_jwrite) ? `TWO_W : `RD_W;

endmodule
