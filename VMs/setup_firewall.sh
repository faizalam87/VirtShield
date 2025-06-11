#!/bin/bash

# CONFIGURATION
CLIENT_IP="192.168.10.4"
SERVER_IP="192.168.10.5"

echo "Enabling IP forwarding"
sudo sysctl -w net.ipv4.ip_forward=1

echo "Setting iptables FORWARD rule"
sudo iptables -A FORWARD -s $CLIENT_IP -d $SERVER_IP -j ACCEPT

echo "Current FORWARD rules:"
sudo iptables -L FORWARD -v -n
