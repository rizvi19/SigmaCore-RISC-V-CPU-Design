#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT_DIR="$( dirname "$( dirname "${SCRIPT_DIR}" )" )"

echo "Compiling Instruction Memory and Testbench..."

DESIGN_FILE="${SCRIPT_DIR}/instruction_memory.sv" # Using the new module name
TB_FILE="${SCRIPT_DIR}/imem_tb.sv"
OUTPUT_SIM_FILE="${SCRIPT_DIR}/imem_sim"
VCD_FILE="${SCRIPT_DIR}/imem_waveforms.vcd"

cd "${SCRIPT_DIR}" || exit

# Check if program.hex exists
if [ ! -f "program.hex" ]; then
    echo "ERROR: 'program.hex' not found. Please create it in the RTL/Memory directory."
    exit 1
fi

iverilog -g2012 -o "${OUTPUT_SIM_FILE}" "${DESIGN_FILE}" "${TB_FILE}"

if [ $? -eq 0 ]; then
  echo "Compilation successful. Running simulation..."
  vvp "${OUTPUT_SIM_FILE}"
  echo "Simulation finished."
  
  if [ -f "${VCD_FILE}" ]; then
    echo "VCD file found. Opening waveforms with GTKWave..."
    gtkwave "${VCD_FILE}" &
  else
    echo "ERROR: VCD file '${VCD_FILE}' not found after simulation!"
  fi
else
  echo "Compilation failed."
fi