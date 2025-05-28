/* 
----------------------------------------------------------------------------
 File: alu.sv
 SigmaCore Project: Arithmetic Logic Unit (ALU) module
 Author: Shahriar Rizvi
 Performs: 32th bit Logical and Arithmetic Operations

 Inputs: 
 - operand1: First input data (32 bit)
 - operand2: Second input data (32 bit)
 - alu_op: ALU operation code (4 bits)

 Outputs:
 - result: Result of the ALU operation (32 bits)
 - zero_flag: 1 if result is zero, else 0
 - negative_flag: 1 if result is negative (when MSB is 1), else 0
 - overflow_flag: 1 if overflow occurs, else 0
 - carry_flag: 1 if carry occurs, else 0
 ---------------------------------------------------------------------------
*/



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

logic [32:0] ext_sum_sub; // Using For overflow detection, so that we can calculate the carry out 

// ALU Operation
always_comb begin
    logic [4:0] shift_temp;
    
    result        = 32'b0;
    carry_flag    = 1'b0; // default no carry = 0
    overflow_flag = 1'b0; // default no overflow = 0


    case(alu_op)
        ALU_ADD: begin
            ext_sum_sub = {1'b0, operand1} + {1'b0, operand2}; // Extending to 33 bits for carry detection
            result = ext_sum_sub[31:0]; // tking the lower 32 bits as rslt
            carry_flag = ext_sum_sub[32]; // The 33rd bit is the carry out

            // Overflow
            if (operand1[31] == operand2[31] && operand1[31] != result[31]) begin // 1 + 1 = 0 --> Overflow
                overflow_flag = 1'b1;
            end
        end

        ALU_SUB: begin
            ext_sum_sub = {1'b0, operand1} + {1'b0, ~operand2} + 33'd1; 
            result = ext_sum_sub[31:0]; // Taking the lower 32 bits as result
            carry_flag = ext_sum_sub[32]; // The 33rd bit is the carry out

            // Overflow
            if (operand1[31] != operand2[31] && operand1[31] != result[31]) begin // 1 - 1 = 0 --> Overflow
                overflow_flag = 1'b1;
            end
        end

        ALU_AND: result = operand1 & operand2; // AND

        ALU_OR: result = operand1 | operand2; // OR

        ALU_XOR: result = operand1 ^ operand2; // XOR

        // lower 5 bit shift (RISC-V standard)
        ALU_SLL: begin 
            shift_temp = operand2[4:0]; 
            result = operand1 << shift_temp; // SLL
        end

        ALU_SRL: begin
            shift_temp = operand2[4:0];
            result = operand1 >> shift_temp; // SRL
        end

        ALU_SRA: begin
            shift_temp = operand2[4:0];
            result = $signed(operand1) >>> shift_temp; // SRA
        end

        default: result = 32'b0; // Default case

    endcase
end

// Flags
assign zero_flag = (result == 32'b0);
assign negative_flag = result[31];


endmodule