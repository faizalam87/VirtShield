#!/bin/bash

MODE_FLAG=$1
LOGDIR=$2
source ./configs/env.sh

OUTFILE="$LOGDIR/iperf.log"
DURATION=10

echo "Starting iperf3 test..." > "$OUTFILE"

iperf3 -c $SERVER_IP -t $DURATION -f m >> "$OUTFILE" 2>&1
