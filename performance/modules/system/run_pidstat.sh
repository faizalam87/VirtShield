#!/bin/bash

MODE_FLAG=$1
LOGDIR=$2
source ./configs/env.sh

OUTFILE="$LOGDIR/pidstat.log"

# Record 1-second interval for 10 seconds
echo "Recording pidstat..." > "$OUTFILE"
pidstat -dur -h 1 10 >> "$OUTFILE" 2>&1
