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
`define STATE_READY_PARALLEL 3'd5
`define STATE_READ_PARALLEL  3'd6
`define STATE_WRITE_PARALLEL 3'd7


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
    reg [2:0] c__state;

    reg                   cache__valid[3:0];
    reg                   cache__lru[3:0];
    reg [12:0]            cache__tag[3:0];
    reg [`QWORD_SIZE-1:0] cache__data[3:0];

    wire [`WORD_SIZE-1:0] data_0;
    wire [`WORD_SIZE-1:0] data_1;
    wire [`WORD_SIZE-1:0] data_2;
    wire [`WORD_SIZE-1:0] data_3;

    wire idx;
    assign idx = addr[`IDX];
    assign c__ready = (c__state == `STATE_READY || c__state == `STATE_READY_PARALLEL);
    assign m__data = (c__state == `STATE_WRITE) ? m__data_out : `QWORD_SIZE'bz;

    assign data_0 = (cache__valid[idx]) ? cache__data[idx][`WORD_SIZE * 1 - 1:`WORD_SIZE * 0] : cache__data[idx + 2][`WORD_SIZE * 1 - 1:`WORD_SIZE * 0];
    assign data_1 = (cache__valid[idx]) ? cache__data[idx][`WORD_SIZE * 2 - 1:`WORD_SIZE * 1] : cache__data[idx + 2][`WORD_SIZE * 2 - 1:`WORD_SIZE * 1];
    assign data_2 = (cache__valid[idx]) ? cache__data[idx][`WORD_SIZE * 3 - 1:`WORD_SIZE * 2] : cache__data[idx + 2][`WORD_SIZE * 3 - 1:`WORD_SIZE * 2];
    assign data_3 = (cache__valid[idx]) ? cache__data[idx][`WORD_SIZE * 4 - 1:`WORD_SIZE * 3] : cache__data[idx + 2][`WORD_SIZE * 4 - 1:`WORD_SIZE * 3];

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
            if (c__state == `STATE_READY) begin
                if (c__read_m)  c__state = `STATE_READ;
                if (c__write_m) c__state = `STATE_WRITE;
            end else if (c__state == `STATE_READY_PARALLEL) begin
                if (c__read_m)  c__state = `STATE_READ_PARALLEL;
                if (c__write_m) c__state = `STATE_WRITE_PARALLEL;
            end

            // Tag array access
            is_hit = (cache__valid[idx] && (cache__tag[idx] == addr[`TAG])) || (cache__valid[2 + idx] && cache__tag[2 + idx] == addr[`TAG]);
        end

        if (c__state == `STATE_READY_PARALLEL) begin
            // Observe if memory write is finished
            if (m__ready) begin
                m__write_m = 0;
                c__state = `STATE_READY;
            end
        end else if (c__state == `STATE_READ_PARALLEL) begin
            // Observe if memory write is finished
            if (m__ready) begin
                m__write_m = 0;
                c__state = `STATE_READ;
            end
        end else if (c__state == `STATE_WRITE_PARALLEL) begin
            if (m__ready) begin
                m__write_m = 0;
                c__state = `STATE_WRITE;
            end
        end
    end


    // Sequential Logic
    always @(posedge clk) begin
        if (c__state == `STATE_READ || c__state == `STATE_READ_PARALLEL) begin
            if(is_hit) begin // When cache hit occurs
                // Data array access
                if(cache__valid[idx]) begin
                    // Set 0
                    o__data <= cache__data[  idx  ][`WORD_SIZE*addr[`OFF] +: `WORD_SIZE];
                    // Update LRU bit
                    cache__lru[idx] <= 0;
                    cache__lru[~idx] <= 1;
                end else begin
                    // Set 1
                    o__data <= cache__data[2 + idx][`WORD_SIZE*addr[`OFF] +: `WORD_SIZE];
                    // Update LRU bit
                    cache__lru[2 + idx] <= 0;
                    cache__lru[2 + (~idx)] <= 1;
                end
                // Cache access 
                if (c__state == `STATE_READ) c__state <= `STATE_READY;
                if (c__state == `STATE_READ_PARALLEL) c__state <= `STATE_READY_PARALLEL;
            end else begin // When cache miss occurs
                if(c__state == `STATE_READ) begin
                    // Prepare for reading new data
                    m__read_m <= 1;
                    m__addr <= addr;
                    // Will wait for memory read
                    c__state <= `STATE_MEM_RD;
                end else if(c__state == `STATE_READ_PARALLEL) begin
                    if (m__ready) c__state <= `STATE_READ;
                end
            end
        end // STATE_READ
        else if (c__state == `STATE_MEM_RD) begin
            // Wait for finishing memory read
            if (m__ready) begin
                o__data <= m__data[`WORD_SIZE*addr[`OFF] +: `WORD_SIZE];
                // Replace invalid or LRU data with new data from memory
                if (cache__valid[idx] == 0 || (cache__valid[2+idx] == 1 && cache__lru[idx] == 1)) begin
                    // Update cache
                    cache__valid[idx] <= 1;
                    cache__lru[idx]   <= 0;
                    cache__lru[~idx]  <= 1;
                    cache__tag[idx]   <= addr[`TAG];
                    cache__data[idx]  <= m__data;
                end 
                else begin
                    // Update cache
                    cache__valid[2 + idx]  <= 1;
                    cache__lru[2 + idx]    <= 0;
                    cache__lru[2 + (~idx)] <= 1;
                    cache__tag[2 + idx]    <= addr[`TAG];
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
                    case(addr[`OFF])
                        0: begin
                            m__data_out <= {data_3, data_2, data_1, i__data};
                        end
                        1: begin
                            m__data_out <= {data_3, data_2, i__data, data_0};
                        end
                        2: begin
                            m__data_out <= {data_3, i__data, data_1, data_0};
                        end
                        3: begin
                            m__data_out <= {i__data, data_2, data_1, data_0};
                        end
                    endcase

                    // Update Cache
                    cache__valid[idx] <= 0;
                end else begin
                    case(addr[`OFF])
                        0: begin
                            m__data_out <= {data_3, data_2, data_1, i__data};
                        end
                        1: begin
                            m__data_out <= {data_3, data_2, i__data, data_0};
                        end
                        2: begin
                            m__data_out <= {data_3, i__data, data_1, data_0};
                        end
                        3: begin
                            m__data_out <= {i__data, data_2, data_1, data_0};
                        end
                    endcase
                    // Update Cache
                    cache__valid[2 + idx] <= 0;
                end
                // Cache access ended
                c__state <= `STATE_READY_PARALLEL;
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