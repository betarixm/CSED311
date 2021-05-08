`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

`include "env.v"
`include "util.v"
`include "alu.v"
`include "register_file.v"
`include "control_unit.v"
`include "alu_control_unit.v"
`include "memory.v"
`include "datapath.v"
`include "branch_calculator.v"
`include "branch_cond_checker.v"


module cpu(clk, reset_n, read_m1, address1, data1, read_m2, write_m2, address2, data2, num_inst, output_port, is_halted);

    input clk;
    input reset_n;

    output read_m1;
    output [`WORD_SIZE-1:0] address1;
    output read_m2;
    output write_m2;
    output [`WORD_SIZE-1:0] address2;

    input [`WORD_SIZE-1:0] data1;
    inout [`WORD_SIZE-1:0] data2;

    output [`WORD_SIZE-1:0] num_inst;
    output [`WORD_SIZE-1:0] output_port;
    output is_halted;

    ///////////////////////////////////////////////////

    //# Wires
    //## Control
    wire c__alu_src;
    wire c__mem_read;
    wire c__mem_write;
    wire c__mem_to_reg;
    wire c__reg_write;
    wire [1:0] c__reg_write_dest;
    wire c__halt;
    wire c__wwd;
    wire c__pc_to_reg;
    wire c__new_inst;

    //## WB/MEM
    wire [`WORD_SIZE-1:0] w__addr__pc;
    wire [`WORD_SIZE-1:0] w__pc__mux;
    wire [`WORD_SIZE-1:0] w__aout__mux;
    wire [`WORD_SIZE-1:0] w__mux__memory;
    wire [`WORD_SIZE-1:0] w__data;

    //## MEM/IF
    wire [`WORD_SIZE-1:0] w__memory__inst;
    wire [`WORD_SIZE-1:0] w__memory__r_memory_register;

    //## IF/ID
    wire [`WORD_SIZE-1:0] w__inst_ext;

    //## ID/EX
    wire [`WORD_SIZE-1:0] w__imm_ext;
    wire [`WORD_SIZE-1:0] w__read_data_1;
    wire [`WORD_SIZE-1:0] w__read_data_2;
    wire [`REG_SIZE-1:0] w__write_reg;
    wire [`WORD_SIZE-1:0] w__mux__write_data;
    wire [`WORD_SIZE-1:0] w__alu_a;
    wire [`WORD_SIZE-1:0] w__alu_b;
    wire [`WORD_SIZE-1:0] w__mux_alu_src_b;
    wire [`WORD_SIZE-1:0] w__func_code;
    wire [2-1:0] w__branch_type;
    wire w__bcond;
    wire w__branch_address;

    //## EX/MEM
    wire w__overflow_flag;
    wire [`WORD_SIZE-1:0] w__mux__pc;
    wire [`WORD_SIZE-1:0] w__alu_out;

    //## MEM/WB
    wire [`WORD_SIZE-1:0] w__write_data;

    //# Registers
    reg [`WORD_SIZE-1:0] r__pc;
    reg [`WORD_SIZE-1:0] r__next_pc;
    reg [`WORD_SIZE-1:0] r__memory_register;
    reg [`WORD_SIZE-1:0] r__read_data_1;
    reg [`WORD_SIZE-1:0] r__read_data_2;
    reg [`WORD_SIZE-1:0] r__inst;
    reg [`WORD_SIZE-1:0] r__num_inst;

    /////////////////////////////////
    //    PIPELINE REGISTERS       //

    // from IF/ID
    reg [`WORD_SIZE-1:0] r__if_id__inst;
    reg [`WORD_SIZE-1:0] r__if_id__pc, r__id_ex__pc;
    reg [`WORD_SIZE-1:0] r__if_id__next_pc, r__id_ex__next_pc;
    
    // from ID/EX
    reg [`WORD_SIZE-1:0] r__id_ex__read_data_1, r__ex_mem__read_data_1, r__mem_wb__read_data_1; // for wwd
    reg [`WORD_SIZE-1:0] r__id_ex__read_data_2;
    reg [`WORD_SIZE-1:0] r__id_ex__mux_alu_src_b, r__ex_mem__mux_alu_src_b;
    reg [`WORD_SIZE-1:0] r__id_ex__imm_ext;
    reg [`WORD_SIZE-1:0] r__id_ex__opcode;
    reg [`WORD_SIZE-1:0] r__id_ex__funct;
    reg [`WORD_SIZE-1:0] r__id_ex__func_code;
    reg [`WORD_SIZE-1:0] r__id_ex__rd, r__ex_mem__rd, r__mem_wb__rd;
    reg [`WORD_SIZE-1:0] r__id_ex__rt, r__ex_mem__rt, r__mem_wb__rt;
    reg rc__id_ex__halt, rc__ex_mem__halt, rc__mem_wb__halt;
    reg rc__id_ex__wwd, rc__ex_mem__wwd, rc__mem_wb__wwd;
    reg rc__id_ex__alu_src;
    reg rc__id_ex__mem_read, rc__ex_mem__mem_read;
    reg rc__id_ex__mem_write, rc__ex_mem__mem_write;
    reg rc__id_ex__reg_write, rc__ex_mem__reg_write, rc__mem_wb__reg_write;
    reg rc__id_ex__mem_to_reg, rc__ex_mem__mem_to_reg, rc__mem_wb__mem_to_reg;
    reg rc__id_ex__pc_to_reg, rc__ex_mem__pc_to_reg, rc__mem_wb__pc_to_reg;
    reg [1:0] rc__id_ex__reg_write_dest, rc__ex_mem__reg_write_dest, rc__mem_wb__reg_write_dest;

    // from EX/MEM
    reg [`WORD_SIZE-1:0] r__ex_mem__alu_out;
    
    // form MEM/WB
    reg [`WORD_SIZE-1:0] r__mem_wb__memory_read_data;
    
    //    PIPELINE REGISTERS END   //
    /////////////////////////////////



    // TODO: manage halt -> doing with halt pipeline register
    // TODO: link output_port -> doing with wwd, read_data_1 pipeline register

    assign num_inst = r__num_inst;

    initial begin
        r__pc <= 0;
        r__num_inst <= 0;
    end
    
    always @(*) begin
        if (reset_n) begin
            r__pc <= 0;
            r__num_inst <= 0;
        end
    end


    ////////// IF ///////////

    /// Memory ///
    /// Instruction memory is concatenated to Data memory
    /// See bottom, MEM stage.

    adder Adder(
        .i1(r__pc),
        .i2(`WORD_SIZE'1),
        .o(r__next_pc)
    );

    // TODO: add mux for pc


    ////////// ID ///////////

    mux4_1_reg mux__write_reg(
        .sel(c__reg_write_dest),
        .i1(r__if_id__inst[`RD]),
        .i2(r__if_id__inst[`RT]),
        .i3(`REG_SIZE'd2),
        .i4(`REG_SIZE'd0),
        .o(w__write_reg)
    );

    mux2_1 mux__reg_data(
        .sel(c__pc_to_reg),
        .i1(w__write_data),
        .i2(r__if_id__next_pc),
        .o(w__mux__write_data)
    );

    register_file Registers(
        .read1(r__if_id__inst[`RS]),
        .read2(r__if_id__inst[`RT]),
        .write_reg(w__write_reg),
        .write_data(w__mux__write_data),
        .reg_write(c__reg_write),
        .clk(clk),
        .read_out1(w__read_data_1),
        .read_out2(w__read_data_2)
    );

    control_unit Control(
        .opcode(r__if_id__inst[`OPCODE]),
        .funct(r__if_id__inst[`FUNC]),
        .clk(clk),
        .reset_n(reset_n),
        .alu_src(c__alu_src),
        .mem_read(c__mem_read),
        .mem_to_reg(c__mem_to_reg),
        .mem_write(c__mem_write),
        .pc_to_reg(c__pc_to_reg),
        .pc_src(c__pc_source),
        .halt(c__halt),
        .wwd(c__wwd),
        .reg_write(c__reg_write),
        .reg_write_dest(c__reg_write_dest),
        .func_code(w__func_code),
        .branch_type(w__branch_type),
    );

    sign_extender Imm_extend(
        .immediate(r__if_id__inst[`IMMD_SIZE-1:0]),
        .sign_extended(w__imm_ext)
    );

    // TODO: hazard detection unit


    branch_cond_checker Branch_Cond_Checker(
        .A(w__read_data_1),
        .B(w__read_data_2),
        .branch_type(w__branch_type),
        .bcond(w__bcond),
    );
    
    branch_calculator Branch_Calculator(
        .A(w__read_data_1),
        .B(w__read_data_2),
        .C(w__branch_address),
    );

    // TODO: flush mux


    ////////////// EX ////////////////

    // TODO : edit mux input for forwarding

    mux2_1 mux__alu_a(
        .sel(),
        .i1(),
        .i2(r__read_data_1),
        .o(w__alu_a)
    );

    mux4_1 mux__alu_b(
        .sel(),
        .i1(r__read_data_2),
        .i2(),
        .i3(),
        .i4(),
        .o(w__alu_b)
    );

    mux MuxALU(
        .sel(rc__id_ex__alu_src),
        .i1(w__read_data_2),
        .i2(w__imm_ext),
        .o(w__mux_alu_src_b)
    );

    alu ALU(
        .A(w__alu_a), 
        .B(w__mux_alu_src_b), 
        .func_code(r__id_ex__func_code),
        .C(w__alu_out), 
        .overflow_flag(w__overflow_flag)
    );


    ////////////// MEM ////////////////

    Memory memory(
        .clk(clk),
        .reset_n(reset_n),
        .read_m1(~is_flush),
        .address1(r__pc),
        .data1(r__inst),
        .read_m2(rc__ex_mem__mem_read),
        .write_m2(rc__ex_mem__mem_write),
        .address2(r__ex_mem__alu_out),
        .data2(w__data)
    );

    assign w__data = (rc__ex_mem__mem_write) ? r__read_data_2 : `WORD_SIZE'bz;


    /////////////// WB ////////////////
    mux2_1 mux__alu_out__reg_memory(
        .sel(c__mem_to_reg),
        .i1(r__alu_out),
        .i2(r__memory_register),
        .o(w__write_data)
    );	



    always @(posedge clk) begin
        ///////////////////////////////
        // update Pipeline Registers
        // - MEM/WB
        r__mem_wb__memory_read_data <= w__data;
        r__mem_wb__rd <= r__ex_mem__rd;
        r__mem_wb__rt <= r__ex_mem__rt;
        r__mem_wb__read_data_1 <= r__ex_mem__read_data_1;
        rc__mem_wb__reg_write <= rc__ex_mem__reg_write;
        rc__mem_wb__reg_write_dest <= rc__ex_mem__reg_write_dest;
        // - EX/MEM
        r__ex_mem__alu_out <= w__alu_out;
        
        r__ex_mem__rd <= r__id_ex__rd;
        r__ex_mem__rt <= r__id_ex__rt;
        r__ex_mem__read_data_1 <= r__id_ex__read_data_1;
        r__ex_mem__mux_alu_src_b <= r__id_ex__mux_alu_src_b;
        rc__ex_mem__mem_read <= rc__id_ex__mem_read;
        rc__ex_mem__mem_write <= rc__id_ex__mem_write;
        rc__ex_mem__mem_to_reg <= rc__id_ex__mem_to_reg;
        rc__ex_mem__pc_to_reg <= rc__id_ex__pc_to_reg;
        rc__ex_mem__reg_write <= rc__id_ex__reg_write;
        rc__ex_mem__reg_write_dest <= rc__id_ex__reg_write_dest;
        // - ID/EX
        r__id_ex__read_data_1 <= w__read_data_1;
        r__id_ex__read_data_2 <= w__read_data_2;
        r__id_ex__mux_alu_src_b <= w__mux_alu_src_b;
        r__id_ex__imm_ext <= w__imm_ext;
        r__id_ex__func_code <= w__func_code;
        r__id_ex__rd <= r__if_id__inst[`RD];
        r__id_ex__rt <= r__if_id__inst[`RT];
        r__id_ex__pc <= r__if_id__pc;
        r__id_ex__next_pc <= r__if_id__next_pc;
        rc__id_ex__alu_src <= c__alu_src;
        rc__id_ex__mem_read <= c__mem_read;
        rc__id_ex__mem_write <= c__mem_write;
        rc__id_ex__mem_to_reg <= c__mem_to_reg; 
        rc__id_ex__pc_to_reg <= c__pc_to_reg;
        rc__id_ex__reg_write <= c__reg_write;
        rc__id_ex__reg_write_dest <= c__reg_write_dest;
        // - IF/ID
        r__if_id__inst <= r__inst;
        r__if_id__pc <= r__pc;
        r__if_id__next_pc <= r__next_pc;
    end


endmodule


