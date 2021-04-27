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


	/////////////////////////////////
	//    PIPELINE REGISTERS       //

	// from IF/ID
	reg [`WORD_SIZE-1:0] r__if_id__instruction;
	reg [`WORD_SIZE-1:0] r__if_id__pc, r__id_ex__pc;
	
	// from ID/EX
	reg [`WORD_SIZE-1:0] r__id_ex__read_data_1;
	reg [`WORD_SIZE-1:0] r__id_ex__read_data_2;
	reg [`WORD_SIZE-1:0] r__id_ex__imm_ext;
	reg [`WORD_SIZE-1:0] r__id_ex__funccode;
	reg [`WORD_SIZE-1:0] r__id_ex__opcode;
	reg [`WORD_SIZE-1:0] r__id_ex__rd, r__ex_mem__rd, r__mem_wb__rd;
	reg [`WORD_SIZE-1:0] r__id_ex__rt, r__ex_mem__rt, r__mem_wb__rt;
	reg rc__id_ex__mem_read, rc__ex_mem__mem_read;
	reg rc__id_ex__mem_write, rc__ex_mem__mem_write;
	reg rc__id_ex__reg_write, rc__ex_mem__reg_write, rc__mem_wb__reg_write;
	reg rc__id_ex__mem_to_reg, rc__ex_mem__mem_to_reg, rc__mem_wb__mem_to_reg;
	reg rc__id_ex__pc_to_reg, rc__ex_mem__pc_to_reg, rc__mem_wb__pc_to_reg;
	reg [1:0] rc__id_ex__alu_src_A;
	reg [1:0] rc__id_ex__alu_src_B;
	reg [1:0] rc__id_ex__alu_op;
	reg [1:0] rc__id_ex__reg_write_dest, rc__ex_mem__reg_write_dest, rc__mem_wb__reg_write_dest;

	// from EX/MEM
	reg [`WORD_SIZE-1:0] r__ex_mem__alu_out;
	
	// form MEM/WB
	reg [`WORD_SIZE-1:0] r__mem_wb__memory_read_data;
	
	//    PIPELINE REGISTERS END   //
	/////////////////////////////////





	


	initial begin
		PC <= 0;
	end
	
	always @(*) begin
		if (reset_n) begin
			PC <= 0;
		end
	end

	always @(posedge clk) begin
		///////////////////////////////
		// update Pipeline Registers
		// - MEM/WB
		r__mem_wb__memory_read_data <= w__;
		r__mem_wb__rd <= r__ex_mem__rd;
		r__mem_wb__rt <= r__ex_mem__rt;
		rc__mem_wb__reg_write <= rc__ex_mem__reg_write;
		rc__mem_wb__reg_write_dest <= rc__ex_mem__reg_write_dest;
		// - EX/MEM
		r__ex_mem__alu_out <= w__;
		r__ex_mem__rd <= r__id_ex__rd;
		r__ex_mem__rt <= r__id_ex__rt;
		rc__ex_mem__mem_read <= rc__id_ex__mem_read;
		rc__ex_mem__mem_write <= rc__id_ex__mem_write;
		rc__ex_mem__mem_to_reg <= rc__id_ex__mem_to_reg;
		rc__ex_mem__pc_to_reg <= rc__id_ex__pc_to_reg;
		rc__ex_mem__reg_write <= rc__id_ex__reg_write;
		rc__ex_mem__reg_write_dest <= rc__id_ex__reg_write_dest;
		// - ID/EX
		r__id_ex__read_data_1 <= w__;
		r__id_ex__read_data_2 <= w__;
		r__id_ex__imm_ext <= w__;
		r__id_ex__funccode <= ;
		r__id_ex__opcode <= ;
		r__id_ex__rd <= ;
		r__id_ex__rt <= ;
		r__id_ex__pc <= r__if_id__pc;
		rc__id_ex__alu_src_A <= c__alu_src_A;
		rc__id_ex__alu_src_B <= c__alu_src_B;
		rc__id_ex__alu_op <= c__alu_op;
		rc__id_ex__mem_read <= c__mem_read;
		rc__id_ex__mem_write <= c__mem_write;
		rc__id_ex__mem_to_reg <= c__mem_to_reg; 
		rc__id_ex__pc_to_reg <= c__pc_to_reg;
		rc__id_ex__reg_write <= c__reg_write;
		rc__id_ex__reg_write_dest <= c__reg_write_dest;
		// - IF/ID
		r__if_id__instruction <= ;
		r__if_id__pc <= ;
	end


endmodule


