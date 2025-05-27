#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Project root is two levels up from the script's directory (RTL/ALU -> RTL -> ProjectRoot)
PROJECT_ROOT_DIR="$( dirname "$( dirname "${SCRIPT_DIR}" )" )"

echo "Script directory: ${SCRIPT_DIR}"
echo "Project root: ${PROJECT_ROOT_DIR}"
echo "Compiling ALU and Testbench..."

# Paths to files relative to the script or project root
PKG_FILE="${PROJECT_ROOT_DIR}/packages/sigma_pkg.sv"
ALU_FILE="${SCRIPT_DIR}/alu.sv"
ALU_TB_FILE="${SCRIPT_DIR}/alu_tb.sv"
OUTPUT_SIM_FILE="${SCRIPT_DIR}/alu_sim"
VCD_FILE="${SCRIPT_DIR}/alu_waveforms.vcd"

# Change to the script's directory to ensure output files are created here
cd "${SCRIPT_DIR}" || exit

iverilog -g2012 -o "${OUTPUT_SIM_FILE}" "${PKG_FILE}" "${ALU_FILE}" "${ALU_TB_FILE}"

if [ $? -eq 0 ]; then
  echo "Compilation successful. Running simulation..."
  vvp "${OUTPUT_SIM_FILE}"
  echo "Simulation finished. Opening waveforms..."
  gtkwave "${VCD_FILE}" & # Added '&' to run gtkwave in background
else
  echo "Compilation failed."
fi