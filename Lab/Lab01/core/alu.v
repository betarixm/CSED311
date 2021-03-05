`include "alu_func.v"

module ADD #(parameter data_width = 16) (
	input wire [data_width - 1 : 0] A, 
	input wire [data_width - 1 : 0] B, 
    output wire [data_width - 1 : 0] C,
    output OverflowFlag);

	assign C = A + B;

	assign OverflowFlag = (A[data_width - 1] == B[data_width - 1]) && (A[data_width - 1] != C[data_width - 1]);

endmodule

module SUB #(parameter data_width = 16) (
	input wire [data_width - 1 : 0] A, 
	input wire [data_width - 1 : 0] B, 
    output wire [data_width - 1 : 0] C,
    output OverflowFlag);

	assign C = A - B;

	assign OverflowFlag = (A[data_width - 1] != B[data_width - 1]) && (A[data_width - 1] != C[data_width - 1]);

endmodule

module ID #(parameter data_width = 16) (
	input wire [data_width - 1 : 0] A, 
    output wire [data_width - 1: 0] C);

	assign C = A;

endmodule

module NOT #(parameter data_width = 16) (
	input wire [data_width - 1 : 0] A, 
    output wire [data_width - 1: 0] C);

	assign C = ~A;

endmodule

module AND #(parameter data_width = 16) (
	input wire [data_width - 1 : 0] A, 
	input wire [data_width - 1 : 0] B, 
    output wire [data_width - 1: 0] C);

	assign C = A & B;

endmodule

module OR #(parameter data_width = 16) (
	input wire [data_width - 1 : 0] A, 
	input wire [data_width - 1 : 0] B, 
    output wire [data_width - 1: 0] C);

	assign C = A | B;

endmodule

module NAND #(parameter data_width = 16) (
	input wire [data_width - 1 : 0] A, 
	input wire [data_width - 1 : 0] B,
    output wire [data_width - 1 : 0] C);

	assign C = ~(A & B);

endmodule

module NOR #(parameter data_width = 16) (
	input wire [data_width - 1 : 0] A, 
	input wire [data_width - 1 : 0] B, 
    output wire [data_width - 1 : 0] C);

	assign C = ~(A | B);

endmodule

module XOR #(parameter data_width = 16) (
	input wire [data_width - 1 : 0] A, 
	input wire [data_width - 1 : 0] B, 
    output wire [data_width - 1 : 0] C);

	assign C = A ^ B;

endmodule

module XNOR #(parameter data_width = 16) (
	input wire [data_width - 1 : 0] A, 
	input wire [data_width - 1 : 0] B, 
    output wire [data_width - 1: 0] C);

	assign C = ~(A ^ B);

endmodule

module LLS #(parameter data_width = 16) (
	input wire [data_width - 1 : 0] A, 
    output wire [data_width - 1: 0] C);

	assign C = A << 1;

endmodule

module LRS #(parameter data_width = 16) (
	input wire [data_width - 1 : 0] A, 
    output wire [data_width - 1: 0] C);

	assign C = A >> 1;

endmodule

module ALS #(parameter data_width = 16) (
	input wire [data_width - 1 : 0] A, 
    output wire [data_width - 1: 0] C);

	assign C = A <<< 1;

endmodule

module ARS #(parameter data_width = 16) (
	input wire [data_width - 1 : 0] A, 
    output wire [data_width - 1: 0] C);

	// assign C = A >>> 1;
	assign C = {A[data_width - 1], A[data_width - 1:1]};

endmodule

module TCP #(parameter data_width = 16) (
	input wire [data_width - 1:0] A,  
    output wire [data_width - 1:0] C);

	assign C = ~A + 1;
	
endmodule

module ZERO #(parameter data_width = 16) (
    output wire [data_width - 1: 0] C);

	assign C = 0;

endmodule


module ALU #(parameter data_width = 16) (
	input [data_width - 1 : 0] A, 
	input [data_width - 1 : 0] B, 
	input [3 : 0] FuncCode,
    output reg [data_width - 1 : 0] C,
    output reg OverflowFlag);
// Do not use delay in your implementation.

// You can declare any variables as needed.
	wire [data_width - 1:0] wireOutADD;
	wire [data_width - 1:0] wireOutSUB;
	wire [data_width - 1:0] wireOutID;
	wire [data_width - 1:0] wireOutNOT;
	wire [data_width - 1:0] wireOutAND;
	wire [data_width - 1:0] wireOutOR;
	wire [data_width - 1:0] wireOutNAND;
	wire [data_width - 1:0] wireOutNOR;
	wire [data_width - 1:0] wireOutXOR;
	wire [data_width - 1:0] wireOutXNOR;
	wire [data_width - 1:0] wireOutLLS;
	wire [data_width - 1:0] wireOutLRS;
	wire [data_width - 1:0] wireOutALS;
	wire [data_width - 1:0] wireOutARS;
	wire [data_width - 1:0] wireOutTCP;
	wire [data_width - 1:0] wireOutZERO;

	wire wireOutAddOverflowFlag;
	wire wireOutSubOverflowFlag;

	ADD Add(A, B, wireOutADD, wireOutAddOverflowFlag);
	SUB Sub(A, B, wireOutSUB, wireOutSubOverflowFlag);
	ID Id(A, wireOutID);
	NOT Not(A, wireOutNOT);
	AND And(A, B, wireOutAND);
	OR Or(A, B, wireOutOR);
	NAND Nand(A, B, wireOutNAND);
	NOR Nor(A, B, wireOutNOR);
	XOR Xor(A, B, wireOutXOR);
	XNOR Xnor(A, B, wireOutXNOR);
	LLS Lls(A, wireOutLLS);
	LRS Lrs(A, wireOutLRS);   
	ALS Als(A, wireOutALS);
	ARS Ars(A, wireOutARS);
	TCP Tcp(A, wireOutTCP);
	ZERO Zero(wireOutZERO);

	initial begin
		C = 0;
		OverflowFlag = 0;
	end   	

// TODO: You should implement the functionality of ALU!
// (HINT: Use 'always @(...) begin ... end')

	always @(FuncCode or A or B) begin
		OverflowFlag = 0;
		case(FuncCode)
			`FUNC_ADD: begin
				C = wireOutADD;
				OverflowFlag = wireOutAddOverflowFlag;
			end

			`FUNC_SUB: begin
				C = wireOutSUB;
				OverflowFlag = wireOutSubOverflowFlag;
			end

			`FUNC_ID: begin
				C = wireOutID;
			end

			`FUNC_NOT: begin
				C = wireOutNOT;
			end

			`FUNC_AND: begin
				C = wireOutAND;
			end

			`FUNC_OR: begin
				C = wireOutOR;	
			end

			`FUNC_NAND: begin
				C = wireOutNAND;	
			end

			`FUNC_NOR: begin
				C = wireOutNOR;	
			end

			`FUNC_XOR: begin
				C = wireOutXOR;	
			end

			`FUNC_XNOR: begin
				C = wireOutXNOR;
			end

			`FUNC_LLS: begin
				C = wireOutLLS;
			end

			`FUNC_LRS: begin
				C = wireOutLRS;
			end

			`FUNC_ALS: begin
				C = wireOutALS;
			end

			`FUNC_ARS: begin
				C = wireOutARS;	
			end

			`FUNC_TCP: begin
				C = wireOutTCP;
			end

			`FUNC_ZERO: begin
				C = wireOutZERO;
			end
		endcase
	end

endmodule
