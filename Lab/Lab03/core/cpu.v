`include "opcodes.v"
`include "registers.v"

`include "alu.v" 	
`include "adder.v"
`include "sign_extender.v"
`include "register_file.v"
`include "pc_calculator.v"
`include "mux.v"   


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

	wire Instruction[15:0];

    wire ALUSrc;
    wire [3-1:0] ALUOp;
    wire RegWrite;
    wire MemRead;
    wire MemtoReg;
    wire MemWrite;
    wire PCtoReg;
    wire Jump;
    wire Branch;
	
	wire [`WORD_SIZE-1:0] ReadData1;
	wire [`WORD_SIZE-1:0] ReadData2;

	wire [`WORD_SIZE-1:0] WriteReg;
	wire [`WORD_SIZE-1:0] WriteData;
	wire [`WORD_SIZE-1:0] WriteDataValue;

	wire [`WORD_SIZE-1:0] WireSignExtendOut;
	wire [`WORD_SIZE-1:0] WireMuxALUOut;

	wire [`WORD_SIZE-1:0] WireALUOut;

	wire [`WORD_SIZE-1:0] ReadDataMemory;

	always @(posedge clk) begin
		PC <= RealNextPc;
	end

    instruction_memory InstructionMemory(.read_address(PC),
										.readM(readM),
										.instruction(Instruction),
										.clk(clk));

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
							.alu_src(ALUSrc), 
							.alu_op(ALUOp), 
							.reg_write(RegWrite), 
							.mem_read(MemRead), 
							.mem_to_reg(MemtoReg), 
							.mem_write(MemWrite), 
							.PCtoReg(PCtoReg), 
							.jp(Jump), 
							.branch(Branch));

	mux MuxWriteReg(.mux_input1(Instruction[7:6]),
					.mux_input2(`R2),
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
							.clk(clk));


	sign_extender SignExtend(.immediate(Instruction[`IMMD_SIZE-1:0]), 
							.sign_extended(WireSignExtendOut));

	mux MuxALU(.mux_input_1(ReadData2), 
				.mux_input_2(WireSignExtendOut), 
				.selector(ALUSrc), 
				.mux_output(WireMuxALUOut));

	alu ALU(.alu_input_1(ReadData1), 
			.alu_input_2(WireMuxALUOut), 
			.func_code(ALUOp), 
			.alu_output(WireALUOut));

	data_memory DataMemory(.address(WireALUOut),
						.write_data(ReadData2),
						.ackOutput(ackOutput),
						.inputReady(inputReady),
						.data(data),
						.readM(readM),
						.writeM(writeM),
						.address_out(address),
						.read_data(ReadDataMemory),
						.mem_write(MemWrite),
						.mem_read(MemRead),
						.clk(clk));

	mux MuxWriteDataValue(.mux_input_1(WireALUOut),
						.mux_input_2(ReadDataMemory),
						.selector(MemtoReg),
						.mux_output(WriteDataValue));

endmodule							  																		  