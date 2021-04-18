`include "opcodes.v"
`include "state_def.v"

`define TRUE   1'b1
`define FALSE  1'b0

// for alu_op
`define ADD_OP    2'b00
`define SUB_OP    2'b01
`define ALU_OP    2'b10

// for i_or_d
`define PC_MEM     1'b0
`define ALUOut_MEM 1'b1

// for alu_src_A
`define PC_A      1'b0
`define REG_A     1'b1

// for alu_src_B
`define REG_B     2'b00
`define OFFSET_B  2'b01
`define IMMD_B    2'b10

// for pc_src
`define ALU_PC    1'b0
`define ALUOut_PC 1'b1

module control_unit(opcode, func_code, clk, reset_n, pc_write_cond, pc_write, i_or_d, mem_read, mem_to_reg, mem_write, ir_write, pc_to_reg, pc_src, halt, wwd, new_inst, reg_write, alu_src_A, alu_src_B, alu_op, pvs_write_en, bcond);
    input [3:0] opcode;
    input [5:0] func_code;
    input clk, reset_n;
    input bcond;

    output reg pc_write_cond, pc_write, i_or_d, mem_read, mem_to_reg, mem_write, ir_write, pc_src, pvs_write_en;
    //additional control signals. pc_to_reg: to support JAL, JRL. halt: to support HLT. wwd: to support WWD. new_inst: new instruction start
    output reg pc_to_reg, halt, wwd, new_inst, reg_write;
    output reg [1:0] alu_src_A, alu_src_B;
    output reg [1:0] alu_op;

    reg [`kStateBits-1:0] current_state;
    reg [`kStateBits-1:0] next_state;
    reg is_rtype, is_itype, is_load, is_store, is_jrel, is_jreg, is_jwrite, is_jump, is_branch;

    initial begin
        current_state <= `STATE_IF_1;
        next_state <= `STATE_IF_1;
    end

    always @(*) begin
        //////////////////////////
        // Classify Instruction //
        //////////////////////////
        case (opcode)
            `ALU_OP: begin
                case (func_code)
                    `INST_FUNC_ADD,
                    `INST_FUNC_SUB,
                    `INST_FUNC_AND,
                    `INST_FUNC_ORR,
                    `INST_FUNC_NOT,
                    `INST_FUNC_TCP,
                    `INST_FUNC_SHL,
                    `INST_FUNC_SHR: is_rtype = `TRUE;
                endcase
            end
            `ADI_OP,
            `ORI_OP,
            `LHI_OP: begin
                is_itype = `TRUE;
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
            `JPR_OP: begin
                case (func_code)
                    `INST_FUNC_JPR: begin
                        is_jump = `TRUE;
                        is_jreg = `TRUE;
                    end
                endcase
            end
            `JRL_OP: begin
                case (func_code)
                    `INST_FUNC_JRL: begin
                        is_jump = `TRUE;
                        is_jreg = `TRUE;
                        is_jwrite = `TRUE;
                    end
                endcase
            end
            `HLT_OP: begin
                case (func_code)
                    `INST_FUNC_HLT: halt = `TRUE;
                endcase
            end
            `WWD_OP: begin
                case (func_code)
                    `INST_FUNC_WWD: wwd = `TRUE;
                endcase
            end
        endcase

        ////////////////
        // micro code //
        ////////////////
        ir_write = `FALSE;
        mem_read = `FALSE;
        mem_write = `FALSE;
        mem_to_reg = `FALSE;
        pc_write = `FALSE;
        pc_write_cond = `TRUE;
        pc_to_reg = `FALSE;
        case (current_state)
            `STATE_IF_1: begin
                // IR <- MEM[PC]
                mem_read = `TRUE;
                i_or_d = `PC_MEM;
            end
            // `STATE_IF_2: begin
            //     wait for memory read
            // end
            `STATE_ID: begin
                // A <- RF[rs1(IR)]
                // B <- RF[rs2(IR)]
                // ALUOut <- PC + OFFSET
                ir_write = `TRUE;
                alu_src_A = `PC_A;
                alu_src_B = `OFFSET_B;
                alu_op = `ADD_OP;
            end
            `STATE_EX_1: begin
                // ALUOUT <- REG O REG
                //     <- REG O IMMD
                //     <- PC O IMMD
                alu_op = `ALU_OP;
                if (is_rtype | is_itype | is_load | is_store | is_jreg | is_branch | wwd | halt) begin
                    alu_src_A = `REG_A;
                end else if (is_jrel) begin
                    alu_src_A = `PC_A;
                end
                if (is_rtype | is_branch) begin
                    alu_src_B = `REG_B;
                end else if (is_itype | is_load | is_store | is_jrel) begin
                    alu_src_B = `IMMD_B;
                end
                if (is_jwrite) begin
                    // RF[$2] <- PC
                    reg_write = `TRUE;
                    pc_to_reg = `TRUE;
                end
                if (is_branch) begin
                    // PC <- ALUOut if branch not taken (need to determine bcond also)
                    alu_op = `SUB_OP;  // for bcond
                    pc_write_cond = `FALSE;
                    pc_src = `ALUOut_PC;
                end
            end
            `STATE_EX_2: begin
                if (is_branch) begin
                    // PC <- OFT(PC, IMMD)
                    alu_src_A = `PC_A;
                    alu_src_B = `IMMD_B;
                    alu_op = `ALU_OP;
                    pc_write = `TRUE;
                    pc_src = `ALU_PC;
                end
                else if (is_jump) begin
                    // PC <- ALUOut(== res of before calculation)
                    pc_write = `TRUE;
                    pc_src = `ALUOut_PC;
                end
            end
            `STATE_MEM_1: begin
                i_or_d = `ALUOut_MEM;
                if (is_load) begin
                    // MDR <- MEM[ALUOut]
                    mem_read = `TRUE;
                end else if (is_store) begin
                    // MEM[ALUOut] <- B
                    mem_write = `TRUE;
                    // PC <- PC + OFFSET
                    alu_src_A = `PC_A;
                    alu_src_B = `OFFSET_B;
                    alu_op = `ADD_OP;
                    pc_write = `TRUE;
                end
            end
            `STATE_MEM_2: begin

            end
            `STATE_WB: begin
                reg_write = `TRUE;
                // default:
                // RF[rd(IR)] <- ALUOut
                if (is_load) begin
                    // RF[rd(IR)] <- MDR
                    mem_to_reg = `TRUE;
                end
                // PC <- PC + OFFSET
                alu_src_A = `PC_A;
                alu_src_B = `OFFSET_B;
                alu_op = `ADD_OP;
                pc_write = `TRUE;
            end
        endcase

        /////////////////////
        // calculate state //
        /////////////////////
        case(current_state)
            `STATE_IF_1: begin 
                next_state = `STATE_IF_2;
            end
            `STATE_IF_2: begin
                if (is_jrel) begin
                    next_state = `STATE_EX_1;
                end
                else begin
                    next_state = `STATE_ID;
                end
            end
            `STATE_ID: next_state = `STATE_EX_1;
            `STATE_EX_1: begin
                next_state = `STATE_MEM_1;
                if (is_jump) begin
                    next_state = `STATE_EX_2;
                end
                else if (is_branch) begin
                    if (bcond) begin  // branch not taken
                        next_state = `STATE_IF_1;
                    end
                    else begin  // branch taken
                        next_state = `STATE_EX_2;
                    end
                end
            end
            `STATE_EX_2: begin
                if (is_branch | is_jump) begin
                    next_state = `STATE_IF_1;
                end
                else if (is_itype | is_rtype | is_jwrite | wwd | halt) begin
                    next_state = `STATE_WB;
                end
                else if (is_load | is_store) begin
                    next_state = `STATE_MEM_1;
                end
            end
            `STATE_MEM_1: next_state = `STATE_MEM_2;
            `STATE_MEM_2: begin
                if (is_load) begin
                    next_state = `STATE_WB;
                end
                else if (is_store) begin
                    next_state = `STATE_IF_1;
                end
            end
            `STATE_WB: begin
                next_state = `STATE_IF_1;
            end
        endcase
    end

    //////////////////
    // update state //
    //////////////////
    always @(posedge clk) begin
        if (!reset_n) begin
            current_state <= `STATE_IF_1;
        end
        else begin
            current_state <= next_state;
        end
    end

endmodule
