#!/bin/bash

# CONFIGURATION
SERVER_IP="192.168.10.5"
MODEL_MAC="52:54:00:12:34:02"      # MAC of the model VM
SERVER_MAC="52:54:00:12:34:03"     # MAC of the server VM

# SSH CONFIG (for copying performance framework)
CLIENT_SSH="client@192.168.10.4"     # 🔧 Update with actual client VM IP and username

# USAGE CHECK
if [ $# -ne 1 ]; then
    echo "Usage: $0 [model|direct]"
    exit 1
fi

MODE=$1

if [ "$MODE" == "model" ]; then
    echo "Routing to server ($SERVER_IP) via MODEL (MAC: $MODEL_MAC)"
    sudo arp -s $SERVER_IP $MODEL_MAC

elif [ "$MODE" == "direct" ]; then
    echo "Routing to server ($SERVER_IP) DIRECTLY (MAC: $SERVER_MAC)"
    sudo arp -s $SERVER_IP $SERVER_MAC

else
    echo "Invalid mode: $MODE"
    echo "Usage: $0 [model|direct]"
    exit 1
fi

# Show ARP entry
echo "Updated ARP entry:"
arp -n | grep $SERVER_IP

# Copy performance framework to client
echo "Copying performance framework to client VM ($CLIENT_SSH)..."
scp -r ../performance "$CLIENT_SSH:/home/ubuntu/"

echo "✅ Routing set and performance framework deployed to client VM."
