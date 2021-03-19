`include "opcodes.v" 	   

module control_unit (instr, alu_src, reg_write, mem_read, mem_to_reg, mem_write, jp, branch);
    input [`WORD_SIZE-1:0] instr;
    output reg alu_src;
    output reg reg_write;
    output reg mem_read;
    output reg mem_to_reg;
    output reg mem_write;
    output reg jp;
    output reg branch;

    assign alu_src = isItype || isStore;
    assign mem_read = isLoad;
    assign mem_to_reg = isLoad;
    assign mem_write = isStore;
    assign reg_write = !isStore;

    always @(*) begin
        case (instr[`WORD_SIZE-1:`WORD_SIZE-4])
            `ALU_OP: begin
                
            end
            `ADI_OP,
            `ORI_OP,
            `LHI_OP: begin
                isItype = 1;
            end
            `LWD_OP: begin
                isItype = 1;
                isLoad = 1;
            end
            `SWD_OP: begin
                isStore = 1;
            end
            `BNE_OP,
            `BEQ_OP,
            `BGZ_OP,
            `BLZ_OP: begin
                
            end
            `JMP_OP,
            `JAL_OP,
            `JPR_OP,
            `JRL_OP: begin
                
            end
        endcase
    end 


endmodule