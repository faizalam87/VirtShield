#!/bin/bash

MODE_FLAG=$1
LOGDIR=$2
OUTFILE="$LOGDIR/perf_user_space.log"

echo "Recording perf stat for user_space_model..." > "$OUTFILE"

# Trap Ctrl+C to clean up if needed
cleanup() {
  echo " Caught interrupt, exiting..." >> "$OUTFILE"
  exit 1
}
trap cleanup INT

# Run the binary directly using perf stat
sudo perf stat \
  -e cycles,instructions,cache-misses,branch-misses \
  ../virtshield_deploy/user_space_model >> "$OUTFILE" 2>&1

echo " Perf stat completed." >> "$OUTFILE"