#!/bin/bash

MODE_FLAG=$1
LOGDIR=$2
source ./configs/env.sh

OUTFILE="$LOGDIR/perf_stat.log"

echo "Recording perf stat..." > "$OUTFILE"
perf stat -e cycles,instructions,cache-misses -a sleep 10 >> "$OUTFILE" 2>&1
