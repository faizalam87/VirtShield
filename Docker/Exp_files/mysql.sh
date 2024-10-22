#!/bin/bash

SERVER_IP="192.168.2.3"
OUTPUT_FILE="mysql_results.txt"
RUN_TIME="300"  
MYSQL_HOST="root"
MYSQL_PASSWORD="password"
MYSQL_DB="benchmark"
TABLES="10"
TABLE_SIZE="1000000"
THREADS="8"

# preapre command

sysbench /usr/share/sysbench/oltp_read_write.lua \
    --mysql-host=$SERVER_IP --mysql-user=$MYSQL_HOST \
    --mysql-password=$MYSQL_PASSWORD --mysql-db=$MYSQL_DB \
    --tables=$TABLES --table-size=$TABLE_SIZE \
    prepare

# Run Command

sysbench /usr/share/sysbench/oltp_read_write.lua \
    --mysql-host=$SERVER_IP --mysql-user=$MYSQL_HOST \
    --mysql-password=$MYSQL_PASSWORD --mysql-db=$MYSQL_DB \
    --tables=$TABLES --table-size=$TABLE_SIZE \
    --threads=$THREADS --time=$RUN_TIME \
    run > $OUTPUT_FILE

# Cleanup command

sysbench /usr/share/sysbench/oltp_read_write.lua \
    --mysql-host=$SERVER_IP --mysql-user=$MYSQL_HOST \
    --mysql-password=$MYSQL_PASSWORD --mysql-db=$MYSQL_DB \
    --tables=$TABLES --table-size=$TABLE_SIZE \
    cleanup