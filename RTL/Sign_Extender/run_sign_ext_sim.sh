#!/bin/bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

PROJECT_ROOT_DIR="$( dirname "$( dirname "${SCRIPT_DIR}" )" )"

echo "Script directory: ${SCRIPT_DIR}"
echo "Project root: ${PROJECT_ROOT_DIR}"
echo "Compiling Sign Extender and Testbench..."


PKG_FILE="${PROJECT_ROOT_DIR}/packages/sigma_pkg.sv"
DESIGN_FILE="${SCRIPT_DIR}/sign_extender.sv" 
TB_FILE="${SCRIPT_DIR}/sign_ext_tb.sv"
OUTPUT_SIM_FILE="${SCRIPT_DIR}/sign_ext_sim"
VCD_FILE="${SCRIPT_DIR}/sign_ext_waveforms.vcd"


cd "${SCRIPT_DIR}" || exit

iverilog -g2012 -o "${OUTPUT_SIM_FILE}" "${PKG_FILE}" "${DESIGN_FILE}" "${TB_FILE}"

if [ $? -eq 0 ]; then
  echo "Compilation successful. Running simulation..."
  vvp "${OUTPUT_SIM_FILE}" # Run the simulation
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