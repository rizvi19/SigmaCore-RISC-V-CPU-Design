// SigmaCore Project: Testbench for the Register File

`timescale 1ns/1ps

module register_file_tb;

    // Inputs to the register_file DUT
    logic        clk_tb;
    logic        reset_n_tb;
    logic [4:0]  read_addr1_tb;
    logic [4:0]  read_addr2_tb;
    logic [4:0]  write_addr_tb;
    logic [31:0] write_data_tb;
    logic        write_enable_tb;

    // Outputs from the register_file DUT
    wire [31:0] read_data1_tb;
    wire [31:0] read_data2_tb;

    // Instantiate the Register File (DUT)
    register_file dut (
        .clk          (clk_tb),
        .reset_n      (reset_n_tb),
        .read_addr1   (read_addr1_tb),
        .read_data1   (read_data1_tb),
        .read_addr2   (read_addr2_tb),
        .read_data2   (read_data2_tb),
        .write_addr   (write_addr_tb),
        .write_data   (write_data_tb),
        .write_enable (write_enable_tb)
    );

    // Clock generation
    localparam CLOCK_PERIOD = 10; // ns
    always begin
        clk_tb = 1'b0; #(CLOCK_PERIOD/2);
        clk_tb = 1'b1; #(CLOCK_PERIOD/2);
    end

    // Test sequence
    initial begin
        $dumpfile("regfile_waveforms.vcd");
        $dumpvars(0, register_file_tb);

        $display("Starting Register File Testbench...");
        $display("===================================");

        // 1. Initialize and Reset
        reset_n_tb      = 1'b0; 
        write_enable_tb = 1'b0;
        write_addr_tb   = 5'b0;
        write_data_tb   = 32'hDEADBEEF; 
        read_addr1_tb   = 5'd1;
        read_addr2_tb   = 5'd2;
        repeat(2) @(posedge clk_tb); 
        reset_n_tb      = 1'b1; 
        @(posedge clk_tb);
        $display("[%0t ns] Reset complete.", $time);

        if (read_data1_tb !== 32'b0 || read_data2_tb !== 32'b0) begin
            $error("FAIL: Read after reset. R1_data=%h, R2_data=%h. Expected 0 for both.", read_data1_tb, read_data2_tb);
        end else begin
            $display("PASS: Read after reset (R1_data=%h, R2_data=%h).", read_data1_tb, read_data2_tb);
        end
        $display("------------------------------------");

        // 2. Write to some registers (with write_enable toggled for each)
        $display("[%0t ns] Test: Writing to registers R1, R2, R31", $time);
        // Write to R1
        write_enable_tb = 1'b1;
        write_addr_tb   = 5'd1; write_data_tb   = 32'hAAAAAAAA; @(posedge clk_tb);
        write_enable_tb = 1'b0; @(posedge clk_tb); // Add a cycle with WE low

        // Write to R2
        write_enable_tb = 1'b1;
        write_addr_tb   = 5'd2; write_data_tb   = 32'hBBBBBBBB; @(posedge clk_tb);
        write_enable_tb = 1'b0; @(posedge clk_tb); // Add a cycle with WE low

        // Write to R31
        write_enable_tb = 1'b1;
        write_addr_tb   = 5'd31; write_data_tb  = 32'hFFFFFFFF; @(posedge clk_tb);
        write_enable_tb = 1'b0; // Keep WE low after last write
        $display("------------------------------------");

        // 3. Read back written values
        $display("[%0t ns] Test: Reading written values", $time);
        read_addr1_tb = 5'd1; read_addr2_tb = 5'd2; @(posedge clk_tb);
        if (read_data1_tb !== 32'hAAAAAAAA) $error("FAIL: Read R1. Got %h, Expected AAAAAAAA", read_data1_tb); else $display("PASS: Read R1 = %h", read_data1_tb);
        if (read_data2_tb !== 32'hBBBBBBBB) $error("FAIL: Read R2. Got %h, Expected BBBBBBBB", read_data2_tb); else $display("PASS: Read R2 = %h", read_data2_tb);

        read_addr1_tb = 5'd31; read_addr2_tb = 5'd1; @(posedge clk_tb);
        if (read_data1_tb !== 32'hFFFFFFFF) $error("FAIL: Read R31. Got %h, Expected FFFFFFFF", read_data1_tb); else $display("PASS: Read R31 = %h", read_data1_tb);
        if (read_data2_tb !== 32'hAAAAAAAA) $error("FAIL: Read R1 on port 2. Got %h, Expected AAAAAAAA", read_data2_tb); else $display("PASS: Read R1 on port 2 = %h", read_data2_tb);
        $display("------------------------------------");

        // 4. Test writing to x0 (register 0)
        $display("[%0t ns] Test: Attempting to write to x0 (R0)", $time);
        write_enable_tb = 1'b1;
        write_addr_tb   = 5'd0; 
        write_data_tb   = 32'h12345678; 
        @(posedge clk_tb);
        write_enable_tb = 1'b0;

        read_addr1_tb = 5'd0; read_addr2_tb = 5'd1; @(posedge clk_tb);
        if (read_data1_tb !== 32'b0) $error("FAIL: x0 read. Got %h, Expected 00000000", read_data1_tb); else $display("PASS: x0 read = %h", read_data1_tb);
        if (read_data2_tb !== 32'hAAAAAAAA) $error("FAIL: R1 value changed after x0 write attempt. Got %h, Expected AAAAAAAA", read_data2_tb); else $display("PASS: R1 value unchanged = %h", read_data2_tb);
        $display("------------------------------------");

        // 5. Test read-during-write (write to R3, read R3 and R4)
        $display("[%0t ns] Test: Read-during-write scenario", $time);
        // First, set R3 and R4 to known initial values
        write_enable_tb = 1'b1;
        write_addr_tb = 5'd3; write_data_tb = 32'h03030303; @(posedge clk_tb);
        write_enable_tb = 1'b0; @(posedge clk_tb); // WE low

        write_enable_tb = 1'b1;
        write_addr_tb = 5'd4; write_data_tb = 32'h04040404; @(posedge clk_tb);
        write_enable_tb = 1'b0; @(posedge clk_tb); // WE low

        // Now, write to R3 and simultaneously read R3 and R4
        read_addr1_tb   = 5'd3; 
        read_addr2_tb   = 5'd4; 
        write_enable_tb = 1'b1; // Enable write for R3 update
        write_addr_tb   = 5'd3; 
        write_data_tb   = 32'hCAFEBABE; // New value for R3 
        
        @(posedge clk_tb); // Write to R3 happens. Read R3/R4 happens combinatorially.
        $display("  During write to R3 with CAFEBABE:");
        $display("  Read R3 (read_data1_tb): %h (Expected old value 03030303)", read_data1_tb);
        $display("  Read R4 (read_data2_tb): %h (Expected 04040404)", read_data2_tb);
        if (read_data1_tb !== 32'h03030303) $error("FAIL: Read-during-write to R3. Got %h, Expected old 03030303", read_data1_tb);
        if (read_data2_tb !== 32'h04040404) $error("FAIL: Read R4 during write to R3. Got %h, Expected 04040404", read_data2_tb);
        write_enable_tb = 1'b0; // Disable write after R3 update

        @(posedge clk_tb); // Advance one more cycle
        read_addr1_tb   = 5'd3; // Read R3 again
        // read_addr2_tb remains 5'd4
        $display("  After write to R3 completed (next cycle):");
        $display("  Read R3 (read_data1_tb): %h (Expected CAFEBABE)", read_data1_tb);
        $display("  Read R4 (read_data2_tb): %h (Should still be 04040404)", read_data2_tb);
        if (read_data1_tb !== 32'hCAFEBABE) $error("FAIL: Read R3 after write. Got %h, Expected CAFEBABE", read_data1_tb);
        if (read_data2_tb !== 32'h04040404) $error("FAIL: Read R4 after R3 write. Got %h, Expected 04040404", read_data2_tb);
        $display("------------------------------------");

        $display("===================================");
        $display("Register File Testbench Finished.");
        $finish;
    end

endmodule
