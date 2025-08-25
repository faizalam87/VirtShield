#!/bin/bash

SERVER_IP="192.168.10.5"
OUTPUT_FILE="../Results/redis/results_"$1".txt"
NUM_REQUEST="1000000"
CONNECTIONS="50"

# Run benchmark

redis-benchmark -h $SERVER_IP -c $CONNECTIONS -n $NUM_REQUEST -t get,set > $OUTPUT_FILE