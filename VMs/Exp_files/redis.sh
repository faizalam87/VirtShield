#!/bin/bash

SERVER_IP="192.168.10.5"
OUTPUT_FILE="redis_results.txt"
RUN_TIME="60"  
CONNECTIONS="50"

# Run benchmark

redis-benchmark -h $SERVER_IP -c $CONNECTIONS -t $RUN_TIME > $OUTPUT_FILE