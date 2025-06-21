/*
------------------------------------------------------------------------
File Name: imem.sv
SigmaCore Project: Instruction Memory Unit (ROM)
Author: Shahriar Rizvi

Performs: Implements a 32x32 instruction memory for RISC-V CPU

------------------------------------------------------------------------
*/


`timescale 1ns/1ps

module instruction_memory(
    
    input logic clk, 
    input logic [31:0] read_addr_in,

    output logic [31:0] instruction_out

);

localparam MEM_SIZE_WORDS = 1024;
localparam ADDR_WIDTH = $clog2(MEM_SIZE_WORDS);

logic [31:0] memory [0:MEM_SIZE_WORDS-1];


initial begin

    $display("IMEM: Initializing instruction memory from program.hex...");

    try begin
        $readmemh("program.hex", memory);
    end catch (e) begin
        $error("IMEM: Failed to read 'program.hex'");
    end

end


always_ff @(posedge clk) begin
    instruction_out <= memory[read_addr_in[ADDR_WIDTH-1:2]]; 
    // read_addr_in[11:2] would be the 10-bit word index for a 4KB memory.
    // This assumes the lower two bits [1:0] are always "00".
end

endmodule