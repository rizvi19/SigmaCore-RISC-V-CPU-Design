// SRAM 
// 32 bit Data Width
// 128 Words
// 7 bit Address Width

`timescale 1ns/1ps

module sram(
    // Clock and Reset Ports
    input logic clk,
    input logic reset,

    // Read Ports
    input logic [6:0] read1_addr,
    input logic [6:0] read2_addr,
    output logic [31:0] read1_data,
    output logic [31:0] read2_data,


    // Write Ports
    input logic [6:0] write_addr,
    input logic [31:0] write_data,
    input logic write_enable,
);

// Packed Array declaration for 32bit x 128 words
logic [31:0] memory [127:0];

// Write Operation
always @(posedge clk) begin
    if(reset == 1'b0) begin 
        for(int i=0; i<128; i++) begin
            memory[i] <= 32'b0;
        end
    end
    else if(write_enable == 1'b1) begin
        memory[write_addr] <= write_data;
    end
end

// Read Operation
always_comb begin
    read1_data = memory[read1_addr];
    read2_data = memory[read2_addr];
end

endmodule