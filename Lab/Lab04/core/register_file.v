`include "env.v"
`include "opcodes.v"

module register_file(read_out1, read_out2, read1, read2, write_reg, write_data, reg_write, pvs_write_en, clk); 
    input [1:0] read1;
    input [1:0] read2;
    input [1:0] write_reg;
    input [15:0] write_data;
    input reg_write;
    input pvs_write_en;
    input clk;
    output [15:0] read_out1;
    output [15:0] read_out2;

    //TODO: implement register file
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
        if(pvs_write_en) begin // Write when last cycle (=pvs_write_en is enabled)
            if(reg_write && (0 <= write_reg && write_reg < `NUM_MAX_REGISTER)) begin
                r[write_reg] = write_data;
            end
        end
    end

endmodule