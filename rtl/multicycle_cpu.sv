/*
-------------------------------------------------
File: multicycle_cpu.sv
SigmaCore Project: Multicycle CPU
Author: Shahriar Rizvi
Performs: Implements a multicycle RISC-V CPU
-------------------------------------------------
*/

`timescale 1ns/1ps

module multicycle_cpu (
    // System Inputs
    input  logic        clk,
    input  logic        reset_n,

    // Control Signal Inputs (to be driven by FSM Control Unit)
    input  logic        pc_write,             // Enable writing to the PC
    input  logic        ir_write,             // Enable writing to the Instruction Register
    input  logic        reg_write,            // Enable writing to the Register File
    input  logic        mem_write,            // Enable writing to Data Memory
    input  logic        mem_read,             // Enable reading from Data Memory
    input  logic [1:0]  pc_source,            // MUX select for the PC's next value
    input  logic        mem_to_reg,           // MUX select for the data written back to the Register File
    input  logic        alu_src_a,            // MUX select for ALU's first operand
    input  logic [1:0]  alu_src_b,            // MUX select for ALU's second operand
    input  logic [2:0]  imm_src,              // Selects immediate type for Sign Extender
    input  logic [1:0]  alu_op_type,          // High-level command for the ALU Control unit
    input  logic        reg_a_write,          // Enable writing to operand register A
    input  logic        reg_b_write,          // Enable writing to operand register B
    input  logic        alu_out_write,        // Enable writing to the ALU output register

    // Debugging Outputs
    output logic [31:0] current_pc_out,
    output logic [31:0] instruction_out
);

    import sigma_pkg::*;

    //--- Intermediate Wires and State Registers ---
    logic [31:0] pc_next, pc_current;
    logic [31:0] instruction_from_imem;
    logic [31:0] instruction_register;
    logic [31:0] mem_data_register;
    logic [31:0] alu_result;
    logic [31:0] alu_result_register;
    logic        alu_zero_flag;
    logic [31:0] reg_file_read_data1, reg_file_read_data2;
    logic [31:0] reg_a, reg_b;
    logic [31:0] sign_extended_imm;
    logic [31:0] alu_input_a, alu_input_b;
    logic [3:0]  alu_op;
    logic [31:0] reg_write_data;
    logic [31:0] mem_read_data;
    logic [2:0]  funct3; // Added for R-type differentiation
    logic [6:0]  funct7; // Added for R-type differentiation

    //================================================================
    // 1. Instruction Fetch (IF) Stage Components
    //================================================================

    // Program Counter (PC) Register
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            pc_current <= 32'b0;
        else if (pc_write)
            pc_current <= pc_next;
    end
    assign current_pc_out = pc_current;

    // Instruction Memory
    instruction_memory imem (
        .clk             (clk),
        .read_addr_in    (pc_current),
        .instruction_out (instruction_from_imem)
    );

    // Instruction Register (IR) - latches the fetched instruction
    always_ff @(posedge clk) begin
        if (ir_write)
            instruction_register <= instruction_from_imem;
    end
    assign instruction_out = instruction_register;
    assign funct3 = instruction_register[14:12]; // Extract funct3
    assign funct7 = instruction_register[31:25]; // Extract funct7

    //================================================================
    // 2. Instruction Decode & Operand Fetch (ID) Stage Components
    //================================================================

    // Register File
    register_file reg_file (
        .clk          (clk),
        .reset_n      (reset_n),
        .read_addr1   (instruction_register[19:15]), // rs1
        .read_data1   (reg_file_read_data1),
        .read_addr2   (instruction_register[24:20]), // rs2
        .read_data2   (reg_file_read_data2),
        .write_addr   (instruction_register[11:7]),  // rd
        .write_data   (reg_write_data),              // Data from Write-Back MUX
        .write_enable (reg_write)
    );
    
    // A and B registers to hold operands steady for the ALU
    always_ff @(posedge clk) begin
        if (reg_a_write) reg_a <= reg_file_read_data1;
        if (reg_b_write) reg_b <= reg_file_read_data2;
    end

    // Sign Extender
    sign_extender sign_ext (
        .instruction_in   (instruction_register),
        .imm_type_in      (imm_src),
        .imm_extended_out (sign_extended_imm)
    );

    //================================================================
    // 3. Execute (EX) Stage Components
    //================================================================

    // MUX for ALU input A (selects PC or Register A)
    assign alu_input_a = (alu_src_a == 1'b0) ? reg_a : pc_current;

    // MUX for ALU input B (selects Register B, immediate, or constant 4)
    always_comb begin
        case (alu_src_b)
            2'b00:   alu_input_b = reg_b;
            2'b01:   alu_input_b = sign_extended_imm;
            2'b10:   alu_input_b = 32'd4;
            default: alu_input_b = 32'hxxxxxxxx;
        endcase
    end

    // ALU Control and ALU
    alu_control alu_ctrl (
        .alu_op_type_in (alu_op_type),
        .funct3_in      (funct3),
        .funct7_in      (funct7),
        .alu_op_out     (alu_op)
    );

    alu main_alu (
        .operand1      (alu_input_a),
        .operand2      (alu_input_b),
        .alu_op        (alu_op),
        .result        (alu_result),
        .zero_flag     (alu_zero_flag),
        .negative_flag (), .overflow_flag (), .carry_flag ()
    );

    // ALUOut Register - latches the ALU result
    always_ff @(posedge clk) begin
        if (alu_out_write)
            alu_result_register <= alu_result;
    end

    //================================================================
    // 4. Memory Access (MEM) Stage Components
    //================================================================

    // Data Memory
    data_memory dmem (
        .clk             (clk),
        .addr_in         (alu_result_register), // Address always comes from ALUOut
        .write_data_in   (reg_b),             // Data to store always comes from Register B
        .write_enable    (mem_write),
        .read_enable     (mem_read),
        .read_data_out   (mem_read_data)
    );

    // Memory Data Register (MDR) - latches data read from memory
    always_ff @(posedge clk) begin
        if (mem_read)
            mem_data_register <= mem_read_data;
    end

    //================================================================
    // 5. Write-Back (WB) Stage Components
    //================================================================

    // MUX to select data to be written back to the Register File
    assign reg_write_data = (mem_to_reg == MEM_TO_REG_ALU_RES) ? alu_result_register : mem_data_register;

    //================================================================
    // PC Update Logic
    //================================================================

    // MUX for selecting the next value of the PC
    always_comb begin
        case (pc_source)
            2'b00:   pc_next = alu_result;      // PC + 4 (default)
            2'b01:   pc_next = pc_current + sign_extended_imm; // Branch target (PC + immediate)
            2'b10:   pc_next = alu_result_register; // Jump target (for JALR, if added later)
            default: pc_next = pc_current;
        endcase
    end

    // Simulation-only debug
    initial begin
        $display("Simulation Debug: Monitoring register writes");
        forever @(posedge clk) begin
            if (reg_write) $display("Write to x%d: %h, mem_to_reg: %b", instruction_register[11:7], reg_write_data, mem_to_reg);
        end
    end

endmodule