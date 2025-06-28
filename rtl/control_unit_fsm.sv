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
    input  logic [2:0]  funct3,       // funct3 field for R-type differentiation
    input  logic [6:0]  funct7,       // funct7 field for R-type differentiation
    input  logic        alu_zero_flag, // Added to determine branch condition

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
                // DECODE --> based on the instruction's opcode and funct3/funct7
                case (opcode)
                    OPCODE_LUI:    next_state = S_WB_I_TYPE;
                    OPCODE_IMM:    next_state = S_EXEC_I_TYPE;
                    OPCODE_RTYPE: begin
                        case (funct3)
                            FUNCT3_ADD:  next_state = (funct7 == FUNCT7_SUB) ? S_EXEC_R_TYPE : S_EXEC_R_TYPE; // SUB or ADD
                            FUNCT3_AND:  next_state = S_EXEC_R_TYPE_LOG;
                            FUNCT3_OR:   next_state = S_EXEC_R_TYPE_LOG;
                            FUNCT3_XOR:  next_state = S_EXEC_R_TYPE_LOG;
                            FUNCT3_SLT:  next_state = S_EXEC_R_TYPE_SLT;
                            FUNCT3_SLL:  next_state = S_EXEC_R_TYPE_SHIFT;
                            FUNCT3_SRL:  next_state = (funct7 == FUNCT7_SRA) ? S_EXEC_R_TYPE_SHIFT : S_EXEC_R_TYPE_SHIFT; // SRA or SRL
                            default:     next_state = S_FETCH;
                        endcase
                    end
                    OPCODE_LOAD:   next_state = S_MEM_READ;
                    OPCODE_STORE:  next_state = S_MEM_ADDR_COMP;
                    OPCODE_BRANCH: next_state = S_BRANCH;
                    default:       next_state = S_FETCH; // If opcode is unknown, start over
                endcase
            end

            S_MEM_ADDR_COMP: begin // For SW
                next_state = S_MEM_WRITE;
            end

            S_MEM_WRITE: begin // For SW
                next_state = S_FETCH; // Write --> Fetch next instruction
            end

            S_MEM_READ: begin // For LW
                next_state = S_WB_MEM;
            end

            S_WB_MEM: begin // For LW
                next_state = S_FETCH;
            end

            S_EXEC_R_TYPE: begin // For ADD
                next_state = S_WB_R_TYPE;
            end

            S_WB_R_TYPE: begin // For ADD
                next_state = S_FETCH; // Write --> Fetch next instruction
            end

            S_EXEC_R_TYPE_LOG: begin // For AND, OR, XOR
                next_state = S_WB_R_TYPE_LOG;
            end

            S_WB_R_TYPE_LOG: begin // For AND, OR, XOR
                next_state = S_FETCH;
            end

            S_EXEC_R_TYPE_SLT: begin // For SLT
                next_state = S_WB_R_TYPE_SLT;
            end

            S_WB_R_TYPE_SLT: begin // For SLT
                next_state = S_FETCH;
            end

            S_EXEC_R_TYPE_SHIFT: begin // For SLL, SRL, SRA
                next_state = S_WB_R_TYPE_SHIFT;
            end

            S_WB_R_TYPE_SHIFT: begin // For SLL, SRL, SRA
                next_state = S_FETCH;
            end

            S_EXEC_I_TYPE: begin // For ADDI, SLTI
                next_state = S_WB_I_TYPE;
            end

            S_WB_I_TYPE: begin // For ADDI, SLTI, LUI
                next_state = S_FETCH; // Write --> Fetch next instruction
            end

            S_BRANCH: begin // For BEQ
                next_state = S_FETCH;
            end
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

            S_MEM_READ: begin // For LW
                // Read data from memory at calculated address
                mem_read = 1'b1;
                alu_src_a = 1'b0;           // ALU Input A = Register A (from rs1)
                alu_src_b = 2'b01;          // ALU Input B = Immediate
                imm_src   = IMM_TYPE_LW;    // Use I-type immediate format
                alu_op_type = ALU_OP_TYPE_LSU; // Tell ALU to ADD for address
                alu_out_write = 1'b1;
            end

            S_WB_MEM: begin // For LW
                // Write the memory data back to the register file
                reg_write  = 1'b1;
                mem_to_reg = MEM_TO_REG_MEM_DATA; // Data comes from memory
            end

            S_EXEC_R_TYPE: begin // For ADD
                // Execute operation: rs1 + rs2
                alu_src_a   = 1'b0;         // ALU Input A = Register A (from rs1)
                alu_src_b   = 2'b00;        // ALU Input B = Register B (from rs2)
                alu_op_type = ALU_OP_TYPE_R_I; // Tell ALU control to decode funct3/7 for ADD
                alu_out_write = 1'b1;
            end

            S_WB_R_TYPE: begin // For ADD
                // Write the result from ALUOut back to the register file
                reg_write  = 1'b1;
                mem_to_reg = MEM_TO_REG_ALU_RES; // Data comes from the ALU
            end

            S_EXEC_R_TYPE_LOG: begin // For AND, OR, XOR
                // Execute logical operation: rs1 op rs2
                alu_src_a   = 1'b0;         // ALU Input A = Register A (from rs1)
                alu_src_b   = 2'b00;        // ALU Input B = Register B (from rs2)
                alu_op_type = ALU_OP_TYPE_R_I; // Tell ALU control to decode funct3 for AND/OR/XOR
                alu_out_write = 1'b1;
            end

            S_WB_R_TYPE_LOG: begin // For AND, OR, XOR
                // Write the result back to the register file
                reg_write  = 1'b1;
                mem_to_reg = MEM_TO_REG_ALU_RES; // Data comes from the ALU
            end

            S_EXEC_R_TYPE_SLT: begin // For SLT
                // Execute comparison: set if rs1 < rs2
                alu_src_a   = 1'b0;         // ALU Input A = Register A (from rs1)
                alu_src_b   = 2'b00;        // ALU Input B = Register B (from rs2)
                alu_op_type = ALU_OP_TYPE_R_I; // Tell ALU control to decode for SLT
                alu_out_write = 1'b1;
            end

            S_WB_R_TYPE_SLT: begin // For SLT
                // Write the result back to the register file
                reg_write  = 1'b1;
                mem_to_reg = MEM_TO_REG_ALU_RES; // Data comes from the ALU
            end

            S_EXEC_R_TYPE_SHIFT: begin // For SLL, SRL, SRA
                // Execute shift operation: rs1 shifted by rs2[4:0]
                alu_src_a   = 1'b0;         // ALU Input A = Register A (from rs1)
                alu_src_b   = 2'b00;        // ALU Input B = Register B (from rs2)
                alu_op_type = ALU_OP_TYPE_R_I; // Tell ALU control to decode funct3/funct7 for SLL/SRL/SRA
                alu_out_write = 1'b1;
            end

            S_WB_R_TYPE_SHIFT: begin // For SLL, SRL, SRA
                // Write the result back to the register file
                reg_write  = 1'b1;
                mem_to_reg = MEM_TO_REG_ALU_RES; // Data comes from the ALU
            end

            S_EXEC_I_TYPE: begin // For ADDI, SLTI
                // Execute operation: rs1 + immediate
                alu_src_a   = 1'b0;         // ALU Input A = Register A (from rs1)
                alu_src_b   = 2'b01;        // ALU Input B = Immediate
                imm_src     = (funct3 == FUNCT3_SLT) ? IMM_TYPE_SLTI : IMM_TYPE_I; // ADDI or SLTI
                alu_op_type = ALU_OP_TYPE_R_I; // Tell ALU control to decode funct3 for ADDI/SLTI
                alu_out_write = 1'b1;
            end

            S_WB_I_TYPE: begin // For ADDI, SLTI, LUI
                // LUI bypasses execute and comes here directly.
                // For ADDI/SLTI, this writes the ALU result.
                reg_write  = 1'b1;
                mem_to_reg = MEM_TO_REG_ALU_RES; // Data comes from ALU path (which for LUI is just the immediate)
            end

            S_BRANCH: begin // For BEQ
                // Compare rs1 and rs2, update PC if equal
                alu_src_a   = 1'b0;         // ALU Input A = Register A (from rs1)
                alu_src_b   = 2'b00;        // ALU Input B = Register B (from rs2)
                imm_src     = IMM_TYPE_B;   // Use B-type immediate for branch offset
                alu_op_type = ALU_OP_TYPE_R_I; // Use ALU for comparison
                pc_write    = alu_zero_flag; // Set pc_write based on ALU zero flag
                pc_source   = 2'b01;        // Select branch target (PC + immediate)
            end
        endcase
    end

    // Simulation-only debug
    initial begin
        $display("Simulation Debug: Monitoring FSM states and opcodes");
        forever @(posedge clk or negedge reset_n) begin
            if (reset_n) $display("State: %d, Opcode: %h", current_state, opcode);
        end
    end

endmodule