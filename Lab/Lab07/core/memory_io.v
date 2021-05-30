`include "opcodes.v"
`include "env.v"

// type
`define INST 0
`define DATA 1

module memory_io(clk, reset_n, is_granted, qdata1, qdata2, m1_ready, m1_ack, m2_ready, m2_ack, read_inst, read_data, write_data, addr_inst, addr_data, read_m1, read_m2, write_m2, write_q2, size_m2, address1, address2, res_inst, res_data, ready_inst, ack_inst, ready_data, ack_data, dmac_req);
    input clk;
    input reset_n;

    input is_granted;

    input [`QWORD_SIZE-1:0] qdata1, qdata2;
    input m1_ready, m1_ack, m2_ready, m2_ack;

    input read_inst, read_data, write_data;
    input [`WORD_SIZE-1:0] addr_inst, addr_data;
    input [`WORD_SIZE-1:0] size_m2;

    reg m1_type, m2_type;
    wire inst_reading, data_reading;

    output reg read_m1, read_m2, write_m2, write_q2;
    output reg [`WORD_SIZE-1:0] address1, address2;

    output reg [`QWORD_SIZE-1:0] res_inst, res_data;
    output ready_inst, ack_inst, ready_data, ack_data;

    input dmac_req;

    wire m2_bus_ready;

    assign m2_bus_ready = m2_ready & is_granted;
    
    initial begin
        read_m1 = 0;
        read_m2 = 0;
        write_m2 = 0;
        write_q2 = 0;

        m1_type = `INST;
        m2_type = `DATA;
    end

    assign res_inst = (m1_type == `INST) ? qdata1 : qdata2;
    assign res_data = (m2_type == `DATA) ? qdata2 : qdata1;

    assign inst_reading = (~m1_ready & ~m1_ack & m1_type == `INST) | (~m2_bus_ready & ~m2_ack & m2_type == `INST);
    assign data_reading = (~m1_ready & ~m1_ack & m1_type == `DATA) | (~m2_bus_ready & ~m2_ack & m2_type == `DATA);
    assign data_writing = (~m2_bus_ready & ~m2_ack & m2_type == `DATA);

    assign address1 = (m1_type == `INST) ? addr_inst : addr_data;
    assign address2 = (dmac_req || (!is_granted)) ? (`WORD_SIZE'bz) : (
        (m2_type == `DATA) ? addr_data : addr_inst
    );

    assign ready_inst = (m1_type == `INST) ? m1_ready : m2_bus_ready;
    assign ready_data = (m1_type == `DATA) ? m1_ready : m2_bus_ready;

    assign ack_inst = (m1_type == `INST) ? m1_ack : (m2_ack & is_granted);
    assign ack_data = (m1_type == `DATA) ? m1_ack : (m2_ack & is_granted);


    reg cnt;


    always @(posedge clk) begin
        if(!reset_n) begin
            cnt <= 0;
            read_m1 <= 0;
            read_m2 <= 0;
            write_m2 <= 0;
            write_q2 <= 0;

            m1_type <= `INST;
            m2_type <= `DATA;
        end
    end

    always @(*) begin
        if (m1_ack) begin
            read_m1 = 0;
        end
        if (m2_ack) begin
            read_m2 = 0;
            write_m2 = 0;
            write_q2 = 0;
        end

        if (read_inst & ~inst_reading) begin
            if (m1_ready) begin
                m1_type = `INST;
                read_m1 = 1;
            end
            else if (m2_bus_ready & ~read_data) begin
                m2_type = `INST;
                read_m2 = 1;
            end
        end

        if (read_data & ~data_reading) begin
            if (m2_bus_ready) begin
                m2_type = `DATA;
                read_m2 = 1;
            end
            else if (m1_ready & ~read_inst) begin
                m1_type = `DATA;
                read_m1 = 1;
            end
        end
        else if (write_data & ~data_writing) begin
            if (m2_bus_ready) begin
                m2_type = `DATA;
                if (size_m2 == `WORD_SIZE) write_m2 = 1;
                if (size_m2 == `QWORD_SIZE) write_q2 = 1;
            end
        end

        cnt = clk;

    end

endmodule