`include "env.v" 
`include "opcodes.v" 

`define TAG 4:15
`define IDX 3
`define OFF 0:2

module cache(c__read_m, c__write_m, addr, i__data, o__data, c__valid, m__read_m, m__write_m, m__addr, m__data_out, m__is_stall, clk);
    input wire c__read_m, c__write_m;
    input wire [`WORD_SIZE-1:0] addr;
    input wire [`WORD_SIZE-1:0] i__data;
    output wire [`WORD_SIZE-1:0] o__data;
    output wire c__valid;
    output wire m__read_m, m__write_m;
    output wire [`WORD_SIZE-1:0] m__addr;
    output wire [`WORD_SIZE-1:0] m__data_out;
    input wire [`WORD_SIZE-1:0] m__is_stall;
    input wire clk;
    
    wire is_hit;
    wire idx;

    reg [12:0] cache__tag[4];
    reg cache__valid[4];
    reg [64:0] cache__data[4];
    reg [`WORD_SIZE-1:0] cache__lru[4];
    
    assign idx = addr[IDX];
    assign is_hit = (cache__valid[idx] & (cache__tag[idx] == addr[TAG])) | (cache__valid[idx + 2] && cache__tag[idx + 2] == addr[TAG]);

    always @(*) begin
        if(is_hit) begin
            // Hit

        end else begin
            
        end
    end

    always @(posedge clk) begin
        
    end

endmodule