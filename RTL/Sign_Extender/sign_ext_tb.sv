/*
-----------------------------------------------------------------------------
File Name: sign_ext_tb.sv
SigmaCore Project: Sign Extender Testbench
Author: Shahriar Rizvi
Performs: Testbench for the Sign Extender module
-----------------------------------------------------------------------------
*/



`timescale 1ns/1ps

module sign_ext_tb;

    // Inputs
    reg  [31:0] instruction_tb;
    reg  [2:0]  imm_type_tb;

    // Output
    wire [31:0] imm_extended_out_tb;

    import sigma_pkg::*;

    sign_extender dut (
        .instruction_in     (instruction_tb),
        .imm_type_in        (imm_type_tb),
        .imm_extended_out   (imm_extended_out_tb)
    );

    task automatic apply_and_check (
        input [31:0] inst_val,
        input [2:0]  type_val,
        input [31:0] expected_ext_val,
        input string test_name
    );
        integer delay_time = 10; // ns

        begin
            #delay_time;
            instruction_tb = inst_val;
            imm_type_tb    = type_val;
            #delay_time;

            $display("[%0t ns] Test: %s", $time, test_name);
            $display("  Instruction: %h, Imm_Type: %b (%s)",
                     instruction_tb, imm_type_tb, imm_type_to_string(imm_type_tb));
            $display("  Extended Output: %h (Decimal: %0d)",
                     imm_extended_out_tb, $signed(imm_extended_out_tb));

            if (imm_extended_out_tb !== expected_ext_val) begin
                $error("  MISMATCH! Output: %h, Expected: %h",
                       imm_extended_out_tb, expected_ext_val);
            end
            $display("------------------------------------");
        end
    endtask

    function automatic string imm_type_to_string(input [2:0] type_code);
        case(type_code)
            IMM_TYPE_NONE: return "NONE";
            IMM_TYPE_I:    return "I-Type";
            IMM_TYPE_S:    return "S-Type";
            IMM_TYPE_B:    return "B-Type";
            IMM_TYPE_U:    return "U-Type";
            IMM_TYPE_J:    return "J-Type";
            default:       return $sformatf("UNKNOWN (%b)", type_code);
        endcase
    endfunction

    initial begin
        $dumpfile("sign_ext_waveforms.vcd");
        $dumpvars(0, sign_ext_tb);

        $display("Starting Sign Extender Testbench Simulation...");
        $display("============================================");

        // Test Case 1: IMM_TYPE_NONE
        apply_and_check(32'hDEADBEEF, IMM_TYPE_NONE, 32'h00000000, "IMM_TYPE_NONE");

        // Test Case 2: IMM_TYPE_I (Positive Immediate +5)
        apply_and_check(32'h00500093, IMM_TYPE_I, 32'h00000005, "I-Type Positive (+5)");

        // Test Case 3: IMM_TYPE_I (Negative Immediate -5)
        apply_and_check(32'hFFB00093, IMM_TYPE_I, 32'hFFFFFFF_B, "I-Type Negative (-5)");

        // Test Case 4: IMM_TYPE_S (Positive Immediate +12)
        apply_and_check(32'h00002623, IMM_TYPE_S, 32'h0000000C, "S-Type Positive (+12)");

        // Test Case 5: IMM_TYPE_S (Negative Immediate -16)
        apply_and_check(32'hFE002823, IMM_TYPE_S, 32'hFFFFFFF0, "S-Type Negative (-16)");

        // Test Case 6: IMM_TYPE_B (Positive Offset +20)
        // Instruction for beq x0,x0,+20 (target is PC+20, immediate is 20) is 0x00A00A63
        apply_and_check(32'h00A00A63, IMM_TYPE_B, 32'h00000014, "B-Type Positive Offset (+20)");

        // Test Case 7: IMM_TYPE_B (Negative Offset -20)
        // Instruction for beq x0,x0,-20 (target is PC-20, immediate is -20) is 0xFE000CE3
        apply_and_check(32'hFE0006E3, IMM_TYPE_B, 32'hFFFFFFEC, "B-Type Negative Offset (-20)");

        // Test Case 8: IMM_TYPE_U (Positive Value 0x12345)
        apply_and_check(32'h123450B7, IMM_TYPE_U, 32'h12345000, "U-Type Positive (0x12345 << 12)");

        // Test Case 9: IMM_TYPE_U (Value 0xFEDCB)
        apply_and_check(32'hFEDCB0B7, IMM_TYPE_U, 32'hFEDCB000, "U-Type Top Bits (0xFEDCB << 12)");

        // Test Case 10: IMM_TYPE_J (Positive Offset +1000)
        // Instruction for jal x0,+1000 (target is PC+1000, immediate is 1000) is 0x3E80006F
        apply_and_check(32'h3E80006F, IMM_TYPE_J, 32'h000003E8, "J-Type Positive Offset (+1000)");

        // Test Case 11: IMM_TYPE_J (Negative Offset -1000)
        // Instruction for jal x0,-1000 (target is PC-1000, immediate is -1000) is 0xC18FC06F
        apply_and_check(32'hC19FF06F, IMM_TYPE_J, 32'hFFFFFC18, "J-Type Negative Offset (-1000)");


        // Test Case 12: Default type (should be 0)
        apply_and_check(32'h12345678, 3'b111, 32'h00000000, "Unknown IMM_TYPE");


        $display("============================================");
        $display("Sign Extender Testbench Simulation Finished.");
        $finish;
    end

endmodule
