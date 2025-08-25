#!/bin/bash
# setup_server.sh for Server Container

sudo apt install redis-server iperf3
# Start iperf3 server in background
echo "[+] Starting iperf3 server..."
nohup iperf3 -s

echo "[+] Starting redis server..."
sudo sed -i "s/^bind.*/bind 0.0.0.0/" /etc/redis/redis.conf

sudo service redis-server restart