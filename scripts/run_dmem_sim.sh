#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT_DIR="$( dirname "$( dirname "${SCRIPT_DIR}" )" )"

echo "Compiling Data Memory and Testbench..."

DESIGN_FILE="${SCRIPT_DIR}/data_memory.sv"
TB_FILE="${SCRIPT_DIR}/dmem_tb.sv"
OUTPUT_SIM_FILE="${SCRIPT_DIR}/dmem_sim"
VCD_FILE="${SCRIPT_DIR}/dmem_waveforms.vcd"

cd "${SCRIPT_DIR}" || exit

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