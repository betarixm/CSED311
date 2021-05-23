`include "env.v" 
`include "opcodes.v" 

`define QWORD_SIZE 64
`define W_Q_EXTEND 48

`define TAG 15:4
`define IDX 3
`define OFF 2:1

`define STATE_READY   3'd0
`define STATE_READ    3'd1
`define STATE_WRITE   3'd2
`define STATE_MEM_RD  3'd3
`define STATE_MEM_WR  3'd4
`define STATE_READY_OBSERVE_MEM 3'd5
`define STATE_READ_OBSERVE_MEM  3'd6


module cache(c__read_m, c__write_m, addr, i__data, o__data, c__ready, m__read_m, m__write_m, m__addr, m__size, m__data, m__ready, clk);
    input c__read_m, c__write_m;
    input [`WORD_SIZE-1:0] addr;
    input [`WORD_SIZE-1:0] i__data;
    output reg c__ready;
    output reg [`WORD_SIZE-1:0] o__data;
    output reg m__read_m, m__write_m;
    output reg [`WORD_SIZE-1:0] m__addr;
    output reg [`WORD_SIZE-1:0] m__size;
    inout reg [`QWORD_SIZE-1:0] m__data;
    reg [`QWORD_SIZE-1:0] m__data_out;
    input [`WORD_SIZE-1:0] m__ready;
    input clk;
    
    reg is_hit;

    reg                   cache__valid[4];
    reg                   cache__lru[4];
    reg [12:0]            cache__tag[4];
    reg [`QWORD_SIZE-1:0] cache__data[4];
    
    wire idx;
    assign idx = addr[`IDX];
    assign c__ready = (c__state == `STATE_READY || c__state == `STATE_READY_OBSERVE_MEM);
    assign m__data = (c__state == `STATE_WRITE) ? m__data_out : `QWORD_SIZE'bz

    initial begin
        cache__lru[0] = 0; 
        cache__lru[1] = 0; 
        cache__lru[2] = 0; 
        cache__lru[3] = 0;

        c__state = `STATE_READY;
    end

    // Combinational Logic
    always @(*) begin
        if ((c__read_m | c__write_m) & c__ready) begin
            if (c__state == `STATE_READY_OBSERVE_MEM) begin
                if (c__read_m)  c__state = `STATE_READ_OBSERVE_MEM;
            end
            else begin
                if (c__read_m)  c__state = `STATE_READ;
                if (c__write_m) c__state = `STATE_WRITE;
            end

            // Tag array access
            is_hit = (cache__valid[idx] && (cache__tag[idx] == addr[`TAG]))
                    || (cache__valid[2 + idx] && cache__tag[2 + idx] == addr[`TAG]);
        end 

        if (c__state == `STATE_READY_OBSERVE_MEM)
        begin
            // Observe if memory write is finished
            if (m__ready) begin
                m__write_m = 0;
                c__state = `STATE_READY;
            end
        end
        else if (c__state == `STATE_READ_OBSERVE_MEM)
        begin
            // Observe if memory write is finished
            if (m__ready) begin
                m__write_m = 0;
                c__state = `STATE_READ;
            end
        end
    end


    // Sequential Logic
    always @(posedge clk) begin
        if (c__state == `STATE_READ || c__state == `STATE_READ_OBSERVE_MEM)
        begin
            if (is_hit) begin // When cache hit occurs
                // Data array access
                if(cache__valid[idx]) begin
                    o__data <= cache__data[  idx  ][`WORD_SIZE*(addr[`OFF] + 1) - 1 : `WORD_SIZE*addr[`OFF]];
                    // Update LRU bit
                    cache__lru[idx] <= 0;
                    cache__lru[~idx] <= 1;
                end else begin
                    o__data <= cache__data[2 + idx][`WORD_SIZE*(addr[`OFF] + 1) - 1 : `WORD_SIZE*addr[`OFF]];
                    // Update LRU bit
                    cache__lru[2 + idx] <= 0;
                    cache__lru[2 + (~idx)] <= 1;
                end
                // Cache access ended
                c__state <= `STATE_READY;
            end
            else begin // When cache miss occurs
                // Prepare for reading new data
                m__read_m <= 1;
                m__addr <= addr;
                // Will wait for memory read
                c__state <= `STATE_MEM_RD;
            end
        end // STATE_READ
        else if (c__state == `STATE_MEM_RD)
        begin
            // Wait for finishing memory read
            if (m__ready) begin
                o__data <= m__data[`WORD_SIZE*(addr[`OFF] + 1) - 1 : `WORD_SIZE*addr[`OFF]];
                // Replace invalid or LRU data with new data from memory
                if (cache__valid[idx] == 0 || (cache__valid[2+idx] == 1 && cache__lru[idx] == 1)) begin
                    // Update cache
                    cache__valid[idx] <= 1;
                    cache__lru[idx]   <= 0;
                    cache__lru[~idx]  <= 1;
                    cache__tag[idx]   <= addr[tag];
                    cache__data[idx]  <= m__data;
                end 
                else begin
                    // Update cache
                    cache__valid[2 + idx]  <= 1;
                    cache__lru[2 + idx]    <= 0;
                    cache__lru[2 + (~idx)] <= 1;
                    cache__tag[2 + idx]    <= addr[tag];
                    cache__data[2 + idx]   <= m__data;
                end
                m__read_m <= 0;
                c__state <= `STATE_READY;
            end
        end // STATE_MEM_RD
        else if (c__state == `STATE_WRITE)
        begin
            if (is_hit) begin // When cache hit occurs
                // Write to memory
                // Let CPU move forward
                // If any other write request occurs, and it misses, that request would stall until we finish the writing.
                m__write_m <= 1;
                m__addr <= {addr[`WORD_SIZE-1:2], 2'b00}; // aligned address
                m__size <= `QWORD_SIZE;
                // Data array access
                if(cache__valid[idx]) begin
                    m__data_out <= {cache__data[idx][`QWORD_SIZE-1 : `WORD_SIZE*(addr[`OFF] + 1)]
                                    , i__data
                                    , cache__data[idx][`WORD_SIZE*addr[`OFF]-1 : 0]};
                    // Update Cache
                    cache__valid[idx] <= 0;
                end else begin
                    m__data_out <= {cache__data[2 + idx][`QWORD_SIZE-1 : `WORD_SIZE*(addr[`OFF] + 1)]
                                    , i__data
                                    , cache__data[2 + idx][`WORD_SIZE*addr[`OFF]-1 : 0]};
                    // Update Cache
                    cache__valid[2 + idx] <= 0;
                end
                // Cache access ended
                c__state <= `STATE_READY_OBSERVE_MEM;
            end
            else begin // When cache miss occurs
                // Write to memory (no allocate)
                // CPU stall until we finish the writing.
                m__write_m <= 1;
                m__addr <= addr; // not aligned address
                m__size <= `WORD_SIZE;
                m__data_out <= {`W_Q_EXTEND'b0, i__data};

                c__state <= `STATE_MEM_WR;
            end
        end // STATE_WRITE
        else if (c__state == `STATE_MEM_WR)
        begin
            // Wait for finishing memory write
            if (m__ready) begin
                m__write_m <= 0;
                c__state <= `STATE_READY;
            end
        end // STATE_MEM_WR

    end // sequential logic ends

endmodule