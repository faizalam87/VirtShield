#!/bin/bash

# Check if a PID is provided as an argument
if [ -z "$1" ]; then
  echo "Error: Please provide the PID of the process."
  echo "Usage: $0 <PID>"
  exit 1
fi

# Set the PID from the command-line argument
PID=$1

# Set the duration of the benchmark (in seconds)
DURATION=65

# Output file for results
OUTPUT="perf_hardware_full_results.txt"

echo "Starting perf monitoring for PID: $PID for $DURATION seconds..."

# Run perf with all hardware events and save the results
sudo perf stat -p "$PID" \
  -e branch-instructions,branch-misses,bus-cycles,cache-misses,cache-references,cpu-cycles,instructions,ref-cycles \
  -e alignment-faults,bpf-output,cgroup-switches,context-switches,cpu-clock,cpu-migrations,dummy,emulation-faults,major-faults,minor-faults,page-faults,task-clock,duration_time,user_time,system_time sleep $DURATION > $OUTPUT 2>&1

echo "Perf monitoring completed. Results saved to $OUTPUT."

# Now, extract and display key metrics from the perf results
echo "Extracting key metrics from the results..."

# Extract and display CPU cycles, instructions, and cache misses
echo "CPU Cycles, Instructions, and Cache Misses:"
grep -E "cpu-cycles|instructions|cache-misses" $OUTPUT

# Extract and display branch instructions and mispredictions
echo "Branch Instructions and Branch Mispredictions:"
grep -E "branch-instructions|branch-misses" $OUTPUT

# Extract and display context switches and page faults
echo "Context Switches and Page Faults:"
grep -E "context-switches|page-faults" $OUTPUT

# Extract and display other relevant metrics like bus cycles and task clock
echo "Bus Cycles and Task Clock:"
grep -E "bus-cycles|task-clock" $OUTPUT

# Optionally, show the full result
echo "Full perf results:"
cat $OUTPUT


