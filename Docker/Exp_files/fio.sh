#!/bin/bash

SERVER_IP="192.168.2.3"
OUTPUT_FILE="fio_results.txt"
PORT="8765"
RUN_TIME="60"  

NAME="benchmark"
TYPE="randrw"
SIZE="1G"
BLOCK_SIZE="4k"
NUM_JOBS="4"

fio --client=$SERVER_IP --port=$PORT \
    --name=$NAME --rw=$TYPE --bs=$BLOCK_SIZE \
    --size=$SIZE --numjobs=$NUM_JOBS \
    --time_based --runtime=$RUN_TIME \
    > $OUTPUT_FILE