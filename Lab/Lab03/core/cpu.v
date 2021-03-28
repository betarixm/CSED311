`include "opcodes.v"
`include "registers.v"

`include "alu.v" 	
`include "adder.v"
`include "sign_extender.v"
`include "register_file.v"
`include "pc_calculator.v"
`include "mux.v"   
`include "branch_controller.v"
`include "instruction_memory.v"
`include "data_memory.v"
`include "memory_io.v"


module cpu (readM, writeM, address, data, ackOutput, inputReady, reset_n, clk);
	output readM;									
	output writeM;								
	output [`WORD_SIZE-1:0] address;	
	inout [`WORD_SIZE-1:0] data;		
	input ackOutput;								
	input inputReady;								
	input reset_n;									
	input clk;			

	reg [`WORD_SIZE-1:0] PC;
	wire [`WORD_SIZE-1:0] NextPC;
	wire [`WORD_SIZE-1:0] RealNextPC;

	wire [15:0] Instruction;

	wire RTDest;
    wire ALUSrc;
    wire [3-1:0] ALUOp;
    wire RegWrite;
    wire MemRead;
    wire MemtoReg;
    wire MemWrite;
    wire PCtoReg;
    wire Jump;
    wire Branch;
	wire BranchCond;
	
	wire [`WORD_SIZE-1:0] ReadData1;
	wire [`WORD_SIZE-1:0] ReadData2;

	wire [`WORD_SIZE-1:0] WriteReg;
	wire [`WORD_SIZE-1:0] WriteRegTemp;
	wire [`WORD_SIZE-1:0] WriteData;
	wire [`WORD_SIZE-1:0] WriteDataValue;

	wire [`WORD_SIZE-1:0] WireSignExtendOut;
	wire [`WORD_SIZE-1:0] WireMuxALUOut;

	wire [`WORD_SIZE-1:0] WireALUOut;

	wire [`WORD_SIZE-1:0] ReadDataMemory;

	wire [`WORD_SIZE-1:0] WireALUSubOut;

	wire SigFetch, SigRead, SigWrite;

	wire [`WORD_SIZE-1:0] DataWrite;
	wire [`WORD_SIZE-1:0] DataOut;
	wire [`WORD_SIZE-1:0] DataAddress;

	wire [`WORD_SIZE-1:0] FetchAddress;

	reg [`WORD_SIZE-1:0] R2;

	integer pass;

	initial begin
		PC <= 0;
		R2 <= `R2;
		pass <= 0;
	end

	always @(*) begin
		if (reset_n) begin
			PC <= 0;
			pass <= 0;
		end
	end

	always @(posedge clk) begin
		if (pass == 0) begin
			pass = 1;
			PC <= 0;
		end
		else if (SigFetch != 1) begin
			PC <= RealNextPC;
		end
	end

    instruction_memory InstructionMemory(.data(DataOut),
										.input_ready(inputReady),
										.mem_read(MemRead),
										.mem_write(MemWrite),
										.address_in(PC),
										.address_out(FetchAddress),
										.sig_fetch(SigFetch),
										.instruction(Instruction),
										.clk(clk),
										.reset_n(reset_n));

    pc_calculator PCCalculator(.pc(PC),
							.branch_cond(BranchCond),
							.branch(Branch),
							.jump(Jump),
							.sign_extended(WireSignExtendOut),
							.target_offset(Instruction[`ADDR_SIZE-1:0]),
							.write_pc_reg(ReadData1),
							.next_pc(NextPC),
							.real_next_pc(RealNextPC));


	control_unit MainControl(.instr(Instruction), 
							.rt_dest(RTDest),
							.alu_src(ALUSrc), 
							.alu_op(ALUOp), 
							.reg_write(RegWrite), 
							.mem_read(MemRead), 
							.mem_to_reg(MemtoReg), 
							.mem_write(MemWrite), 
							.PCtoReg(PCtoReg), 
							.jp(Jump), 
							.branch(Branch));

	mux MuxWriteRegRT(.mux_input_1({14'd0, Instruction[7:6]}),
					.mux_input_2({14'd0, Instruction[9:8]}),
					.selector(RTDest),
					.mux_output(WriteRegTemp));

	mux MuxWriteReg(.mux_input_1(WriteRegTemp),
					.mux_input_2(R2),
					.selector(PCtoReg),
					.mux_output(WriteReg));

	mux MuxWriteData(.mux_input_1(WriteDataValue),
					.mux_input_2(NextPC),
					.selector(PCtoReg),
					.mux_output(WriteData));

	register_file Registers(.read_out1(ReadData1), 
							.read_out2(ReadData2), 
							.read1(Instruction[11:10]), 
							.read2(Instruction[9:8]), 
							.write_reg(WriteReg), 
							.write_data(WriteData), 
							.reg_write(RegWrite), 
							.clk(clk),
							.reset_n(reset_n));


	sign_extender SignExtend(.immediate(Instruction[`IMMD_SIZE-1:0]), 
							.sign_extended(WireSignExtendOut));

	mux MuxALU(.mux_input_1(ReadData2), 
				.mux_input_2(WireSignExtendOut), 
				.selector(ALUSrc), 
				.mux_output(WireMuxALUOut));

	alu ALU(.alu_input_1(ReadData1), 
			.alu_input_2(WireMuxALUOut), 
			.func_code(ALUOp), 
			.alu_output(WireALUOut),
			.sub_output(WireALUSubOut));
	
	branch_controller BranchController(.sub_input(WireALUSubOut),
										.opcode(Instruction[`WORD_SIZE-1:`WORD_SIZE-4]),
										.is_branch(BranchCond));

	data_memory DataMemory(.read_data(DataOut),
							.write_data(ReadData2),
							.mem_read(MemRead),
							.mem_write(MemWrite),
							.input_ready(inputReady),
							.ack_output(ackOutput),
							.address_in(WireALUOut),
							.address_out(DataAddress),
							.sig_read(SigRead),
							.sig_write(SigWrite),
							.read_data_out(ReadDataMemory),
							.write_data_out(DataWrite),
							.clk(clk),
							.reset_n(reset_n));


	mux MuxWriteDataValue(.mux_input_1(WireALUOut),
						.mux_input_2(ReadDataMemory),
						.selector(MemtoReg),
						.mux_output(WriteDataValue));

	memory_io MemoryIO (
		.data(data),
		.sig_fetch(SigFetch),
		.sig_read(SigRead),
		.sig_write(SigWrite),
		.data_write(DataWrite),
		.input_ready(inputReady),
		.address_data_in(DataAddress),
		.address_fetch_in(FetchAddress),
		.address_out(address),
		.read_m(readM),
		.write_m(writeM),
		.data_out(DataOut),
		.clk(clk)
	);

endmodule							  																		  