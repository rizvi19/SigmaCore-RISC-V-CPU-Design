/*
-----------------------------------------------------------
File Name: register_file.sv
SigmaCore Project: Register File Unit
Author: Shahriar Rizvi
Performs: Implements a 32x32 register file for RISC-V CPU

- 32 registers, each 32 bits wide.
- Register x0 (address 0) is hardwired to zero.
- Two asynchronous read ports.
- One synchronous write port.


-----------------------------------------------------------
*/

`timescale 1ns/1ps

module register_file (
    // Clock and Reset
    input  logic        clk,          // Clock signal
    input  logic        reset_n,      // Active-low synchronous reset

    // Read Port 1
    input  logic [4:0]  read_addr1,   // Address for read port 1
    output logic [31:0] read_data1,   // Data output from read port 1

    // Read Port 2
    input  logic [4:0]  read_addr2,   // Address for read port 2
    output logic [31:0] read_data2,   // Data output from read port 2

    // Write Port
    input  logic [4:0]  write_addr,   // Address for write port
    input  logic [31:0] write_data,   // Data to write
    input  logic        write_enable  // Enables writing
);

    // Register storage: 32 registers, each 32 bits wide.
    logic [31:0] registers [0:31]; // Array of 32 registers

    // Synchronous Write Port Logic
    // Writes occur on the positive edge of the clock.
    always_ff @(posedge clk) begin
        if (!reset_n) begin // Active-low synchronous reset
            // On reset, initialize all registers to 0.
            for (int i = 0; i < 32; i++) begin
                registers[i] <= 32'b0;
            end
        end else begin
            // If write_enable is asserted and the write_addr is not x0 (register 0),
            // then write write_data to the specified register.
            if (write_enable && (write_addr != 5'b0)) begin
                registers[write_addr] <= write_data;
            end
        end
    end

    // Asynchronous Read Port 1 Logic
    // If read_addr1 is 0 (x0), output 32'b0. Otherwise, output the register content.
    assign read_data1 = (read_addr1 == 5'b0) ? 32'b0 : registers[read_addr1];

    // Asynchronous Read Port 2 Logic
    // If read_addr2 is 0 (x0), output 32'b0. Otherwise, output the register content.
    assign read_data2 = (read_addr2 == 5'b0) ? 32'b0 : registers[read_addr2];

endmodule
