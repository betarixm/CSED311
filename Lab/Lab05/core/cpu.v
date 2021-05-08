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

	///////////////////////////////////////////////////

	//# Wires
	//## Control
	wire c__pc_write_cond;
	wire c__pc_write;
	wire c__i_or_d;
	wire c__mem_read;
	wire c__mem_write;
	wire c__mem_to_reg;
	wire c__ir_write;
	wire c__pc_source;
	wire [1:0] c__alu_op;
	wire [1:0] c__alu_src_a;
	wire [1:0] c__alu_src_b;
	wire c__reg_write;
	wire [1:0] c__reg_write_dest;
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
	wire [`WORD_SIZE-1:0] w__immext__mux;
	wire [`WORD_SIZE-1:0] w__read_data_1;
	wire [`WORD_SIZE-1:0] w__read_data_2;
	wire [`REG_SIZE-1:0] w__write_reg;
	wire [`WORD_SIZE-1:0] w__mux__write_data;
	wire [`WORD_SIZE-1:0] w__alu_a;
	wire [`WORD_SIZE-1:0] w__alu_b;

	//## EX/MEM
	wire w__bcond;
	wire w__overflow_flag;
	wire [`WORD_SIZE-1:0] w__mux__pc;
	wire [`WORD_SIZE-1:0] w__alu_result;

	//## MEM/WB
	wire [`WORD_SIZE-1:0] w__write_data;
    wire [4-1:0] w__alu__func_code;
    wire [2-1:0] w__alu__branch_type;

	//# Registers
	reg [`WORD_SIZE-1:0] r__pc;
	reg [`WORD_SIZE-1:0] r__memory_register;
	reg [`WORD_SIZE-1:0] r__read_data_1;
	reg [`WORD_SIZE-1:0] r__read_data_2;
	reg [`WORD_SIZE-1:0] r__alu_out;
	reg [`WORD_SIZE-1:0] r__inst;
	reg [`WORD_SIZE-1:0] r__num_inst;

	reg [`WORD_SIZE-1:0] r__const_0;
	reg [`WORD_SIZE-1:0] r__const_1;

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



	// TODO: manage halt
	// TODO: link output_port

	assign num_inst = r__num_inst;

	initial begin
		r__const_0 <= 0;
		r__const_1 <= 1;

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

	// TODO: check for new memory input & output
	memory Memory(
		.clk(clk),
		.reset_n(reset_n),
		.read_m(c__mem_read),
		.write_m(c__mem_write),
		.address(w__mux__memory),
		.data(w__data)
	);

	// TODO: add pc+1 adder

	// TODO: add mux for pc


	////////// ID ///////////

	mux4_1_reg mux__write_reg(
		.sel(c__reg_write_dest),
		.i1(r__inst[`RD]),
		.i2(r__inst[`RT]),
		.i3(`REG_SIZE'd2),
		.i4(`REG_SIZE'd0),
		.o(w__write_reg)
	);

	mux2_1 mux__reg_data(
		.sel(c__pc_to_reg),
		.i1(w__write_data),
		.i2(r__pc + `WORD_SIZE'b1),
		.o(w__mux__write_data)
	);

	register_file Registers(
		.read1(r__inst[`RS]),
		.read2(r__inst[`RT]),
		.write_reg(w__write_reg),
		.write_data(w__mux__write_data),
		.reg_write(c__reg_write),
		.pvs_write_en(c__pvs_write_en),
		.clk(clk),
		.read_out1(w__read_data_1),
		.read_out2(w__read_data_2)
	);

	control_unit Control(
		.opcode(r__inst[`OPCODE]),
		.func_code(r__inst[`FUNC]),
		.clk(clk),
		.reset_n(reset_n),
		.pc_write_cond(c__pc_write_cond),
		.pc_write(c__pc_write),
		.i_or_d(c__i_or_d),
		.mem_read(c__mem_read),
		.mem_to_reg(c__mem_to_reg),
		.mem_write(c__mem_write),
		.ir_write(c__ir_write),
		.pc_to_reg(c__pc_to_reg),
		.pc_src(c__pc_source),
		.halt(is_halted),
		.wwd(c__wwd),
		.new_inst(c__new_inst),
		.reg_write(c__reg_write),
		.reg_write_dest(c__reg_write_dest),
		.alu_src_A(c__alu_src_a),
		.alu_src_B(c__alu_src_b),
		.alu_op(c__alu_op),
		.pvs_write_en(c__pvs_write_en),
		.bcond(w__bcond)
	);

	sign_extender Imm_extend(
		.immediate(r__inst[`IMMD_SIZE-1:0]),
		.sign_extended(w__immext__mux)
	);

	// TODO: hazard detection unit

	// TODO: bcond calculation unit
	
	// TODO: branch address calculation unit

	// TODO: flush mux


	////////////// EX ////////////////

	// TODO : edit mux input for forwarding

	mux2_1 mux__alu_a(
		.sel(c__alu_src_a[0]),
		.i1(),
		.i2(r__read_data_1),
		.o(w__alu_a)
	);

	mux4_1 mux__alu_b(
		.sel(c__alu_src_b),
		.i1(r__read_data_2),
		.i2(),
		.i3(),
		.i4(),
		.o(w__alu_b)
	);

	alu_control_unit ALU_control(
		.funct(r__inst[`FUNC]),
		.opcode(r__inst[`OPCODE]),
		.ALUOp(c__alu_op), 
		.clk(clk), 
		.funcCode(w__alu__func_code),
		.branchType(w__alu__branch_type)
	);

	alu ALU(
		.A(w__alu_a), 
		.B(w__alu_b), 
		.func_code(w__alu__func_code), 
		.branch_type(w__alu__branch_type), 
		.C(w__alu_result), 
		.overflow_flag(w__overflow_flag), 
		.bcond(w__bcond));


	////////////// MEM ////////////////

	// TODO: check for new memory input output
	memory Memory(
		.clk(clk),
		.reset_n(reset_n),
		.read_m(c__mem_read),
		.write_m(c__mem_write),
		.address(),
		.data(w__data)
	);


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


