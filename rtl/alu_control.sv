// SigmaCore Project: ALU Control Unit
// This module takes a high-level command from the main control unit
// and the instruction's funct fields to generate the final 4-bit op-code for the ALU.
// It is purely combinational logic.

`timescale 1ns/1ps

module alu_control (
    // Inputs
    input  logic [1:0] alu_op_type_in, // High-level command from Main Control Unit
    input  logic [2:0] funct3_in,      // Funct3 field from instruction
    input  logic [6:0] funct7_in,      // Funct7 field from instruction

    // Output
    output logic [3:0] alu_op_out      // 4-bit operation code for the ALU
);

    import sigma_pkg::*;

    always_comb begin
        // By default, let's make the operation ADD.
        // Specific cases below will override this.
        alu_op_out = ALU_ADD;

        case (alu_op_type_in)
            // For R-Type and I-Type (e.g., add, addi), we need to look at funct3/funct7.
            // This is where we will add more logic for other arithmetic instructions.
            ALU_OP_TYPE_R_I: begin
                case (funct3_in)
                    FUNCT3_ADD: begin
                        // For this funct3, ADD and SUB are possible. We check funct7.
                        // For ADDI, funct7 is not used, but it will match the ADD case.
                        if (funct7_in == FUNCT7_ADD) begin
                            alu_op_out = ALU_ADD;
                        end
                        // We will add the 'else if' for SUB later.
                    end
                    // Other cases for slt, and, or, etc., will be added here later.
                    default: alu_op_out = ALU_ADD; // Default to ADD for this type for now
                endcase
            end

            // For Load/Store instructions, the ALU is always used to calculate
            // the address by adding the register value and the immediate offset.
            ALU_OP_TYPE_LSU: begin
                alu_op_out = ALU_ADD;
            end

            // For LUI, we want the ALU to simply pass the immediate value through.
            // We use a special "COPY B" operation in the ALU for this.
            ALU_OP_TYPE_LUI: begin
                alu_op_out = ALU_COPY_B;
            end

            default: alu_op_out = ALU_ADD; // Default to ADD for any unknown op_type
        endcase
    end

endmodule
