`include "opcodes.v" 	   

module instruction_memory (read_address, inputReady, data, readM, instruction, clk);
    input [`WORD_SIZE-1:0] read_address;
    input inputReady;
    inout wire [`WORD_SIZE-1:0] data;
    output reg readM;
    output reg [`WORD_SIZE-1:0] instruction;

    input clk;

    reg fetch_instruction;


    always @(posedge clk) begin
        readM <= 1;
        fetch_instruction <= 1;    
    end

    always @(*) begin
        if (fetch_instruction == 1 && inputReady == 1) begin
            fetch_instruction = 0;
            instruction = data;
        end
    end

endmodule