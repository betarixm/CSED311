`timescale 1ns/1ns
`define WORD_SIZE 16 
`include "env.v"

// TODO: implement your external_device module
module external_device (clk, reset_n, intrpt, bg, addr_offset, qdata2, intrpt_resolved);

	input clk;
	input reset_n;

	output reg [1:0] intrpt;

	input bg;
	input [`WORD_SIZE-1:0] addr_offset;

	inout [`QWORD_SIZE-1:0] qdata2;

	input intrpt_resolved;

	reg [`QWORD_SIZE-1:0] o__data;
	reg [`WORD_SIZE-1:0] num_clk; // num_clk to count cycles and trigger interrupt at appropriate cycle
	reg [`WORD_SIZE-1:0] data [0:`WORD_SIZE-1]; // data to transfer

	assign qdata2 = (bg) ? (
		{data[addr_offset + 3], data[addr_offset + 2], data[addr_offset + 1], data[addr_offset + 0]}
	) : (`QWORD_SIZE'bz);

	always @(*) begin
		
	end

	always @(posedge clk) begin
		if(!reset_n) begin
			data[16'd0] <= 16'h0001;
			data[16'd1] <= 16'h0002;
			data[16'd2] <= 16'h0003;
			data[16'd3] <= 16'h0004;
			data[16'd4] <= 16'h0005;
			data[16'd5] <= 16'h0006;
			data[16'd6] <= 16'h0007;
			data[16'd7] <= 16'h0008;
			data[16'd8] <= 16'h0009;
			data[16'd9] <= 16'h000a;
			data[16'd10] <= 16'h000b;
			data[16'd11] <= 16'h000c;
			num_clk <= 0;
		end
		else begin
			num_clk <= num_clk+1;
			if(num_clk == 3000) begin
				intrpt <= `INST_DMA_BEGIN;
			end

			if(intrpt_resolved) begin
				intrpt <= 0;
			end
		end
	end
endmodule
