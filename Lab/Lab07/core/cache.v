`include "env.v" 
`include "opcodes.v" 

`define QWORD_SIZE 64
`define W_Q_EXTEND 48

`define TAG 15:3
`define IDX 2
`define OFF 1:0

`define STATE_READY   3'd0
`define STATE_READ    3'd1
`define STATE_WRITE   3'd2
`define STATE_MEM_RD  3'd3
`define STATE_MEM_WR  3'd4
`define STATE_READY_PARALLEL 3'd5
`define STATE_READ_PARALLEL  3'd6
`define STATE_WRITE_PARALLEL 3'd7


module cache(c__read_m, c__write_m, addr, i__data, o__data, c__ready, m__read_m, m__write_m, m__addr, m__size, m__data, m__ready, m__ack, is_hit, clk, reset_n, is_granted);
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
    input m__ready;
    input m__ack;
    input clk, reset_n;
    input is_granted;

    reg [`WORD_SIZE-1:0] reading_addr;
    reg [`WORD_SIZE-1:0] next_writing_addr;
    reg [`WORD_SIZE-1:0] next_writing_data;
    reg from_write_parallel;
    
    output reg is_hit;
    reg r__data_out_updated;
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
    assign m__data = (c__state == `STATE_WRITE || c__state == `STATE_MEM_WR || c__state == `STATE_WRITE_PARALLEL || c__state == `STATE_READY_PARALLEL) ? m__data_out : `QWORD_SIZE'bz;

    assign data_0 = (cache__valid[idx] && (cache__tag[idx] == addr[`TAG])) ? cache__data[idx][`WORD_SIZE * 1 - 1:`WORD_SIZE * 0] : cache__data[idx + 2][`WORD_SIZE * 1 - 1:`WORD_SIZE * 0];
    assign data_1 = (cache__valid[idx] && (cache__tag[idx] == addr[`TAG])) ? cache__data[idx][`WORD_SIZE * 2 - 1:`WORD_SIZE * 1] : cache__data[idx + 2][`WORD_SIZE * 2 - 1:`WORD_SIZE * 1];
    assign data_2 = (cache__valid[idx] && (cache__tag[idx] == addr[`TAG])) ? cache__data[idx][`WORD_SIZE * 3 - 1:`WORD_SIZE * 2] : cache__data[idx + 2][`WORD_SIZE * 3 - 1:`WORD_SIZE * 2];
    assign data_3 = (cache__valid[idx] && (cache__tag[idx] == addr[`TAG])) ? cache__data[idx][`WORD_SIZE * 4 - 1:`WORD_SIZE * 3] : cache__data[idx + 2][`WORD_SIZE * 4 - 1:`WORD_SIZE * 3];

    initial begin
        m__write_m = 0;
        cache__lru[0] = 0; 
        cache__lru[1] = 0; 
        cache__lru[2] = 0; 
        cache__lru[3] = 0;

        cache__valid[0] = 0; 
        cache__valid[1] = 0; 
        cache__valid[2] = 0; 
        cache__valid[3] = 0;

        reading_addr = 0;
        c__state = `STATE_READY;
        from_write_parallel = 0;
        r__data_out_updated = 0;
    end

    // Combinational Logic
    always @(*) begin
        if ((c__read_m | c__write_m) & c__ready & ~m__ack) begin
            if (c__state == `STATE_READY) begin
                if (c__read_m)  c__state = `STATE_READ;
                if (c__write_m) c__state = `STATE_WRITE;
            end else if (c__state == `STATE_READY_PARALLEL) begin
                if (c__read_m)  c__state = `STATE_READ_PARALLEL;
                if (c__write_m) begin
                    c__state = `STATE_WRITE_PARALLEL;
                    next_writing_addr = addr;
                    next_writing_data = i__data;
                end
            end

            // Tag array access
            if (from_write_parallel) begin
                is_hit = (cache__valid[next_writing_addr[`IDX]] && (cache__tag[next_writing_addr[`IDX]] == next_writing_addr[`TAG])) || (cache__valid[2 + next_writing_addr[`IDX]] && cache__tag[2 + next_writing_addr[`IDX]] == next_writing_addr[`TAG]);
            end
            else begin
                is_hit = (cache__valid[idx] && (cache__tag[idx] == addr[`TAG])) || (cache__valid[2 + idx] && cache__tag[2 + idx] == addr[`TAG]);
            end
        end


        if (c__state == `STATE_MEM_RD) begin
            // Wait for finishing memory read
            if (m__ack) begin
                o__data = m__data[`WORD_SIZE*reading_addr[`OFF] +: `WORD_SIZE];
                // Replace invalid or LRU data with new data from memory
                if (cache__valid[reading_addr[`IDX]] == 0 || (cache__valid[2+reading_addr[`IDX]] == 1 && cache__lru[reading_addr[`IDX]] == 1)) begin
                    // Update cache
                    cache__valid[reading_addr[`IDX]] = 1;
                    cache__lru[reading_addr[`IDX]]   = 0;
                    cache__lru[~reading_addr[`IDX]]  = 1;
                    cache__tag[reading_addr[`IDX]]   = reading_addr[`TAG];
                    cache__data[reading_addr[`IDX]]  = m__data;
                end 
                else begin
                    // Update cache
                    cache__valid[2 + reading_addr[`IDX]]  = 1;
                    cache__lru[2 + reading_addr[`IDX]]    = 0;
                    cache__lru[2 + (~reading_addr[`IDX])] = 1;
                    cache__tag[2 + reading_addr[`IDX]]    = reading_addr[`TAG];
                    cache__data[2 + reading_addr[`IDX]]   = m__data;
                end
                m__read_m = 0;
                c__state = `STATE_READY;
                reading_addr = 0;
            end
        end // STATE_MEM_RD
        else if (c__state == `STATE_MEM_WR)
        begin
            // Wait for finishing memory write
            if (m__ack) begin
                m__write_m = 0;
                c__state = `STATE_READY;
            end
        end // STATE_MEM_WR

    end


    // Sequential Logic
    always @(posedge clk) begin
        if(!reset_n) begin
            cache__lru[0] <= 0; 
            cache__lru[1] <= 0; 
            cache__lru[2] <= 0; 
            cache__lru[3] <= 0;

            cache__valid[0] <= 0; 
            cache__valid[1] <= 0; 
            cache__valid[2] <= 0; 
            cache__valid[3] <= 0;

            reading_addr <= 0;
            c__state <= `STATE_READY;
            from_write_parallel <= 0;
        end else begin
            if (c__state == `STATE_READ || c__state == `STATE_READ_PARALLEL) begin
                if(is_hit) begin // When cache hit occurs
                    // Data array access
                    if(cache__valid[idx] && (cache__tag[idx] == addr[`TAG])) begin
                        // Set 0
                        case(addr[`OFF])
                            0: o__data <= cache__data[  idx  ][`WORD_SIZE*1-1 : `WORD_SIZE*0];
                            1: o__data <= cache__data[  idx  ][`WORD_SIZE*2-1 : `WORD_SIZE*1];
                            2: o__data <= cache__data[  idx  ][`WORD_SIZE*3-1 : `WORD_SIZE*2];
                            3: o__data <= cache__data[  idx  ][`WORD_SIZE*4-1 : `WORD_SIZE*3];
                        endcase
                        // Update LRU bit
                        cache__lru[idx] <= 0;
                        cache__lru[~idx] <= 1;
                    end else begin
                        // Set 1
                        case(addr[`OFF])
                            0: o__data <= cache__data[2 + idx][`WORD_SIZE*1-1 : `WORD_SIZE*0];
                            1: o__data <= cache__data[2 + idx][`WORD_SIZE*2-1 : `WORD_SIZE*1];
                            2: o__data <= cache__data[2 + idx][`WORD_SIZE*3-1 : `WORD_SIZE*2];
                            3: o__data <= cache__data[2 + idx][`WORD_SIZE*4-1 : `WORD_SIZE*3];
                        endcase
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
                        m__addr <= {addr[`WORD_SIZE-1:2], 2'b00}; // aligned address
                        // Will wait for memory read
                        c__state <= `STATE_MEM_RD;
                        reading_addr <= addr;
                    end else if(c__state == `STATE_READ_PARALLEL) begin
                        if (m__ready) c__state <= `STATE_READ;
                    end
                end
            end // STATE_READ
            else if (c__state == `STATE_WRITE)
            begin
                from_write_parallel <= 0;
                if (is_hit) begin // When cache hit occurs
                    if (from_write_parallel) begin
                        // Write to memory
                        // Let CPU move forward
                        // If any other write request occurs, and it misses, that request would stall until we finish the writing.
                        m__write_m <= 1;
                        m__addr <= {next_writing_addr[`WORD_SIZE-1:2], 2'b00}; // aligned next_writing_address
                        m__size <= `QWORD_SIZE;
                        // Data array access
                        if((r__data_out_updated == 0) && cache__valid[next_writing_addr[`IDX]] && (cache__tag[next_writing_addr[`IDX]] == next_writing_addr[`TAG])) begin
                            case(next_writing_addr[`OFF])
                                0: begin
                                    m__data_out <= {data_3, data_2, data_1, next_writing_data};
                                end
                                1: begin
                                    m__data_out <= {data_3, data_2, next_writing_data, data_0};
                                end
                                2: begin
                                    m__data_out <= {data_3, next_writing_data, data_1, data_0};
                                end
                                3: begin
                                    m__data_out <= {next_writing_data, data_2, data_1, data_0};
                                end
                            endcase

                            // Update Cache
                            cache__valid[next_writing_addr[`IDX]] <= 0;
                            r__data_out_updated <= 1;
                        end else begin
                            if (r__data_out_updated == 0) begin
                                case(next_writing_addr[`OFF])
                                    0: begin
                                        m__data_out <= {data_3, data_2, data_1, next_writing_data};
                                    end
                                    1: begin
                                        m__data_out <= {data_3, data_2, next_writing_data, data_0};
                                    end
                                    2: begin
                                        m__data_out <= {data_3, next_writing_data, data_1, data_0};
                                    end
                                    3: begin
                                        m__data_out <= {next_writing_data, data_2, data_1, data_0};
                                    end
                                endcase
                                // Update Cache
                                cache__valid[2 + next_writing_addr[`IDX]] <= 0;
                                r__data_out_updated <= 1;
                            end
                        end
                        // Cache access ended
                    if(is_granted) begin
                        c__state <= `STATE_READY_PARALLEL;
                        r__data_out_updated <= 0;
                    end
                    end
                    else begin
                        // Write to memory
                        // Let CPU move forward
                        // If any other write request occurs, and it misses, that request would stall until we finish the writing.
                        m__write_m <= 1;
                        m__addr <= {addr[`WORD_SIZE-1:2], 2'b00}; // aligned address
                        m__size <= `QWORD_SIZE;
                        // Data array access
                        if((r__data_out_updated == 0) && cache__valid[idx] && (cache__tag[idx] == addr[`TAG])) begin
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
                            r__data_out_updated <= 1;
                            // Update Cache
                            cache__valid[idx] <= 0;
                        end
                        else begin
                            if(r__data_out_updated == 0) begin
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
                                r__data_out_updated <= 1;
                            end
                        end
                    end
                    // Cache access ended
                    if(is_granted) begin
                        c__state <= `STATE_READY_PARALLEL;
                        r__data_out_updated <= 0;
                    end
                end
                else begin // When cache miss occurs
                    if (from_write_parallel) begin
                        // Write to memory (no allocate)
                        // CPU stall until we finish the writing.
                        m__write_m <= 1;
                        m__addr <= next_writing_addr; // not aligned address
                        m__size <= `WORD_SIZE;
                        m__data_out <= {`W_Q_EXTEND'b0, next_writing_data};
                    end
                    else begin
                        // Write to memory (no allocate)
                        // CPU stall until we finish the writing.
                        m__write_m <= 1;
                        m__addr <= addr; // not aligned address
                        m__size <= `WORD_SIZE;
                        m__data_out <= {`W_Q_EXTEND'b0, i__data};
                    end

                    c__state <= `STATE_MEM_WR;
                end
            end // STATE_WRITE
            else if (c__state == `STATE_READY_PARALLEL) begin
                // Observe if memory write is finished
                if (m__ack) begin
                    m__write_m <= 0;
                    c__state <= `STATE_READY;
                end
            end else if (c__state == `STATE_READ_PARALLEL) begin
                // Observe if memory write is finished
                if (m__ack) begin
                    m__write_m <= 0;
                    c__state <= `STATE_READ;
                end
            end else if (c__state == `STATE_WRITE_PARALLEL) begin
                if (m__ack) begin
                    m__write_m <= 0;
                    c__state <= `STATE_WRITE;
                    from_write_parallel <= 1;
                end
            end
        end
    end // sequential logic ends

endmodule