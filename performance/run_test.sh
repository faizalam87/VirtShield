#!/bin/bash

set -e
source ./configs/env.sh

MODE_FLAG=$1
if [[ "$MODE_FLAG" != "--baseline" && "$MODE_FLAG" != "--secure" ]]; then
  echo "Usage: $0 [--baseline | --secure]"
  exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGDIR="./logs/$TIMESTAMP"
mkdir -p "$LOGDIR"

echo "=== Running performance test ($MODE_FLAG) ==="
echo "Logs will be stored in: $LOGDIR"

# Network tests
echo "[1/4] Running iperf3"
bash ./modules/net/run_iperf.sh "$MODE_FLAG" "$LOGDIR"

echo "[2/4] Running ping"
bash ./modules/net/run_ping.sh "$MODE_FLAG" "$LOGDIR"

# System usage
echo "[3/4] Running pidstat"
bash ./modules/system/run_pidstat.sh "$MODE_FLAG" "$LOGDIR"

echo "[4/4] Running perf stat"
bash ./modules/system/run_perf.sh "$MODE_FLAG" "$LOGDIR"

# Optional: packet capture (can be disabled with flag)
if [[ "$ENABLE_TCPDUMP" == "true" ]]; then
  echo "[Optional] Running tcpdump"
  bash ./modules/common/run_tcpdump.sh "$MODE_FLAG" "$LOGDIR"
fi

echo "=== Done ==="
