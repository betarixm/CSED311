`include "opcodes.v"

module data_memory (read_data, write_data, mem_read, mem_write, address_in, address_out, sig_read, sig_write, read_data_out, write_data_out, clk);
    input [`WORD_SIZE-1:0] read_data;
    input [`WORD_SIZE-1:0] write_data;
    input mem_read;
    input mem_write;
    input [`WORD_SIZE-1:0] address_in;
    output [`WORD_SIZE-1:0] address_out;
    output reg sig_read;
    output reg sig_write;
    output reg [`WORD_SIZE-1:0] read_data_out;
    output reg [`WORD_SIZE-1:0] write_data_out;

    input clk;

    assign address_out = address_in;
    assign read_data_out = read_data;
    assign write_data_out = write_data;

    initial begin
        sig_read <= 0;
        sig_write <= 0;
    end
    
    always @(reset_n) begin
        sig_read <= 0;
        sig_write <= 0;
    end

    always @(negedge clk) begin
        if (mem_read) begin
            sig_read <= 1;
        end
        if (mem_write) begin
            sig_write <= 1;
        end
    end

    always @(negedge clk) begin
        sig_read <= 0;
        sig_write <= 0;
    end

endmodule