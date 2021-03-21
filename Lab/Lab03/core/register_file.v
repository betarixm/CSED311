`include "opcodes.v"
`include "registers.v"

module register_file(read_out1, read_out2, read1, read2, write_reg, write_data, reg_write, clk); 
    output [15:0] read_out1;
    output [15:0] read_out2;
    input [1:0] read1;
    input [1:0] read2;
    input [1:0] write_reg;
    input [15:0] write_data;
    input reg_write;
    input clk;

    reg [`WORD_SIZE - 1:0] r[`NUM_MAX_REGISTER - 1: 0];

    integer i;

    initial begin
        for(i = 0; i < `NUM_MAX_REGISTER; i = i + 1) begin
            r[i] <= `WORD_SIZE'd0;
        end

        read_out1 <= `WORD_SIZE'd0;
        read_out2 <= `WORD_SIZE'd0;
    end

    always @(posedge clk) begin
         if(reg_write) begin
             r[write_reg] <= write_data;
         end else begin
            if(0 <= read1 < `NUM_MAX_REGISTER) begin
                read_out1 <= r[read1];
            end
            
            if(0 <= read2 < `NUM_MAX_REGISTER) begin
                read_out2 <= r[read2];
            end
         end
    end
    
endmodule

