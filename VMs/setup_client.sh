#!/bin/bash

# CONFIGURATION
SERVER_IP="192.168.10.5"
FIREWALL_MAC="52:54:00:12:34:02"   

echo "Setting ARP entry to point $SERVER_IP to firewall MAC $FIREWALL_MAC"
sudo arp -s $SERVER_IP $FIREWALL_MAC

echo "ARP entry configured:"
arp -n | grep $SERVER_IP
