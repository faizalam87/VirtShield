#!/bin/bash

LOGDIR=$1           # log directory
IS_KERNEL=$2        # 0 for user-space, 1 for kernel-space
DURATION=10

# Validate IS_KERNEL
if [[ "$IS_KERNEL" != "0" && "$IS_KERNEL" != "1" ]]; then
  echo " Invalid argument for IS_KERNEL: '$IS_KERNEL'"
  echo "Usage: <logdir> [0|1]"
  echo "       0 = User-space model"
  echo "       1 = Kernel-space model"
  exit 1
fi

# Create output files
OUTFILE_USER="$LOGDIR/perf_user_space.log"
OUTFILE_KERNEL="$LOGDIR/perf_kernel.log"

# Trap Ctrl+C
trap "echo ' Interrupted'; exit 1" INT

if [[ "$IS_KERNEL" == "1" ]]; then
  echo "📊 Recording system-wide perf stat for kernel-space model..." > "$OUTFILE_KERNEL"

  TMP_DATA="$LOGDIR/perf_kernel.data"

  # Record kernel-level events system-wide
  sudo perf record \
    -e cycles,instructions,cache-misses,branch-misses \
    -a -g --output="$TMP_DATA" -- sleep $DURATION

  # Generate report filtered by the kernel module
  sudo perf report \
    --input="$TMP_DATA" --kallsyms=/proc/kallsyms \
    --dsos=kernel_space.ko >> "$OUTFILE_KERNEL" 2>&1

  echo " Kernel-space perf done." >> "$OUTFILE_KERNEL"

else
  echo "🚀 Launching and monitoring user_space_model..." > "$OUTFILE_USER"

  sudo perf stat \
    -e cycles,instructions,cache-misses,branch-misses \
    ../virtshield_deploy/user_space_model >> "$OUTFILE_USER" 2>&1

  echo " User-space perf done." >> "$OUTFILE_USER"
fi
