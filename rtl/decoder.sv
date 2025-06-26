/*
---------------------------------------------------------------
File: decoder.sv
SigmaCore Project: Instruction Decoder
Author: Shahriar Rizvi
Performs: Decodes RISC-V instructions into control signals
---------------------------------------------------------------
*/

`timescale 1ns/1ps

module instruction_decoder(
    input  logic [31:0] instruction_in,

    output logic [6:0] opcode,
    output logic [4:0] rd,
    output logic [2:0] funct3,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [6:0] funct7
);

    // Opcode is in bits 6:0, defines the instruction type (all types)
    assign opcode = instruction_in[6:0];

    // Destination register (rd) is in bits 11:7
    assign rd = instruction_in[11:7];

    // funct3 is in bits 14:12, further specifies the operation for some opcodes
    assign funct3 = instruction_in[14:12];

    // Source register 1 (rs1) is in bits 19:15
    assign rs1 = instruction_in[19:15];

    // Source register 2 (rs2) is in bits 24:20
    assign rs2 = instruction_in[24:20];

    // funct7 is in bits 31:25, used with funct3 to specify R-type operations (e.g., ADD vs. SUB)
    assign funct7 = instruction_in[31:25];

endmodule