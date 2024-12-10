#!/bin/bash

SERVER_IP="192.168.10.5"
OUTPUT_FILE="../Results/fio/results_"$1".txt"
# PORT="8765"
FILE="/home/client/Exp_files/fio-test.fio"

fio --client=$SERVER_IP $FILE > $OUTPUT_FILE