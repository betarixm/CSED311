
`include "vending_machine_def.v"
`include "state_def.v"	

module calculate_current_state(i_input_coin,i_select_item,item_price,coin_value,current_total,
input_total, output_total, return_total, balance_total, current_total_nxt,wait_time,o_return_coin,o_available_item,o_output_item);


	
	input [`kNumCoins-1:0] i_input_coin,o_return_coin;
	input [`kNumItems-1:0]	i_select_item;			
	input [31:0] item_price [`kNumItems-1:0];
	input [31:0] coin_value [`kNumCoins-1:0];	
	input [`kTotalBits-1:0] current_total;
	input [31:0] wait_time;
	output reg [`kNumItems-1:0] o_available_item,o_output_item;
	output reg [`kTotalBits-1:0] input_total, output_total, return_total, current_total_nxt;
	output [`kTotalBits-1:0] balance_total;
	integer i;	

	initial begin
		input_total <= 0;
		output_total <= 0;
		return_total <= 0;
		current_total_nxt <= `STATE_INIT;
	end

	assign balance_total = input_total - output_total - return_total;

	
	// Combinational logic for the next states
	always @(i_input_coin or i_select_item) begin
		// TODO: current_total_nxt
		// You don't have to worry about concurrent activations in each input vector (or array).
		// Calculate the next current_total state.
		if(i_input_coin) begin
			current_total_nxt = `STATE_MONEY;
		end else if (i_select_item) begin
			current_total_nxt = `STATE_ITEM;
		end else begin
			current_total_nxt = `STATE_IDLE;
		end
	end

	
	
	// Combinational logic for the outputs
	always @(current_total or i_input_coin or o_return_coin or i_select_item) begin
		// o_available_item
		// o_output_item

		case(current_total)
			`STATE_INIT: begin
				input_total = 0;
				output_total = 0;
				return_total = 0;
			end

			`STATE_IDLE: begin
				o_available_item = `kNumItems'd0;
				for(i=0; i < `kNumItems; i = i + 1) begin
					if(item_price[i] <= balance_total) begin
						o_available_item[i] = 1;
					end

				end

				for(i=0; i < `kNumCoins; i = i + 1) begin
					if(o_return_coin[i] == 1) begin
						return_total = return_total + coin_value[i];
					end
				end
			end

			`STATE_MONEY: begin
				for(i=0; i < `kNumCoins; i = i + 1) begin
					if(i_input_coin[i] == 1) begin
						input_total = input_total + coin_value[i];
					end
				end
			end

			`STATE_ITEM: begin
				o_output_item = `kNumItems'd0;
				for(i = 0; i < `kNumItems; i = i + 1) begin
					if(i_select_item[i] == 1 && item_price[i] <= balance_total) begin
						o_output_item[i] = 1;
						output_total = output_total + item_price[i];
					end
				end
			end
		endcase
	end
 
	


endmodule 