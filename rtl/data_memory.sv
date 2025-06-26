/*
------------------------------------------------------------------
File: data_memory.sv
SigmaCore Project: Data Memory Unit (RAM)
Author: Shahriar Rizvi
Performs: Implements a 1024x32 data memory for RISC-V CPU
------------------------------------------------------------------
*/


`timescale 1ns/1ps

module data_memory(
    input logic clk,
    input logic [31:0] addr_in,
    input logic [31:0] write_data_in,
    input logic write_enable,
    output logic read_enable,

    output logic [31:0] read_data_out
);


    localparam MEM_SIZE_WORDS = 1024; // 4KB of data memory (1024 words)
    localparam ADDR_WIDTH     = $clog2(MEM_SIZE_WORDS); // = 10 bits for 1024 words


    logic [31:0] memory [0:MEM_SIZE_WORDS-1];

    logic [ADDR_WIDTH-1:0] word_addr;

    assign word_addr = addr_in[ADDR_WIDTH+1:2];

    always_ff @(posedge clk) begin
        if (write_enable) begin
            memory[word_addr] <= write_data_in;
        end
    end


    always_ff @(posedge clk) begin
        if (read_enable) begin
            read_data_out <= memory[word_addr];
        end
    end

endmodule