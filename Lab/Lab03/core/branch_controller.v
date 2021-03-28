`include "opcodes.v"

module branch_controller(sub_input, opcode, is_branch);
    input [`WORD_SIZE-1:0] sub_input;
    input [3:0] opcode;
    output reg is_branch;

    always @(*) begin
        is_branch = 0;

        case(opcode)
            `BNE_OP: begin
                is_branch = (sub_input != 0);
            end

            `BEQ_OP: begin
                is_branch = (sub_input == 0);
            end

            `BGZ_OP: begin
                is_branch = (sub_input > 0);
            end

            `BLZ_OP: begin
                is_branch = (sub_input < 0);
            end
        endcase
    end
endmodule