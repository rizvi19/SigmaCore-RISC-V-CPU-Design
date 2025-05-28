// This is the package file for the SigmaCore RISC-V CPU Design

package sigma_pkg; 

    // For ALU operations
    parameter logic [3:0] ALU_ADD = 4'b0000;
    parameter logic [3:0] ALU_SUB = 4'b0001;
    parameter logic [3:0] ALU_AND = 4'b0010;
    parameter logic [3:0] ALU_OR  = 4'b0011;
    parameter logic [3:0] ALU_XOR = 4'b0100;
    parameter logic [3:0] ALU_SLL = 4'b0101; 
    parameter logic [3:0] ALU_SRL = 4'b0110; 
    parameter logic [3:0] ALU_SRA = 4'b0111; 

    // For Immediate values, for sign extender
    parameter logic [2:0] IMM_TYPE_NONE = 3'b000; // No immediate
    parameter logic [2:0] IMM_TYPE_I    = 3'b001; // For I-type instructions (loads, immediate arithmetic, JALR)
    parameter logic [2:0] IMM_TYPE_S    = 3'b010; // For S-type instructions (stores)
    parameter logic [2:0] IMM_TYPE_B    = 3'b011; // For B-type instructions (conditional branches)
    parameter logic [2:0] IMM_TYPE_U    = 3'b100; // For U-type instructions (LUI, AUIPC)
    parameter logic [2:0] IMM_TYPE_J    = 3'b101;

endpackage