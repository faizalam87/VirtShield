#!/bin/bash

SERVER_IP="192.168.2.3"
OUTPUT_FILE="../Results/iperf_results.txt"
BANDWIDTH="50G" 
RUN_TIME="300"  

iperf3 -c $SERVER_IP -b $BANDWIDTH -t $RUN_TIME --get-server-output > $OUTPUT_FILE