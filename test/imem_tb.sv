// SigmaCore Project: Testbench for the Instruction Memory

`timescale 1ns/1ps

module instruction_memory_tb;

    // Inputs to the DUT
    logic        clk_tb;
    logic [31:0] read_addr_tb;

    // Output from the DUT
    wire [31:0] instruction_out_tb;

    // Instantiate the Instruction Memory (DUT)
    instruction_memory dut (
        .clk             (clk_tb),
        .read_addr_in    (read_addr_tb),
        .instruction_out (instruction_out_tb)
    );

    // Clock generation
    localparam CLOCK_PERIOD = 10; // ns
    always begin
        clk_tb = 1'b0; #(CLOCK_PERIOD/2);
        clk_tb = 1'b1; #(CLOCK_PERIOD/2);
    end

    // Test sequence
    initial begin
        $dumpfile("imem_waveforms.vcd");
        $dumpvars(0, instruction_memory_tb);

        $display("Starting Instruction Memory Testbench...");
        $display("========================================");

        // Initialize signals
        clk_tb       = 1'b0;
        read_addr_tb = 32'b0;

        // Waiting for 2 cycles for memory to initialize from file
        repeat(2) @(posedge clk_tb);

        // --- Test Case 1: Read from address 0x00 ---
        $display("[%0t ns] Test: Reading from address 0x00", $time);
        read_addr_tb = 32'h00000000;
        @(posedge clk_tb); // Address is latched. Data will appear on the next posedge.
        @(posedge clk_tb); // Data is now valid on instruction_out_tb

        $display("  Read from addr %h. Got instruction: %h. Expected: 12345678", read_addr_tb, instruction_out_tb);
        if (instruction_out_tb !== 32'h12345678) $error("FAIL: Address 0x00 mismatch.");
        else $display("PASS: Address 0x00 correct.");
        $display("------------------------------------");

        // --- Test Case 2: Read from address 0x08 ---
        $display("[%0t ns] Test: Reading from address 0x08", $time);
        read_addr_tb = 32'h00000008;
        @(posedge clk_tb);
        @(posedge clk_tb);

        $display("  Read from addr %h. Got instruction: %h. Expected: DEADBEEF", read_addr_tb, instruction_out_tb);
        if (instruction_out_tb !== 32'hDEADBEEF) $error("FAIL: Address 0x08 mismatch.");
        else $display("PASS: Address 0x08 correct.");
        $display("------------------------------------");

        // --- Test Case 3: Read from address 0x10 ---
        $display("[%0t ns] Test: Reading from address 0x10", $time);
        read_addr_tb = 32'h00000010;
        @(posedge clk_tb);
        @(posedge clk_tb);

        $display("  Read from addr %h. Got instruction: %h. Expected: FFFFFFFF", read_addr_tb, instruction_out_tb);
        if (instruction_out_tb !== 32'hFFFFFFFF) $error("FAIL: Address 0x10 mismatch.");
        else $display("PASS: Address 0x10 correct.");
        $display("------------------------------------");
        
        // --- Test Case 4: Read from consecutive addresses ---
        $display("[%0t ns] Test: Reading consecutively from 0x04 then 0x0C", $time);
        read_addr_tb = 32'h00000004;
        @(posedge clk_tb); // Latch address 0x04
        // On this next edge, output for address 0x10 (from prev test) is still valid.
        @(posedge clk_tb); // Now, output for address 0x04 is valid.
        $display("  Read from addr 0x04. Got instruction: %h. Expected: ABCDEF01", instruction_out_tb);
        if (instruction_out_tb !== 32'hABCDEF01) $error("FAIL: Address 0x04 mismatch.");
        
        // Immediately change address to 0x0C
        read_addr_tb = 32'h0000000C;
        @(posedge clk_tb); // Latch address 0x0C
        // On this next edge, output for address 0x04 is still valid.
        @(posedge clk_tb); // Now, output for address 0x0C is valid.
        $display("  Read from addr 0x0C. Got instruction: %h. Expected: 00000000", instruction_out_tb);
        if (instruction_out_tb !== 32'h00000000) $error("FAIL: Address 0x0C mismatch.");
        else $display("PASS: Consecutive reads correct.");
        $display("------------------------------------");


        $display("========================================");
        $display("Instruction Memory Testbench Finished.");
        $finish;
    end

endmodule
