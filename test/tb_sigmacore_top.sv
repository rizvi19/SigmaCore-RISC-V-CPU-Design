// SigmaCore Project: Testbench for the Top-Level CPU with Smart Monitor

`timescale 1ns/1ps

module tb_sigmacore_top;

    // Inputs to the DUT
    logic        clk_tb;
    logic        reset_n_tb;

    // Outputs from the DUT
    wire [31:0] pc_out_tb;
    wire [31:0] instruction_out_tb;

    // Instantiate the Top-Level CPU (DUT)
    sigmacore_top dut (
        .clk                 (clk_tb),
        .reset_n             (reset_n_tb),
        .final_pc_out        (pc_out_tb),
        .final_instruction_out (instruction_out_tb)
    );

    // Clock generation
    localparam CLOCK_PERIOD = 10; // ns
    always begin
        clk_tb = 1'b0; #(CLOCK_PERIOD/2);
        clk_tb = 1'b1; #(CLOCK_PERIOD/2);
    end

    // Test sequence
    initial begin
        // CORRECTED: Declare local variable at the top of the block.
        logic [9:0] dmem_word_addr;

        $dumpfile("cpu_waveforms.vcd");
        $dumpvars(0, tb_sigmacore_top);

        $display("Starting Top-Level CPU Testbench...");
        $display("===================================");
        $display("Program loaded. Resetting the CPU...");

        // 1. Initialize and Reset
        clk_tb     = 1'b0;
        reset_n_tb = 1'b0; // Assert active-low reset
        repeat(5) @(posedge clk_tb); // Hold reset for a few cycles
        reset_n_tb = 1'b1; // De-assert reset
        
        $display("[%0t ns] Reset released. Running CPU program...", $time);

        // 2. Run the CPU for a fixed number of cycles to complete the program
        repeat(30) @(posedge clk_tb);

        // 3. Announce completion
        $display("[%0t ns] Simulation finished.", $time);
        $display("===================================");
        $display("Final CPU State Verification:");

        // Programmatically check final register values using hierarchical references
        if(dut.datapath.reg_file.registers[5] !== 32'h10001000) $error("Final Check FAIL: x5 (t0) is incorrect!");
        else $display("Final Check PASS: x5 (t0) = %h", dut.datapath.reg_file.registers[5]);

        if(dut.datapath.reg_file.registers[6] !== 32'h10001123) $error("Final Check FAIL: x6 (t1) is incorrect!");
        else $display("Final Check PASS: x6 (t1) = %h", dut.datapath.reg_file.registers[6]);
        
        if(dut.datapath.reg_file.registers[7] !== 32'h20002123) $error("Final Check FAIL: x7 (t2) is incorrect!");
        else $display("Final Check PASS: x7 (t2) = %h", dut.datapath.reg_file.registers[7]);

        // Check data memory where the SW instruction wrote its data
        // CORRECTED: Assign value after declaration.
        dmem_word_addr = 32'h10000FF8 >> 2; // Calculate word address
        if(dut.datapath.dmem.memory[dmem_word_addr] !== 32'h20002123) $error("Final Check FAIL: Data Memory at 0x10000FF8 is incorrect!");
        else $display("Final Check PASS: Data Memory @ 0x10000FF8 contains %h", dut.datapath.dmem.memory[dmem_word_addr]);

        $display("===================================");
        $display("Top-Level CPU Testbench Finished.");
        $finish;
    end

    // --- Smart Monitor ---
    // This block watches the CPU and reports on every instruction that completes.
    always @(posedge clk_tb) begin
        // CORRECTED: Declare all local variables at the beginning of the procedural block.
        string      instr_name;
        string      report_string;
        logic [6:0] opcode;
        logic [4:0] rd;
        
        if (reset_n_tb) begin // Only monitor after reset
            // Check if the 'reg_write' signal from the control unit is high.
            // This indicates an instruction is completing its write-back stage.
            if (dut.fsm_ctrl.reg_write) begin
                
                // Assign values to local variables
                opcode = dut.final_instruction_out[6:0];
                rd     = dut.final_instruction_out[11:7];

                // Decode the instruction name for clear reporting
                case (opcode)
                    7'b0110111: instr_name = "lui";
                    7'b0010011: instr_name = "addi";
                    7'b0110011: instr_name = "add";
                    default:    instr_name = "unknown_wb";
                endcase
                
                // CORRECTED: Separate assignment from declaration for the string.
                report_string = $sformatf(
                    "CPU TRACE | PC: %h | WB: Writing %h to register x%0d (%s)",
                    dut.final_pc_out, dut.datapath.reg_write_data, rd, instr_name
                );
                
                $display(report_string);
            end
            
            // Monitor for Store Word (which doesn't write to a register)
            if (dut.fsm_ctrl.mem_write) begin
                 report_string = $sformatf(
                    "CPU TRACE | PC: %h | MEM: Storing value %h to address %h (sw)",
                     dut.final_pc_out, dut.datapath.reg_b, dut.datapath.alu_result_register
                );
                $display(report_string);
            end
        end
    end

endmodule
