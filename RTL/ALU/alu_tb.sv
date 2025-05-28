/*
---------------------------------------------------------------
File: alu_tb.sv
SigmaCore Project: ALU Testbench
Author: Shahriar Rizvi
Performs: Testbench for the ALU module
---------------------------------------------------------------
*/

`timescale 1ns/1ps

module alu_tb;

    // Inputs
    reg [31:0] operand1_tb;
    reg [31:0] operand2_tb;
    reg [3:0] alu_op_tb;

    // Outputs
    wire [31:0] result_tb;
    wire zero_flag_tb;
    wire negative_flag_tb;
    wire overflow_flag_tb;
    wire carry_flag_tb;

    import sigma_pkg::*;

    // Instantiate the ALU module
    alu alu_instance(
        .operand1(operand1_tb),
        .operand2(operand2_tb),
        .alu_op(alu_op_tb),
        .result(result_tb),
        .zero_flag(zero_flag_tb),
        .negative_flag(negative_flag_tb),
        .overflow_flag(overflow_flag_tb),
        .carry_flag(carry_flag_tb)
    );



    task automatic apply_and_check; // A task to apply the Test Cases
        input [31:0] op1_in, op2_in;
        input [3:0]  op_code_in;
        input [31:0] expected_result;
        input        expected_zero, expected_neg, expected_ovf, expected_carry;
        input string test_name;
        integer      delay_time = 10; // delay in ns

        begin
            #delay_time;
            operand1_tb = op1_in;
            operand2_tb = op2_in;
            alu_op_tb   = op_code_in;
            #delay_time; 

            $display("[%0t ns] Test: %s", $time, test_name);
            $display("  Inputs: op1=%h, op2=%h, alu_op=%b (%s)",
                        operand1_tb, operand2_tb, alu_op_tb, op_code_to_string(alu_op_tb));
            $display("  Outputs: Result=%h, Z=%b, N=%b, O=%b, C=%b",
                        result_tb, zero_flag_tb, negative_flag_tb, overflow_flag_tb, carry_flag_tb);

            if (result_tb !== expected_result) begin
                $error("  MISMATCH! Result: %h, Expected: %h", result_tb, expected_result);
            end
            if (zero_flag_tb !== expected_zero) begin
                $error("  MISMATCH! Zero Flag: %b, Expected: %b", zero_flag_tb, expected_zero);
            end
            if (negative_flag_tb !== expected_neg) begin
                $error("  MISMATCH! Negative Flag: %b, Expected: %b", negative_flag_tb, expected_neg);
            end
            if (overflow_flag_tb !== expected_ovf) begin
                $error("  MISMATCH! Overflow Flag: %b, Expected: %b", overflow_flag_tb, expected_ovf);
            end
            if (alu_op_tb == ALU_ADD || alu_op_tb == ALU_SUB) begin // Carry is most relevant for ADD/SUB
                if (carry_flag_tb !== expected_carry) begin
                    $error("  MISMATCH! Carry Flag: %b, Expected: %b", carry_flag_tb, expected_carry);
                end
            end
        end
    endtask

    // Function to convert ALU op code to string for display
    function automatic string op_code_to_string(input [3:0] op_code);
        case(op_code)
            ALU_ADD: return "ADD";
            ALU_SUB: return "SUB";
            ALU_AND: return "AND";
            ALU_OR:  return "OR";
            ALU_XOR: return "XOR";
            ALU_SLL: return "SLL";
            ALU_SRL: return "SRL";
            ALU_SRA: return "SRA";
            
            default: return $sformatf("OP:%b", op_code);
        endcase
    endfunction




    // Test Cases
    initial begin
        $dumpfile("alu_waveforms.vcd");
        $dumpvars(0, alu_tb);

        // --- Test Cases ---
        // apply_and_check(op1, op2, alu_op, exp_res, exp_Z, exp_N, exp_O, exp_C, "Test Name");

        // Test 1: ADD (Simple)
        apply_and_check(32'h00000001, 32'h00000002, ALU_ADD, 32'h00000003, 1'b0, 1'b0, 1'b0, 1'b0, "ADD (1 + 2)");
        // Test 2: SUB (Simple)
        apply_and_check(32'h00000005, 32'h00000002, ALU_SUB, 32'h00000003, 1'b0, 1'b0, 1'b0, 1'b1, "SUB (5 - 2)"); // Carry=1 (no borrow)
        // Test 3: AND
        apply_and_check(32'h0000000F, 32'h0000000A, ALU_AND, 32'h0000000A, 1'b0, 1'b0, 1'b0, 1'b0, "AND (0xF & 0xA)");
        // Test 4: OR
        apply_and_check(32'h0000000F, 32'h0000000A, ALU_OR,  32'h0000000F, 1'b0, 1'b0, 1'b0, 1'b0, "OR (0xF | 0xA)");
        // Test 5: XOR
        apply_and_check(32'h0000000F, 32'h0000000A, ALU_XOR, 32'h00000005, 1'b0, 1'b0, 1'b0, 1'b0, "XOR (0xF ^ 0xA)");
        // Test 6: SLL (Shift Logical Left)
        apply_and_check(32'h0000000F, 32'd2,        ALU_SLL, 32'h0000003C, 1'b0, 1'b0, 1'b0, 1'b0, "SLL (0xF << 2)");
        // Test 7: SRL (Shift Logical Right)
        apply_and_check(32'h0000000F, 32'd2,        ALU_SRL, 32'h00000003, 1'b0, 1'b0, 1'b0, 1'b0, "SRL (0xF >> 2)");
        // Test 8: SRA (Shift Arithmetic Right, positive number)
        apply_and_check(32'h000000F0, 32'd2,        ALU_SRA, 32'h0000003C, 1'b0, 1'b0, 1'b0, 1'b0, "SRA (0xF0 >>> 2)");
        // Test 9: SRA (Shift Arithmetic Right, negative number)
        apply_and_check(32'hFFFFFFF0, 32'd2,        ALU_SRA, 32'hFFFFFFFC, 1'b0, 1'b1, 1'b0, 1'b0, "SRA (0xFFFFFFF0 >>> 2)");
        // Test 10: ADD (Zero flag)
        apply_and_check(32'hFFFFFFFF, 32'h00000001, ALU_ADD, 32'h00000000, 1'b1, 1'b0, 1'b0, 1'b1, "ADD (-1 + 1) -> Zero");
        // Test 11: ADD (Overflow: pos + pos = neg)
        apply_and_check(32'h7FFFFFFF, 32'h00000001, ALU_ADD, 32'h80000000, 1'b0, 1'b1, 1'b1, 1'b0, "ADD (MaxPos + 1) -> Overflow");
        // Test 12: ADD (Overflow: neg + neg = pos)
        apply_and_check(32'h80000000, 32'h80000000, ALU_ADD, 32'h00000000, 1'b1, 1'b0, 1'b1, 1'b1, "ADD (MinNeg + MinNeg) -> Overflow");
        // Test 13: SUB (Negative flag)
        apply_and_check(32'h00000002, 32'h00000005, ALU_SUB, 32'hFFFFFFFD, 1'b0, 1'b1, 1'b0, 1'b0, "SUB (2 - 5) -> Negative"); // Carry=0 (borrow)
        // Test 14: SUB (Overflow: pos - neg = neg_res_overflow)
        apply_and_check(32'h70000000, 32'h90000000, ALU_SUB, 32'hE0000000, 1'b0, 1'b1, 1'b1, 1'b0, "SUB (LargePos - LargeNeg) -> Overflow");
        // Test 15: SUB (Overflow: neg - pos = pos_res_overflow)
        apply_and_check(32'h90000000, 32'h70000000, ALU_SUB, 32'h20000000, 1'b0, 1'b0, 1'b1, 1'b1, "SUB (LargeNeg - LargePos) -> Overflow");
        // Test 16: SLL (Shift by 0)
        apply_and_check(32'hABCDEF12, 32'd0,        ALU_SLL, 32'hABCDEF12, 1'b0, 1'b1, 1'b0, 1'b0, "SLL (val << 0)");
        // Test 17: SLL (Shift by 31)
        apply_and_check(32'h00000001, 32'd31,       ALU_SLL, 32'h80000000, 1'b0, 1'b1, 1'b0, 1'b0, "SLL (1 << 31)");
        // Test 18: SLL (Shift amount > 31, should use operand2[4:0])
        apply_and_check(32'h00000001, 32'd34,       ALU_SLL, 32'h00000004, 1'b0, 1'b0, 1'b0, 1'b0, "SLL (1 << 34), effective (1 << 2)");
        // Test 19: Default ALU op (if not defined in package, or an unused code)
        // Assuming 4'b1111 is not a defined ALU_OP in sigma_pkg.sv
        apply_and_check(32'd10, 32'd5, 4'b1111, 32'h0, 1'b1, 1'b0, 1'b0, 1'b0, "Default/Unknown ALU Op");


        $display("ALU Testbench Simulation Finished.");
        $finish;

    end

endmodule


