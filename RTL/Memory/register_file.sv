// Register File

// RISC-V Architecture simple Register File:

// 32 registers each 32bit size
// The Address will be in 5bit.

`timescale 1ns/1ps
module regfile(
    // Clock and Reset
    input logic clk,
    input logic reset,

    // Read
    input logic [4:0] read1_addr,
    input logic [4:0] read2_addr,
    output logic [31:0] read1_data,
    output logic [31:0] read2_data,

    // Write
    input logic [4:0] write_addr,
    input logic [31:0] write_data,
    input logic write_enable,
);


logic 