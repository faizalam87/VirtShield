#!/bin/bash

SERVER_IP="192.168.2.3"
OUTPUT_FILE="../Results/redis/results_"$1".txt"
NUM_REQUEST="10000000"
CONNECTIONS="50"

# Run benchmark

redis-benchmark -h $SERVER_IP -c $CONNECTIONS -n $NUM_REQUEST -t get,set > $OUTPUT_FILE