`timescale 1ns/1ps

module tb_sigmacore_top;

    // Inputs to the DUT
    logic        clk_tb;
    logic        reset_n_tb;

    // Outputs from the DUT
    logic [31:0] pc_out_tb;
    logic [31:0] instruction_out_tb;

    // Instantiate the Top-Level CPU (DUT)
    sigmacore_top dut (
        .clk                 (clk_tb),
        .reset_n             (reset_n_tb),
        .final_pc_out        (pc_out_tb),
        .final_instruction_out (instruction_out_tb)
    );

    // Clock generation
    localparam CLOCK_PERIOD = 10; // ns
    initial begin
        clk_tb = 1'b0;
        forever #(CLOCK_PERIOD/2) clk_tb = ~clk_tb;
    end

    // Test sequence
    initial begin
        $dumpfile("cpu_waveforms.vcd");
        $dumpvars(0, tb_sigmacore_top);

        $display("Starting Top-Level CPU Testbench...");
        $display("===================================");

        // 1. Reset the CPU
        reset_n_tb = 1'b0;
        repeat(5) @(posedge clk_tb);
        reset_n_tb = 1'b1;
        $display("[%0t ns] Reset released. Running CPU program...", $time);

        // 2. Run for a reasonable number of cycles (20 cycles per instruction * 15 instructions)
        repeat(300) @(posedge clk_tb);

        // 3. End simulation
        $display("[%0t ns] Simulation finished.", $time);
        $display("===================================");
        $display("Note: Verify register and memory values using cpu_waveforms.vcd.");
        $display("Expected: x5=0xCAFEF000 (LUI), x6=0xCAFEF100 (ADDI), x7=0x95FDE100 (ADD),");
        $display("          x7=... (SUB/AND/OR/XOR/SLT/SLTI/SLL/SRL/SRA), x6=... (LW), memory[0xCAFEF00C]=0x95FDE100 (SW),");
        $display("          PC branches correctly for BEQ (e.g., back to 0x0 if t0 == t1).");
        $display("===================================");
        $display("Top-Level CPU Testbench Finished.");
        $finish;
    end

    // Simplified Smart Monitor to trace program execution
    always @(posedge clk_tb) begin
        if (reset_n_tb) begin
            $display("TRACE | PC: %h | Instruction: %h", pc_out_tb, instruction_out_tb);
        end
    end

endmodule