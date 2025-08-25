#!/bin/bash

MODE_FLAG=$1
LOGDIR=$2
SERVER_IP=$3

OUTPUT_FILE="$LOGDIR/redis.log"
DURATION=10

echo "Starting redis-benchmark test..." > "$OUTFILE"
NUM_REQUEST="1000000"
CONNECTIONS="50"

# Run benchmark

redis-benchmark -h $SERVER_IP -c $CONNECTIONS -n $NUM_REQUEST -t get,set > $OUTPUT_FILE

