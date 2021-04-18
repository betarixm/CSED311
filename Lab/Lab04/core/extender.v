`include "opcodes.v"

module sign_extender (immediate, sign_extended);
    input [`IMMD_SIZE-1:0] immediate;
    output [`WORD_SIZE-1:0] sign_extended;

    assign sign_extended = $signed(immediate);

endmodule