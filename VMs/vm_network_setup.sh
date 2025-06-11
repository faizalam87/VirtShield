#!/bin/bash

# CONFIGURATION
CLIENT_VM_USER="client"
CLIENT_VM_IP="192.168.10.4"

FIREWALL_VM_USER="model"
FIREWALL_VM_IP="192.168.10.3"

# Copy scripts
echo "Copying setup script to Client VM..."
scp setup_client.sh $CLIENT_VM_USER@$CLIENT_VM_IP:/home/$CLIENT_VM_USER

echo "Copying setup script to Firewall VM..."
scp setup_firewall.sh $FIREWALL_VM_USER@$FIREWALL_VM_IP:/home/$FIREWALL_VM_USER

# Run scripts remotely
echo "Running setup on Client VM..."
ssh $CLIENT_VM_USER@$CLIENT_VM_IP "bash /home/$CLIENT_VM_USER/setup_client.sh"

echo "Running setup on Firewall VM..."
ssh $FIREWALL_VM_USER@$FIREWALL_VM_IP "bash /home/$FIREWALL_VM_USER/setup_firewall.sh"

echo "Done!"
