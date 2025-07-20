#!/bin/bash

MODE_FLAG=$1
LOGDIR=$2
source ./configs/env.sh

OUTFILE="$LOGDIR/tcpdump.pcap"
INTERFACE="eth0"  # 🔧 Update if needed

echo "Capturing TCP traffic for 10 seconds on $INTERFACE..." | tee "$LOGDIR/tcpdump.log"

timeout 10 tcpdump -i "$INTERFACE" tcp -w "$OUTFILE" >> "$LOGDIR/tcpdump.log" 2>&1
