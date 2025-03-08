// Testbench for the ALU module

`timescale 1ns/1ps

module alu_tb;

    // Inputs
    reg [31:0] operand1;
    reg [31:0] operand2;
    reg [3:0] alu_op;

    // Outputs
    wire [31:0] result;
    wire zero_flag;
    wire negative_flag;
    wire overflow_flag;
    wire carry_flag;

    // Instantiate the ALU module
    alu alu_inst(
        .operand1(operand1),
        .operand2(operand2),
        .alu_op(alu_op),
        .result(result),
        .zero_flag(zero_flag),
        .negative_flag(negative_flag),
        .overflow_flag(overflow_flag),
        .carry_flag(carry_flag)
    );

    // Testbench code
    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);

        // Test case 1: ADD operation
        operand1 = 32'h00000001;
        operand2 = 32'h00000002;
        alu_op = 4'b0000; // ALU_ADD
        #10; // Wait for 10 time units
        $display("Test Case 1: ADD operation");
        $display("Operand1: %h", operand1);
        $display("Operand2: %h", operand2);
        $display("ALU Operation: ADD");
        $display("Result: %h", result);
        $display("Zero Flag: %b", zero_flag);
        $display("Negative Flag: %b", negative_flag);
        $display("Overflow Flag: %b", overflow_flag);
        $display("Carry Flag: %b", carry_flag);
        $display("");

        // Test case 2: SUB operation
        operand1 = 32'h00000005;
        operand2 = 32'h00000002;
        alu_op = 4'b0001; // ALU_SUB
        #10; // Wait for 10 time units
        $display("Test Case 2: SUB operation");
        $display("Operand1: %h", operand1);
        $display("Operand2: %h", operand2);
        $display("ALU Operation: SUB");
        $display("Result: %h", result);
        $display("Zero Flag: %b", zero_flag);
        $display("Negative Flag: %b", negative_flag);
        $display("Overflow Flag: %b", overflow_flag);
        $display("Carry Flag: %b", carry_flag);
        $display("");

        // Test case 3: AND operation
        operand1 = 32'h0000000F;
        operand2 = 32'h0000000A;
        alu_op = 4'b0010; // ALU_AND
        #10; // Wait for 10 time units
        $display("Test Case 3: AND operation");
        $display("Operand1: %h", operand1);
        $display("Operand2: %h", operand2);
        $display("ALU Operation: AND");
        $display("Result: %h", result);
        $display("Zero Flag: %b", zero_flag);
        $display("Negative Flag: %b", negative_flag);
        $display("Overflow Flag: %b", overflow_flag);
        $display("Carry Flag: %b", carry_flag);
        $display("");

        // Test case 4: OR operation
        operand1 = 32'h0000000F;
        operand2 = 32'h0000000A;
        alu_op = 4'b0011; // ALU_OR
        #10; // Wait for 10 time units
        $display("Test Case 4: OR operation");
        $display("Operand1: %h", operand1);
        $display("Operand2: %h", operand2);
        $display("ALU Operation: OR");
        $display("Result: %h", result);
        $display("Zero Flag: %b", zero_flag);
        $display("Negative Flag: %b", negative_flag);
        $display("Overflow Flag: %b", overflow_flag);
        $display("Carry Flag: %b", carry_flag);
        $display("");

        // Test case 5: XOR operation
        operand1 = 32'h0000000F;
        operand2 = 32'h0000000A;
        alu_op = 4'b0100; // ALU_XOR
        #10; // Wait for 10 time units
        $display("Test Case 5: XOR operation");
        $display("Operand1: %h", operand1);
        $display("Operand2: %h", operand2);
        $display("ALU Operation: XOR");
        $display("Result: %h", result);
        $display("Zero Flag: %b", zero_flag);
        $display("Negative Flag: %b", negative_flag);
        $display("Overflow Flag: %b", overflow_flag);
        $display("Carry Flag: %b", carry_flag);
        $display("");

        // Test case 6: SLL operation
        operand1 = 32'h0000000F;
        operand2 = 5'b00010;
        alu_op = 4'b0101; // ALU_SLL
        #10; // Wait for 10 time units
        $display("Test Case 6: SLL operation");
        $display("Operand1: %h", operand1);
        $display("Operand2: %h", operand2);
        $display("ALU Operation: SLL");
        $display("Result: %h", result);
        $display("Zero Flag: %b", zero_flag);
        $display("Negative Flag: %b", negative_flag);
        $display("Overflow Flag: %b", overflow_flag);

        // Test case 7: SRL operation
        operand1 = 32'h0000000F;
        operand2 = 5'b00010;
        alu_op = 4'b0110; // ALU_SRL
        #10; // Wait for 10 time units
        $display("Test Case 7: SRL operation");
        $display("Operand1: %h", operand1);
        $display("Operand2: %h", operand2);
        $display("ALU Operation: SRL");
        $display("Result: %h", result);
        $display("Zero Flag: %b", zero_flag);
        $display("Negative Flag: %b", negative_flag);
        $display("Overflow Flag: %b", overflow_flag);
        
        // Test case 8: SRA operation
        operand1 = 32'h80000000;
        operand2 = 5'b00010;
        alu_op = 4'b0111; // ALU_SRA
        #10; // Wait for 10 time units
        $display("Test Case 8: SRA operation");
        $display("Operand1: %h", operand1);
        $display("Operand2: %h", operand2);
        $display("ALU Operation: SRA");
        $display("Result: %h", result);
        $display("Zero Flag: %b", zero_flag);
        $display("Negative Flag: %b", negative_flag);
        $display("Overflow Flag: %b", overflow_flag);

    end

    initial begin
        $monitor("Time: %0t | Operand1: %h | Operand2: %h | ALU Operation: %0d | Result: %h | Zero Flag: %b | Negative Flag: %b | Overflow Flag: %b | Carry Flag: %b\n", $time, operand1, operand2, alu_op, result, zero_flag, negative_flag, overflow_flag, carry_flag);
    end


endmodule


