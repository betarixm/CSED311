`include "state_def.v"

module change_state(clk, reset_n, next_state, current_state);
    input clk;
    input reset_n;
    input next_state;
    output current_state;

    initial begin
        current_state <= `STATE_IF_1;
    end

    always @(posedge clk) begin
        if (!reset_n) begin
            current_state <= `STATE_IF_1;
        end
        else begin
            current_state <= next_state;
        end
    end
