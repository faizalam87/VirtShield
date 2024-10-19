#!/bin/bash

SERVER_IP="192.168.2.3"
OUTPUT_FILE="netperf_results.txt"
RUN_TIME="60"  

netperf -H $SERVER_IP -l $RUN_TIME > $OUTPUT_FILE
