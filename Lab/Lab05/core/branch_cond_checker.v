`include "opcodes.v"

module branch_cond_checker (A, B, branch_type, bcond)
    
    input [`WORD_SIZE-1:0] A, B;
    input branch_type;
    output bcond;

    always @(*) begin
        case (branch_type)
            `BRANCH_NE: bcond = (A != B);
            `BRANCH_EQ: bcond = (A == B);
            `BRANCH_GZ: bcond = ($signed(A) >  0);
            `BRANCH_LZ: bcond = ($signed(A) <  0);
        endcase
    end	

endmodule