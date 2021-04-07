`include "state_def.v"

module calculate_state(is_jwrite, is_wwd, is_halt, is_branch, is_load, is_store, is_itype, is_rtype, PVS_write_en, current_state, next_state);
    input is_jwrite, is_wwd, is_halt, is_branch, is_load, is_store, is_itype, is_rtype, PVS_write_en;
    
    input [`kStateBits-1:0] current_state;
    output [`kStateBits-1:0] next_state;

    initial begin
        next_state <= `STATE_IF_1;
    end

    always @(*) begin
        case(current_state)
            `STATE_IF_1: next_state = `STATE_IF_2;
            `STATE_IF_2: next_state = `STATE_IF_3;
            `STATE_IF_3: next_state = `STATE_IF_4;
            `STATE_IF_4: begin
                if (isJAL) begin
                    next_state = `STATE_EX_1;
                end
                else begin
                    next_state = `STATE_ID;
                end
            end
            `STATE_ID: next_state = `STATE_EX_1;
            `STATE_EX_1: next_state = `STATE_EX_2;
            `STATE_EX_2: begin
                if (is_branch & PVS_write_en) begin
                    next_state = `STATE_IF_1;
                end
                else if (is_itype | is_rtype | is_jwrite | is_wwd | is_halt) begin
                    next_state = `STATE_WB;
                end
                else if (is_load | is_store) begin
                    next_state = `STATE_MEM_1;
                end
            end
            `STATE_MEM_1: next_state = `STATE_MEM_2;
            `STATE_MEM_2: next_state = `STATE_MEM_3;
            `STATE_MEM_3: next_state = `STATE_MEM_4;
            `STATE_MEM_4: begin
                if (is_load) begin
                    next_state = `STATE_WB;
                end
                else if (is_store & PVS_write_en) begin
                    next_state = `STATE_IF_1;
                end
            end
            `STATE_WB: begin
                if (PVS_write_en) begin
                    next_state = `STATE_IF_1;
                end
            end
        endcase
    end