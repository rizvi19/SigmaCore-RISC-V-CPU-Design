#!/bin/bash

# Get the project root directory relative to the script's location
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && cd .. && pwd )"

echo "Project Root: ${PROJECT_ROOT}"
echo "Compiling all CPU modules and top-level testbench..."

# Change directory to where the test program is, so $readmemh can find it
cd "${PROJECT_ROOT}/test/programs" || exit

# Compile all necessary .sv files. Note the use of -I to include the rtl directory.
iverilog -g2012 -o "${PROJECT_ROOT}/test/cpu_sim" \
         -I "${PROJECT_ROOT}/rtl" \
         "${PROJECT_ROOT}/packages/sigma_pkg.sv" \
         "${PROJECT_ROOT}/rtl/multicycle_cpu.sv" \
         "${PROJECT_ROOT}/rtl/control_unit_fsm.sv" \
         "${PROJECT_ROOT}/rtl/alu.sv" \
         "${PROJECT_ROOT}/rtl/alu_control.sv" \
         "${PROJECT_ROOT}/rtl/data_memory.sv" \
         "${PROJECT_ROOT}/rtl/instruction_decoder.sv" \
         "${PROJECT_ROOT}/rtl/instruction_memory.sv" \
         "${PROJECT_ROOT}/rtl/register_file.sv" \
         "${PROJECT_ROOT}/rtl/sign_extender.sv" \
         "${PROJECT_ROOT}/rtl/sigmacore_top.sv" \
         "${PROJECT_ROOT}/test/tb_sigmacore_top.sv"

# Check for compilation success
if [ $? -eq 0 ]; then
  echo "Compilation successful. Running simulation..."
  vvp "${PROJECT_ROOT}/test/cpu_sim"
  echo "Simulation finished."
  
  if [ -f "cpu_waveforms.vcd" ]; then
    echo "VCD file found in test/programs/. Opening waveforms with GTKWave..."
    gtkwave "cpu_waveforms.vcd" &
  else
    echo "ERROR: VCD file 'cpu_waveforms.vcd' not found after simulation!"
  fi
else
  echo "Compilation failed."
fi