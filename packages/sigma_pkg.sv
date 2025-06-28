// This is the package file for the SigmaCore RISC-V CPU Design

package sigma_pkg; 

    /*
    -----------------------------------------------------------
    For ALU operations
    -----------------------------------------------------------
    */

    parameter logic [3:0] ALU_ADD   = 4'b0000;
    parameter logic [3:0] ALU_SUB   = 4'b0001;
    parameter logic [3:0] ALU_AND   = 4'b0010;
    parameter logic [3:0] ALU_OR    = 4'b0011;
    parameter logic [3:0] ALU_XOR   = 4'b0100;
    parameter logic [3:0] ALU_SLL   = 4'b0101; 
    parameter logic [3:0] ALU_SRL   = 4'b0110; 
    parameter logic [3:0] ALU_SRA   = 4'b0111; 
    parameter logic [3:0] ALU_SLT   = 4'b1000;
    parameter logic [3:0] ALU_SLTU  = 4'b1001;
    parameter logic [3:0] ALU_COPY_B = 4'b1010; 
    // New ALU operations
    parameter logic [3:0] ALU_SLTI  = 4'b1011; // For SLTI (reusing I-type ALU logic)


    /*
    -------------------------------------------
    For Immediate values, for sign extender
    -------------------------------------------
    */

    parameter logic [2:0] IMM_TYPE_NONE = 3'b000; // No immediate
    parameter logic [2:0] IMM_TYPE_I    = 3'b001; // For I-type instructions (loads, immediate arithmetic, JALR)
    parameter logic [2:0] IMM_TYPE_S    = 3'b010; // For S-type instructions (stores)
    parameter logic [2:0] IMM_TYPE_B    = 3'b011; // For B-type instructions (conditional branches)
    parameter logic [2:0] IMM_TYPE_U    = 3'b100; // For U-type instructions (LUI, AUIPC)
    parameter logic [2:0] IMM_TYPE_J    = 3'b101;
    // New Immediate Types
    parameter logic [2:0] IMM_TYPE_SLTI = 3'b110; // For SLTI (same as I-type but distinct for clarity)
    parameter logic [2:0] IMM_TYPE_LW   = 3'b111; // For LW (I-type variant)


    /*
    ------------------------------------------
    RV32I Opcodes
    7 bits opcode
    ------------------------------------------
    */

    parameter logic [6:0] OPCODE_LUI    = 7'b0110111; // U-Type: Load Upper Immediate
    parameter logic [6:0] OPCODE_STORE  = 7'b0100011; // S-Type: Stores (sw, sh, sb)
    parameter logic [6:0] OPCODE_IMM    = 7'b0010011; // I-Type: Immediate arithmetic (addi, slti, etc.)
    parameter logic [6:0] OPCODE_RTYPE  = 7'b0110011; // R-Type: Register-register arithmetic (add, sub, and, or, xor, slt, sll, srl, sra, etc.)
    parameter logic [6:0] OPCODE_LOAD   = 7'b0000011; // Opcode for lw, lh, lb
    parameter logic [6:0] OPCODE_BRANCH = 7'b1100011; // Opcode for beq, bne, etc.
    // New Opcodes (some reuse existing, differentiated by funct3/funct7)
    parameter logic [6:0] OPCODE_SLTI   = 7'b0010011; // I-Type: SLTI (funct3 = 010)
    parameter logic [6:0] OPCODE_BEQ    = 7'b1100011; // B-Type: BEQ (funct3 = 000)


    /*
    ------------------------------------------
    funct3 and funct7 values
    ------------------------------------------
    */

    // For R-Type and I-Type Immediate
    parameter logic [2:0] FUNCT3_ADD = 3'b000;
    // For Store Word (SW)
    parameter logic [2:0] FUNCT3_SW  = 3'b010;
    // New funct3 values
    parameter logic [2:0] FUNCT3_SUB = 3'b000; // Differentiated by funct7
    parameter logic [2:0] FUNCT3_AND = 3'b111;
    parameter logic [2:0] FUNCT3_OR  = 3'b110;
    parameter logic [2:0] FUNCT3_XOR = 3'b100;
    parameter logic [2:0] FUNCT3_SLT = 3'b010;
    parameter logic [2:0] FUNCT3_SLL = 3'b001;
    parameter logic [2:0] FUNCT3_SRL = 3'b101; // Differentiated by funct7
    parameter logic [2:0] FUNCT3_SRA = 3'b101; // Differentiated by funct7
    parameter logic [2:0] FUNCT3_LW  = 3'b010;
    parameter logic [2:0] FUNCT3_BEQ = 3'b000;

    // For R-Type, funct7 differentiates between ADD and SUB, and other operations
    parameter logic [6:0] FUNCT7_ADD = 7'b0000000;
    parameter logic [6:0] FUNCT7_SUB = 7'b0100000;
    parameter logic [6:0] FUNCT7_SRA = 7'b0100000; // Shared with SUB


    /*
    ------------------------------------------
    Control Signals from Main Control Unit
    ------------------------------------------
    */

    // Selects the source for the second ALU operand.
    // 0: from Register File (rs2), 1: from Sign Extender (immediate)
    parameter logic       ALU_SRC_REG = 1'b0;
    parameter logic       ALU_SRC_IMM = 1'b1;

    // Selects what data to write back to the Register File.
    // 0: from the ALU result, 1: from the Data Memory (for loads)
    parameter logic       MEM_TO_REG_ALU_RES  = 1'b0;
    parameter logic       MEM_TO_REG_MEM_DATA = 1'b1;

    // Defines the main operation type for the ALU Control unit.
    // This signal simplifies the main control unit's logic.
    parameter logic [1:0] ALU_OP_TYPE_R_I = 2'b00; // For R-Type and I-Type (decode funct3/7)
    parameter logic [1:0] ALU_OP_TYPE_LSU = 2'b01; // For Load/Store (ALU does ADD for address)
    parameter logic [1:0] ALU_OP_TYPE_LUI = 2'b10; // For LUI (ALU passes immediate through)


    /*
    -------------------------------------------------------------------------------------------------
    FSM States for Multicycle Control Unit
    Based on the state diagram from Harris & Harris, Ch. 7
    -------------------------------------------------------------------------------------------------
    */
    
    parameter logic [3:0] S_FETCH          = 4'd0;  // Instruction Fetch
    parameter logic [3:0] S_DECODE         = 4'd1;  // Instruction Decode and Register Fetch
    parameter logic [3:0] S_MEM_ADDR_COMP  = 4'd2;  // Memory Address Computation (for LW/SW)
    parameter logic [3:0] S_MEM_WRITE      = 4'd3;  // Memory Write (for SW)
    parameter logic [3:0] S_EXEC_R_TYPE    = 4'd4;  // R-Type Execution (ADD, SUB, etc....)
    parameter logic [3:0] S_WB_R_TYPE      = 4'd5;  // R-Type Write-Back
    parameter logic [3:0] S_EXEC_I_TYPE    = 4'd6;  // I-Type Execution (ADDI, SLTI, etc...)
    parameter logic [3:0] S_WB_I_TYPE      = 4'd7;  // I-Type and LUI Write-Back
    // New FSM States
    parameter logic [3:0] S_EXEC_R_TYPE_LOG = 4'd8;  // For AND, OR, XOR
    parameter logic [3:0] S_WB_R_TYPE_LOG   = 4'd9;  // Write-back for AND, OR, XOR
    parameter logic [3:0] S_EXEC_R_TYPE_SLT = 4'd10; // For SLT
    parameter logic [3:0] S_WB_R_TYPE_SLT   = 4'd11; // Write-back for SLT
    parameter logic [3:0] S_EXEC_R_TYPE_SHIFT = 4'd12; // For SLL, SRL, SRA
    parameter logic [3:0] S_WB_R_TYPE_SHIFT  = 4'd13; // Write-back for SLL, SRL, SRA
    parameter logic [3:0] S_MEM_READ        = 4'd14; // For LW
    parameter logic [3:0] S_WB_MEM          = 4'd15; // Write-back for LW
    parameter logic [3:0] S_BRANCH          = 4'd16; // For BEQ

endpackage