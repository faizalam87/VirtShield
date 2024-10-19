#!/bin/bash

SERVER_IP="192.168.2.3"
OUTPUT_FILE="nuttcp_results.txt"
RUN_TIME="60"  

nuttcp -T $RUN_TIME -o $OUTPUT_FILE $SERVER_IP
