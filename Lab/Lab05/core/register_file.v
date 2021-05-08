`include "env.v"
`include "opcodes.v" 

module register_file (read_out1, read_out2, read1, read2, dest, write_data, reg_write, clk, reset_n);

    input clk, reset_n;
    input [1:0] read1;
    input [1:0] read2;
    input [1:0] dest;
    input reg_write;
    input [`WORD_SIZE-1:0] write_data;
    
    output [`WORD_SIZE-1:0] read_out1;
    output [`WORD_SIZE-1:0] read_out2;


    reg [`WORD_SIZE - 1:0] r[`NUM_MAX_REGISTER - 1:0];

    integer i;

    assign read_out1 = r[read1];
    assign read_out2 = r[read2];

    initial begin
        for(i = 0; i < `NUM_MAX_REGISTER; i = i + 1) begin
            r[i] <= `WORD_SIZE'd0;
        end
    end

    always @(posedge clk) begin
        if(reg_write && (0 <= dest && dest < `NUM_MAX_REGISTER)) begin
            r[dest] = write_data;
        end
    end

endmodule
