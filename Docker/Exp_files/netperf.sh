#!/bin/bash

SERVER_IP="192.168.2.3"
OUTPUT_FILE="../Results/netperf/results_"$1".txt"
RUN_TIME="300"  

netperf -H $SERVER_IP -l $RUN_TIME > $OUTPUT_FILE
