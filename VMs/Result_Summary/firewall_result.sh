#!/bin/bash

output_file=./Results/"$1".csv

time_counter=0.0

echo "Time(s),COMMAND,RES,%CPU,%MEM" > $output_file

while true; do
	top -b -n 1 | awk -v time="$time_counter" 'NR>7 {print time","$12","$6","$9","$10}' | head -n 3  >> $output_file
	time_counter=$(echo "$time_counter + 0.1" | bc)
	sleep 0.1
done
