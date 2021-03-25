`include "opcodes.v"

module data_memory (address, write_data, ackOutput, inputReady, data, read_data, readM, writeM, address_out, mem_write, mem_read, clk);
    input [`WORD_SIZE-1:0] address;
    input [`WORD_SIZE-1:0] write_data;
    input ackOutput;
    input inputReady;
    inout [`WORD_SIZE-1:0] data;
    output reg readM;
    output reg writeM;
    output reg [`WORD_SIZE-1:0] address_out;

    output reg [`WORD_SIZE-1:0] read_data;
    
    input mem_write;
    input mem_read;

    input clk;

    always @(negedge clk) begin
        if (mem_write == 1) begin
            address_out <= address;
            data <= write_data;
            writeM <= 1;
        end
        else if (mem_read == 1) begin
            address_out <= address;
            readM <= 1;
        end
    end

    always @(*) begin
        if (writeM == 1 && ackOutput == 1) begin
            writeM = 0;
        end
        if (readM == 1 && inputReady == 1) begin
            readM = 0;
            read_data = data;
        end
    end 

endmodule