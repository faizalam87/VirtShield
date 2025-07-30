#!/bin/bash

set -e  # Exit on error

# Step 1: Create Docker networks
echo "Creating Docker networks..."
docker network create --subnet 192.168.1.0/24 client-net || true
docker network create --subnet 192.168.2.0/24 server-net || true

# Step 2: Build Docker images
echo "Building Docker images..."
docker build -t client -f dockerfile.client .
docker build -t server -f dockerfile.server .
docker build -t model -f dockerfile.model .

# Step 3: Run containers
echo "Running client container..."
docker run -d --name client --net client-net --ip 192.168.1.3 --cpus="2" --memory="1g" --privileged client

echo "Running server container..."
docker run -d --name server --net server-net --ip 192.168.2.3 --cpus="2" --memory="1g" server

echo "Running model container (firewall)..."
docker run -d --name model --net client-net --ip 192.168.1.2 --cpus="2" --memory="1g" --privileged model

# Step 4: Connect model to server-net
echo "Connecting model to server-net..."
docker network connect --ip 192.168.2.2 server-net model

# Step 5: Configure IP forwarding and iptables on model
echo "Configuring iptables and routing inside model..."
docker exec model sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

docker exec model iptables -A FORWARD -i eth0 -o eth1 -s 192.168.1.3 -d 192.168.2.3 -j ACCEPT
docker exec model iptables -A FORWARD -i eth1 -o eth0 -s 192.168.2.3 -d 192.168.1.3 -j ACCEPT
docker exec model iptables -t nat -A POSTROUTING -s 192.168.1.3 -d 192.168.2.3 -j MASQUERADE

# Step 6: Configure routing on client
echo "Adding route to client to reach server via model..."
docker exec client ip route add 192.168.2.3 via 192.168.1.2



# Step 7: Copy ONLY required performance files and setup script

# Client-side performance files
docker exec client mkdir -p /root/performance
docker cp -r ../performance/configs                client:/root/performance/

docker cp ../performance/modules/common/run_tcpdump.sh            client:/root/performance/
docker cp ../performance/modules/net/run_iperf.sh              client:/root/performance/
docker cp ../performance/modules/net/run_ping.sh               client:/root/performance/

# Model-side performance files
docker exec model mkdir -p /root/performance
docker cp ../performance/modules/system/run_perf.sh                model:/root/performance/
docker cp ../performance/modules/system/run_pidstat.sh             model:/root/performance/