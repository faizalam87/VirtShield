#!/bin/bash

MODE_FLAG=$1
LOGDIR=$2
SERVER_IP=$3

OUTFILE="$LOGDIR/ping.log"
COUNT=10

echo "Running ping test to $SERVER_IP..." > "$OUTFILE"
ping -c $COUNT -D $SERVER_IP >> "$OUTFILE" 2>&1
