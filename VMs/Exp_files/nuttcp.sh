#!/bin/bash

SERVER_IP="192.168.10.5"
OUTPUT_FILE="../Results/nuttcp/results_"$1".txt"
RUN_TIME="300"
BANDWIDTH="50g" 

nuttcp -T$RUN_TIME -R$BANDWIDTH $SERVER_IP > $OUTPUT_FILE
