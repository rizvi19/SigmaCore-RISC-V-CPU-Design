// This is for sign extending the immediate value of the instruction
// The immediate value is 12 bits and it is sign extended to 32 bits

module sign_ext(
    input logic [24:0] imm_src,
    input logic [1:0] imm_type,

    output logic [31:0] imm_ext
);

import sigma_pkg::*; // Importing the package for better readability

logic [11:0] imm_collect;

always_comb begin
    case(imm_type)
        TYPE_I: imm_collect = imm_src[24:13]; // Immediate Type
        default: imm_collect = 12'b0;
    endcase
end

assign imm_ext = {20{imm_collect[11]}, imm_collect}; // Sign Extending the immediate value


endmodule