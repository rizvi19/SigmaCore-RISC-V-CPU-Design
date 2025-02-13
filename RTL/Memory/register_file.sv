// Register File

// RISC-V Architecture simple Register File:

// 32 registers each 32bit size
// The Address will be in 5bit.

`timescale 1ns/1ps
module regfile(
    // Clock and Reset Ports
    input logic clk,
    input logic reset,

    // Read Ports
    input logic [4:0] read1_addr,
    input logic [4:0] read2_addr,
    output logic [31:0] read1_data,
    output logic [31:0] read2_data,

    // Write Ports
    input logic [4:0] write_addr,
    input logic [31:0] write_data,
    input logic write_enable,
);


// Packed Array declaration for 32bit x 32 registers
logic [31:0] registers [31:0]; 

// Write Operation
always @(posedge clk) begin
    if(reset == 1'b0) begin 
        for(int i=0; i<32; i++) begin
            registers[i] <= 32'b0;
        end
    end
    // x0 register is Zero Register and only can be 0, so it can't be written with another value
    else if(write_enable == 1'b1 && write_addr != 5'b0) begin
        registers[write_addr] <= write_data;
    end
end

// Read Operation
always_comb begin
    read1_data = registers[read1_addr];
    read2_data = registers[read2_addr];
end

endmodule

