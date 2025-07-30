#!/bin/bash

SERVER_IP="192.168.2.3"
OUTPUT_FILE="../Results/fio/results_"$1".txt"
# PORT="8765"
FILE="/home/ubuntu/Exp_files/fio-test.fio"

fio --client=$SERVER_IP --debug=all $FILE > $OUTPUT_FILE