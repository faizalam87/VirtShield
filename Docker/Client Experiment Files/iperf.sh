#!/bin/bash

SERVER_IP="192.168.2.3"
OUTPUT_FILE="iperf_results.txt"
BANDWIDTH="10G" 
RUN_TIME="60"  

iperf3 -c $SERVER_IP -b $BANDWIDTH -t $RUN_TIME --get-server-output > $OUTPUT_FILE