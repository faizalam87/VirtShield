#!/bin/bash

OUTPUT_FILE="$1"

# Add header to the output file
echo "CPUPerc,MemUsage,NetIO,BlockIO" > "$OUTPUT_FILE"

while true; do
    docker stats firewall --no-stream --format "{{.CPUPerc}},{{.MemUsage}},{{.NetIO}},{{.BlockIO}}" >> "$OUTPUT_FILE"
    sleep 1
done