#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT_DIR="$( dirname "$( dirname "${SCRIPT_DIR}" )" )" # RTL -> ProjectRoot

echo "Script directory: ${SCRIPT_DIR}"
echo "Project root: ${PROJECT_ROOT_DIR}"
echo "Compiling Register File and Testbench..."

PKG_FILE="${PROJECT_ROOT_DIR}/packages/sigma_pkg.sv" # Assuming sigma_pkg might be needed later, though not directly by this regfile
DESIGN_FILE="${SCRIPT_DIR}/register_file.sv"
TB_FILE="${SCRIPT_DIR}/register_file_tb.sv"
OUTPUT_SIM_FILE="${SCRIPT_DIR}/regfile_sim"
VCD_FILE="${SCRIPT_DIR}/regfile_waveforms.vcd"

cd "${SCRIPT_DIR}" || exit

# The register file doesn't strictly depend on sigma_pkg.sv yet,
# but including it won't hurt if other common types were there.
# If sigma_pkg.sv is empty or only contains unrelated items, it's fine.
# Or you can remove PKG_FILE from the command if it causes issues and is not needed.
iverilog -g2012 -o "${OUTPUT_SIM_FILE}" "${DESIGN_FILE}" "${TB_FILE}"
# If you add things to sigma_pkg that might be used by regfile later, use:
# iverilog -g2012 -o "${OUTPUT_SIM_FILE}" "${PKG_FILE}" "${DESIGN_FILE}" "${TB_FILE}"


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