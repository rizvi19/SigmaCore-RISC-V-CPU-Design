/*
---------------------------------------------------------------------------------------------------
File: sign_ext.sv
SigmaCore Project: Sign Extender Unit
Author: Shahriar Rizvi
Performs: Sign extension of immediate values in RISC-V instructions

This module takes a 32-bit RISC-V instruction and an immediate type (defined in sigma_pkg),
extracts the appropriate immediate field, and sign-extends it to 32 bits.
---------------------------------------------------------------------------------------------------
*/



`timescale 1ns/1ps

module sign_extender (
    // Inputs
    input  logic [31:0] instruction_in, 
    input  logic [2:0]  imm_type_in,    // from sigma_pkg

    // Output
    output logic [31:0] imm_extended_out 
);

    import sigma_pkg::*;

    logic [31:0] imm_temp;

    always_comb begin
        imm_temp = 32'b0;

        case (imm_type_in)
            IMM_TYPE_I: begin
                // I-type immediate: instruction[31:20] (12 bits)
                // Sign bit is instruction[31]
                imm_temp = {{20{instruction_in[31]}}, instruction_in[31:20]};
            end

            IMM_TYPE_S: begin
                // S-type immediate: {instruction[31:25], instruction[11:7]} (12 bits)
                // Sign bit is instruction[31]
                imm_temp = {{20{instruction_in[31]}}, instruction_in[31:25], instruction_in[11:7]};
            end

            IMM_TYPE_B: begin
                // B-type immediate: {instruction[31](imm[12]), instruction[7](imm[11]), instruction[30:25](imm[10:5]), instruction[11:8](imm[4:1]), 1'b0 (imm[0])}
                // Sign bit for extension is instruction[31]. This forms a 13-bit value that is then sign-extended.
                imm_temp = {{19{instruction_in[31]}}, instruction_in[31], instruction_in[7], instruction_in[30:25], instruction_in[11:8], 1'b0};
            end

            IMM_TYPE_U: begin
                // U-type immediate: instruction[31:12] (20 bits)
                // Forms imm[31:12] by placing the 20-bit immediate in the upper bits and zeroing lower 12.
                imm_temp = {instruction_in[31:12], 12'b0};
            end

            IMM_TYPE_J: begin
                // J-type immediate: {instruction[31](imm[20]), instruction[19:12](imm[19:12]), instruction[20](imm[11]), instruction[30:21](imm[10:1]), 1'b0 (imm[0])}
                // Sign bit for extension is instruction[31]. This forms a 21-bit value that is then sign-extended.
                imm_temp = {{11{instruction_in[31]}}, instruction_in[31], instruction_in[19:12], instruction_in[20], instruction_in[30:21], 1'b0};
            end

            IMM_TYPE_NONE: begin
                imm_temp = 32'b0; // no immediate
            end

            default: begin
                imm_temp = 32'b0; 
            end
        endcase
    end

    assign imm_extended_out = imm_temp;

endmodule
