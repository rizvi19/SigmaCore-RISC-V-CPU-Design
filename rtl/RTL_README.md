# Memory Implementation

This README provides an overview of the implementation of `register_file.sv` and `memory.sv` for the SigmaCore RISC-V CPU Design project.

## Files

- `register_file.sv`: This file contains the SystemVerilog code for the register file module.
- `memory.sv`: This file contains the SystemVerilog code for the memory module.

## Description


### Register File (`register_file.sv`)

The register file is a critical component of the CPU, responsible for storing and providing access to the CPU's registers. It typically includes the following features:
- A set of general-purpose registers.
- Read and write ports for accessing the registers.
- Control logic for handling read and write operations.
- 32 registers with 32 bit each

### Memory (`memory.sv`)

The memory module is responsible for storing instructions and data. It typically includes:
- A memory array for storing data.
- Read and write ports for accessing the memory.
- Control logic for handling memory operations.
- Size: 32x128

# RISC-V has 47 Instructions

Every instructions will be implemented one by one. First we will implement the `add`, `sub`, `and`, `or`, `xor`, `slt` (Set Less than), `sltu` (set less than Unsigned)  instruction in `ALU.sv`.

First of all we will implement the Immediate (I-Type) type instruction. 

![image](https://github.com/user-attachments/assets/0079ef34-2586-4931-9703-0c0daf089c4c)


In this picture from RISC-V architecture we can see that the Immediate value can be in several bits like: `[31:20]`, `[31:25]`, `[11:7]`, `[31:12]`. So, if we want to extract the immediate value then we have to take the the bit `[31:7]` (total `25` bits) and then we have to `Sign Extend` the value. 




Instructions Implementation Order:

LUI
ADDI
ADD
SW


