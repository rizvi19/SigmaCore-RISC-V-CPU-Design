// Arithmetic Logic Unit (ALU) module

`timescale 1ns/1ps

module alu(
    // Inputs
    input logic [31:0] operand1,
    input logic [31:0] operand2,
    input logic [3:0] alu_op, 

    // Outputs
    output logic [31:0] result,
    output logic zero_flag,
    output logic negative_flag,
    output logic overflow_flag,
    output logic carry_flag
);

import sigma_pkg::*; // Importing the package for better readability
// ALU Operation

always_comb begin
    case(alu_op)
        ALU_ADD: {carry_flag, result} = operand1 + operand2; // ADD
        ALU_SUB: {carry_flag, result} = operand1 + (~operand2 + 1'b1); // SUB using 2's complement
        ALU_AND: result = operand1 & operand2; // AND
        ALU_OR: result = operand1 | operand2; // OR
        ALU_XOR: result = operand1 ^ operand2; // XOR
        ALU_SLL: result = operand1 << operand2; // SLL
        ALU_SRL: result = operand1 >> operand2; // SRL
        ALU_SRA: result = $signed(operand1) >>> operand2; // SRA
        default: result = 32'b0; // Default case
    endcase
end

// Flags
assign zero_flag = (result == 32'b0);
assign negative_flag = result[31];


endmodule