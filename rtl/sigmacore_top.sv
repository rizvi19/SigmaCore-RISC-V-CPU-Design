/*
---------------------------------------------------
File: sigmacore_top.sv
Description: Top-level module for the SigmaCore CPU
Author: Shahriar Rizvi
---------------------------------------------------
*/

`timescale 1ns/1ps

module sigmacore_top (
    // System Inputs
    input  logic        clk,
    input  logic        reset_n,

    output logic [31:0] final_pc_out,
    output logic [31:0] final_instruction_out
);

    logic        pc_write;
    logic        ir_write;
    logic        reg_write;
    logic        mem_write;
    logic        mem_read;
    logic [1:0]  pc_source;
    logic        mem_to_reg;
    logic        alu_src_a;
    logic [1:0]  alu_src_b;
    logic [2:0]  imm_src;
    logic [1:0]  alu_op_type;
    logic        reg_a_write;
    logic        reg_b_write;
    logic        alu_out_write;

    logic [6:0] opcode_from_datapath;


    // 1. Instantiate the FSM Control Unit
    control_unit_fsm fsm_ctrl (
        .clk        (clk),
        .reset_n    (reset_n),
        .opcode     (opcode_from_datapath),
        // Control Signal Outputs
        .pc_write      (pc_write),
        .ir_write      (ir_write),
        .reg_write     (reg_write),
        .mem_write     (mem_write),
        .mem_read      (mem_read),
        .pc_source     (pc_source),
        .mem_to_reg    (mem_to_reg),
        .alu_src_a     (alu_src_a),
        .alu_src_b     (alu_src_b),
        .imm_src       (imm_src),
        .alu_op_type   (alu_op_type),
        .reg_a_write   (reg_a_write),
        .reg_b_write   (reg_b_write),
        .alu_out_write (alu_out_write)
    );

    // 2. Instantiate the Multicycle Datapath
    multicycle_cpu datapath (
        .clk           (clk),
        .reset_n       (reset_n),
        // Control Signal Inputs
        .pc_write      (pc_write),
        .ir_write      (ir_write),
        .reg_write     (reg_write),
        .mem_write     (mem_write),
        .mem_read      (mem_read),
        .pc_source     (pc_source),
        .mem_to_reg    (mem_to_reg),
        .alu_src_a     (alu_src_a),
        .alu_src_b     (alu_src_b),
        .imm_src       (imm_src),
        .alu_op_type   (alu_op_type),
        .reg_a_write   (reg_a_write),
        .reg_b_write   (reg_b_write),
        .alu_out_write (alu_out_write),
        // Debugging Outputs
        .current_pc_out    (final_pc_out),
        .instruction_out   (final_instruction_out)
    );

    // The opcode is part of the instruction output from the datapath
    assign opcode_from_datapath = final_instruction_out[6:0];

endmodule
