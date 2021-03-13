`include "vending_machine_def.v"
`include "state_def.v"

	

module check_time_and_coin(i_input_coin,i_select_item,i_trigger_return,coin_value,item_price,balance_total,clk,reset_n,wait_time,o_return_coin);
	input clk;
	input reset_n;
	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0]	i_select_item;
	input i_trigger_return;
	input [31:0] coin_value [`kNumCoins-1:0];	// Value of each coin
	input [31:0] item_price [`kNumItems-1:0];	// Price of each item
	input [`kTotalBits-1:0] balance_total;
	output reg  [`kNumCoins-1:0] o_return_coin;
	output reg [31:0] wait_time;
	integer i;

	// initiate values
	initial begin
		// initiate values
		wait_time <= `kWaitTime;
	end


	// update coin return time
	always @(i_input_coin, i_select_item) begin
		// for coin input
		for(i=0; i < `kNumCoins; i = i + 1) begin
			if(i_input_coin[i] == 1) begin
				wait_time = `kWaitTime;
			end
		end
		// for item input
		for(i=0; i < `kNumItems; i = i + 1) begin
			if(i_select_item[i] == 1 && item_price[i] <= balance_total) begin
				// needed to check if it's available
				wait_time = `kWaitTime;
			end
		end
	end

	always @(wait_time) begin
		// TODO: o_return_coin
		if (wait_time == 0 || i_trigger_return == 1) begin
			for(i=`kNumCoins-1; i>=0; i=i-1) begin
				if(coin_value[i] <= balance_total) begin
					o_return_coin[i] = 1;
				end
			end
		end
	end

	always @(posedge clk ) begin
		if (!reset_n) begin
			// TODO: reset all states.
			wait_time <= `kWaitTime;
			o_return_coin <= `kNumCoins'd0;
		end
		else begin
			// update all states.
			wait_time <= wait_time - 1;
		end
	end
endmodule 