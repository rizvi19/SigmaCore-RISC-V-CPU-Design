// SigmaCore Project: Testbench for the Data Memory

`timescale 1ns/1ps

module data_memory_tb;

    
    reg        clk_tb;
    reg [31:0] addr_tb;
    reg [31:0] write_data_tb;
    reg        write_enable_tb;
    reg        read_enable_tb;

    // Output from the DUT
    wire [31:0] read_data_out_tb;

    // Instantiate the Data Memory (DUT)
    data_memory dut (
        .clk             (clk_tb),
        .addr_in         (addr_tb),
        .write_data_in   (write_data_tb),
        .write_enable    (write_enable_tb),
        .read_enable     (read_enable_tb),
        .read_data_out   (read_data_out_tb)
    );

    // Clock generation
    localparam CLOCK_PERIOD = 10; // ns
    always begin
        clk_tb = 1'b0; #(CLOCK_PERIOD/2);
        clk_tb = 1'b1; #(CLOCK_PERIOD/2);
    end

    // Test sequence
    initial begin
        $dumpfile("dmem_waveforms.vcd");
        $dumpvars(0, data_memory_tb);

        $display("Starting Data Memory Testbench...");
        $display("=================================");

        // Initialize signals
        clk_tb          = 1'b0;
        addr_tb         = 32'b0;
        write_data_tb   = 32'b0;
        write_enable_tb = 1'b0;
        read_enable_tb  = 1'b0;

        // Wait a couple of cycles to start clean
        repeat(2) @(posedge clk_tb);

        // --- Test Case 1: Write a value, then read it back ---
        $display("[%0t ns] Test: Writing 0xCAFEBABE to address 0x100", $time);
        addr_tb         = 32'h00000100;
        write_data_tb   = 32'hCAFEBABE;
        write_enable_tb = 1'b1;
        @(posedge clk_tb); // Write occurs on this edge
        write_enable_tb = 1'b0; // De-assert write enable
        @(posedge clk_tb); // Wait a cycle

        $display("[%0t ns] Test: Reading from address 0x100", $time);
        addr_tb        = 32'h00000100;
        read_enable_tb = 1'b1;
        @(posedge clk_tb); // Address is latched. Data will appear on the next posedge.
        read_enable_tb = 1'b0; // Can de-assert now
        @(posedge clk_tb); // Data is now valid on read_data_out_tb

        $display("  Read from addr %h. Got data: %h. Expected: CAFEBABE", addr_tb, read_data_out_tb);
        if (read_data_out_tb !== 32'hCAFEBABE) $error("FAIL: Address 0x100 data mismatch.");
        else $display("PASS: Address 0x100 data correct.");
        $display("---------------------------------");

        // --- Test Case 2: Write to another address, ensure first value is unchanged ---
        $display("[%0t ns] Test: Writing 0x12345678 to address 0x204", $time);
        addr_tb         = 32'h00000204;
        write_data_tb   = 32'h12345678;
        write_enable_tb = 1'b1;
        @(posedge clk_tb);
        write_enable_tb = 1'b0;
        @(posedge clk_tb);

        // Read back the first address (0x100) to ensure it's still correct
        $display("[%0t ns] Test: Re-reading from address 0x100", $time);
        addr_tb        = 32'h00000100;
        read_enable_tb = 1'b1;
        @(posedge clk_tb);
        read_enable_tb = 1'b0;
        @(posedge clk_tb);
        $display("  Read from addr %h. Got data: %h. Expected: CAFEBABE", addr_tb, read_data_out_tb);
        if (read_data_out_tb !== 32'hCAFEBABE) $error("FAIL: Original value at 0x100 was corrupted.");
        else $display("PASS: Original value at 0x100 is intact.");

        // Now read back the second address (0x204)
        $display("[%0t ns] Test: Reading from address 0x204", $time);
        addr_tb        = 32'h00000204;
        read_enable_tb = 1'b1;
        @(posedge clk_tb);
        read_enable_tb = 1'b0;
        @(posedge clk_tb);
        $display("  Read from addr %h. Got data: %h. Expected: 12345678", addr_tb, read_data_out_tb);
        if (read_data_out_tb !== 32'h12345678) $error("FAIL: Address 0x204 data mismatch.");
        else $display("PASS: Address 0x204 data correct.");
        $display("---------------------------------");

        $display("=================================");
        $display("Data Memory Testbench Finished.");
        $finish;
    end

endmodule
