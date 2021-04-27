`include "opcodes.v" 

module control_unit (opcode, func_code, clk, reset_n,mem_read, mem_to_reg, mem_write, pc_to_reg, halt, wwd, reg_write, reg_write_dest, alu_src_A, alu_src_B, alu_op);

	input [3:0] opcode;
	input [5:0] func_code;
	input clk;
	input reset_n;
	

	output reg reg_write, mem_read, mem_to_reg, mem_write;
  	//additional control signals. pc_to_reg: to support JAL, JRL. halt: to support HLT. wwd: to support WWD.
  	output reg pc_to_reg, halt, wwd;
  	output reg [1:0] reg_write_dest, alu_src_A, alu_src_B;
  	output reg [1:0] alu_op;

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
        pvs_write_en = `FALSE;
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
                case (func_code)
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

endmodule
