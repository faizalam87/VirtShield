#!/bin/bash

SERVER_IP="192.168.10.5"
OUTPUT_FILE="nuttcp_results.txt"
RUN_TIME="60"  

nuttcp -T $RUN_TIME -o $OUTPUT_FILE $SERVER_IP
