`include "env.v" 
`include "opcodes.v" 

`define TAG 15:4
`define IDX 3
`define OFF 2:1

module cache(c__read_m, c__write_m, addr, i__data, o__data, c__valid, m__read_m, m__write_m, m__addr, m__data_out, m__is_stall, clk);
    input wire c__read_m, c__write_m;
    input wire [`WORD_SIZE-1:0] addr;
    input wire [`WORD_SIZE-1:0] i__data;
    output reg [`WORD_SIZE-1:0] o__data;
    output wire c__valid;
    output wire m__read_m, m__write_m;
    output wire [`WORD_SIZE-1:0] m__addr;
    output wire [`WORD_SIZE-1:0] m__data_out;
    input wire [`WORD_SIZE-1:0] m__is_stall;
    input wire clk;
    
    reg clk_counter;
    reg is_hit;
    wire idx;

    reg [12:0] cache__tag[4];
    reg cache__valid[4];
    reg [63:0] cache__data[4];
    reg cache__lru[4];
    
    assign idx = addr[IDX];

    initial begin
        clock_counter = 0;
    end

    // Combinational Logic
    always @(*) begin
        
    end

    // Sequential Logic
    always @(posedge clk) begin
        // Valid
        // Valid-control-signal is basically turned off.
        c__valid <= 0;

        // Update Clk Counter
        // TODO: Reset to 0 when logic end
        clk_counter <= clk_counter + 1;

        // Hit
        is_hit <= (cache__valid[idx] & (cache__tag[idx] == addr[TAG])) | (cache__valid[idx + 2] && cache__tag[idx + 2] == addr[TAG]);

        if(is_hit) begin
            // When Hit
            // Clk counter is estimated to be 1.
            // Watch out for non-blocking

            if(c__read_m) begin
                if(cache__valid[idx]) begin
                    o__data <= cache__data[idx][`WORD_SIZE * addr[`OFF]:`WORD_SIZE * (addr[`OFF] + 1) - 1];
                    // Update LRU
                    cache__lru[idx] <= 1;
                    cache__lru[~idx] <= 0;
                end else begin
                    o__data <= cache__data[idx + 2][`WORD_SIZE * addr[`OFF]:`WORD_SIZE * (addr[`OFF] + 1) - 1]
                    // Update LRU
                    cache__lru[2 + idx] <= 1;
                    cache__lru[2 + (~idx)] <= 0; 
                end
                clk_counter <= 0; // Reset clk counter; Need to check race condition
                c__valid <= 1; // Turn on valid-control-signal; It will be turned off at next posedge
            end
        end else begin 
            // When Not Hit
            // Clk counter is estimated to be 1.
            // Watch out for non-blocking

        end
    end

endmodule