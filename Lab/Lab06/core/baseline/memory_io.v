`include "opcodes.v"
`include "env.v"

// type
`define INST 0
`define DATA 1

module memory_io(clk, reset_n, data1, data2, m1_ready, m1_ack, m2_ready, m2_ack, read_inst, read_data, write_data, addr_inst, addr_data, read_m1, read_m2, write_m2, address1, address2, res_inst, res_data);
    input clk;
    input reset_n;

    input [`WORD_SIZE-1:0] data1, data2;
    input m1_ready, m1_ack, m2_ready, m2_ack;

    input read_inst, read_data, write_data;
    input [`WORD_SIZE-1:0] addr_inst, addr_data;

    reg m1_type, m2_type;
    wire inst_reading, data_reading;

    output reg read_m1, read_m2, write_m2;
    output reg [`WORD_SIZE-1:0] address1, address2;

    output reg [`WORD_SIZE-1:0] res_inst, res_data;

    
    initial begin
        read_m1 = 0;
        read_m2 = 0;
        write_m2 = 0;

        m1_type = `INST;
        m2_type = `DATA;
    end

    assign res_inst = (m1_type == `INST) ? data1 : data2;
    assign res_data = (m2_type == `DATA) ? data2 : data1;

    assign inst_reading = (~m1_ready & ~m1_ack & m1_type == `INST) | (~m2_ready & ~m2_ack & m2_type == `INST);
    assign data_reading = (~m1_ready & ~m1_ack & m1_type == `DATA) | (~m2_ready & ~m2_ack & m2_type == `DATA);

    assign address1 = (m1_type == `INST) ? addr_inst : addr_data;
    assign address2 = (m2_type == `DATA) ? addr_data : addr_inst;

    reg cnt;


    always @(posedge clk) begin
        if(!reset_n) begin
            cnt <= 0;
            read_m1 <= 0;
            read_m2 <= 0;
            write_m2 <= 0;

            m1_type <= `INST;
            m2_type <= `DATA;
        end
    end

    always @(*) begin
        if (read_inst & ~inst_reading) begin
            if (m1_ready) begin
                m1_type = `INST;
                read_m1 = 1;
            end
            else if (m2_ready & ~read_data) begin
                m2_type = `INST;
                read_m2 = 1;
            end
        end

        if (read_data & ~data_reading) begin
            if (m2_ready) begin
                m2_type = `DATA;
                read_m2 = 1;
            end
            else if (m1_ready & ~read_inst) begin
                m1_type = `DATA;
                read_m1 = 1;
            end
        end
        else if (write_data & (write_m2 & m2_type == `DATA)) begin
            if (m2_ready) begin
                m2_type = `DATA;
                write_m2 = 1;
            end
        end

        cnt = clk;

    end

endmodule