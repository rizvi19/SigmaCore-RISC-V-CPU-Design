/*
-------------------------------------------------------------
File: control_unit_fsm.sv
Description: Finite State Machine (FSM) for the Control Unit 
Author: Shahriar Rizvi
-------------------------------------------------------------
*/



`timescale 1ns/1ps

module control_unit_fsm (
    // System Inputs
    input  logic        clk,
    input  logic        reset_n,

    input  logic [6:0]  opcode,       // Opcode of the current instruction

    // Control Signal Outputs to Datapath
    output logic        pc_write,
    output logic        ir_write,
    output logic        reg_write,
    output logic        mem_write,
    output logic        mem_read,
    output logic [1:0]  pc_source,
    output logic        mem_to_reg,
    output logic        alu_src_a,
    output logic [1:0]  alu_src_b,
    output logic [2:0]  imm_src,
    output logic [1:0]  alu_op_type,
    output logic        reg_a_write,
    output logic        reg_b_write,
    output logic        alu_out_write
);

    import sigma_pkg::*;

    // FSM state registers
    logic [3:0] current_state, next_state;




    //==================================================================
    // 1. State Register Logic (Sequential)
    //    Handles state transitions on the clock edge.
    //==================================================================


    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            current_state <= S_FETCH; // Initial State: Fetch
        else
            current_state <= next_state; // Clock ticks --> Go to next state
    end





    //==================================================================
    // 2. Next State Logic (Combinational)
    //    Determines the next state based on current state and inputs.
    //==================================================================
    always_comb begin
        next_state = S_FETCH;
        case (current_state)

            S_FETCH: begin
                // Fetch --> Decode
                next_state = S_DECODE;
            end

            S_DECODE: begin
                // DECODE --> based on the instruction's opcode.
                case (opcode)
                    OPCODE_LUI:   next_state = S_WB_I_TYPE; 
                    OPCODE_IMM:   next_state = S_EXEC_I_TYPE;
                    OPCODE_RTYPE: next_state = S_EXEC_R_TYPE;
                    OPCODE_STORE: next_state = S_MEM_ADDR_COMP;
                    default:      next_state = S_FETCH; // If opcode is unknown, start over
                endcase
            end


            S_MEM_ADDR_COMP: begin // For SW
                next_state = S_MEM_WRITE;
            end


            S_MEM_WRITE: begin // For SW
                next_state = S_FETCH; // Write --> Fetch next instruction
            end


            S_EXEC_R_TYPE: begin // For ADD
                next_state = S_WB_R_TYPE;
            end
            

            S_WB_R_TYPE: begin // For ADD
                next_state = S_FETCH; // Write --> Fetch next instruction
            end


            S_EXEC_I_TYPE: begin // For ADDI
                next_state = S_WB_I_TYPE;
            end

            S_WB_I_TYPE: begin // For ADDI and LUI
                next_state = S_FETCH; // Write --> Fetch next instruction
            end
            
            // default: begin
            //     next_state = S_FETCH; // Invalid state --> FETCH
            // end
        endcase
    end




    //==================================================================
    // 3. Output Logic (Combinational)
    //    Generates control signals based on the CURRENT state. (Moore FSM)
    //==================================================================

    always_comb begin
        // First, set all control signals to their default "off" or "safe" values
        pc_write      = 1'b0;
        ir_write      = 1'b0;
        reg_write     = 1'b0;
        mem_write     = 1'b0;
        mem_read      = 1'b0;
        pc_source     = 2'b00;
        mem_to_reg    = MEM_TO_REG_ALU_RES;
        alu_src_a     = 1'b0; // Default to reading from Register A
        alu_src_b     = 2'b00; // Default to reading from Register B
        imm_src       = IMM_TYPE_NONE;
        alu_op_type   = ALU_OP_TYPE_R_I;
        reg_a_write   = 1'b0;
        reg_b_write   = 1'b0;
        alu_out_write = 1'b0;

        case(current_state)
            S_FETCH: begin
                // Fetch instruction from memory at PC, increment PC
                mem_read    = 1'b1;         
                ir_write    = 1'b1;         // Latch the instruction into the IR
                pc_write    = 1'b1;         // Prepare to update the PC
                alu_src_a   = 1'b1;         // ALU Input A = PC
                alu_src_b   = 2'b10;        // ALU Input B = 4
                alu_op_type = ALU_OP_TYPE_LSU; // Tell ALU to ADD to calculate PC+4
            end

            S_DECODE: begin
                // Decode instruction, read operands from Register File
                reg_a_write = 1'b1; // Latch rs1 data into register A
                reg_b_write = 1'b1; // Latch rs2 data into register B
                alu_out_write = 1'b1; // Prepare ALUOut to latch in the next state
            end

            S_MEM_ADDR_COMP: begin // For SW
                // Calculate memory address: rs1 + immediate
                alu_src_a   = 1'b0;         // ALU Input A = Register A (from rs1)
                alu_src_b   = 2'b01;        // ALU Input B = Immediate
                imm_src     = IMM_TYPE_S;   // Use S-type immediate format
                alu_op_type = ALU_OP_TYPE_LSU; // Tell ALU to ADD
                alu_out_write = 1'b1;
            end
            
            S_MEM_WRITE: begin // For SW
                // Write data from Register B to memory
                mem_write = 1'b1;
            end
            S_EXEC_R_TYPE: begin // For ADD
                // Execute operation: rs1 + rs2
                alu_src_a   = 1'b0;         // ALU Input A = Register A (from rs1)
                alu_src_b   = 2'b00;        // ALU Input B = Register B (from rs2)
                alu_op_type = ALU_OP_TYPE_R_I; // Tell ALU control to decode funct3/7
                alu_out_write = 1'b1;
            end
            S_WB_R_TYPE: begin // For ADD
                // Write the result from ALUOut back to the register file
                reg_write  = 1'b1;
                mem_to_reg = MEM_TO_REG_ALU_RES; // Data comes from the ALU
            end
            S_EXEC_I_TYPE: begin // For ADDI
                // Execute operation: rs1 + immediate
                alu_src_a   = 1'b0;         // ALU Input A = Register A (from rs1)
                alu_src_b   = 2'b01;        // ALU Input B = Immediate
                imm_src     = IMM_TYPE_I;   // Use I-type immediate format
                alu_op_type = ALU_OP_TYPE_R_I; // Tell ALU control to decode funct3
                alu_out_write = 1'b1;
            end
            S_WB_I_TYPE: begin // For ADDI and LUI
                // LUI bypasses execute and comes here directly.
                // For ADDI, this writes the ALU result.
                // For LUI, this writes the sign-extended immediate.
                reg_write  = 1'b1;
                mem_to_reg = MEM_TO_REG_ALU_RES; // Data comes from ALU path (which for LUI is just the immediate)
            end
        endcase
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) current_state <= S_FETCH;
        else current_state <= next_state;
        $display("State: %d, Opcode: %h", current_state, opcode);
    end

endmodule