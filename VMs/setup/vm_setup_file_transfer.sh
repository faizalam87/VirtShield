#!/bin/bash
# Transfer the setup scripts for each VM's to the corresponding machines.

set -e


# CONFIGURATION
CLIENT_VM_USER="client"
CLIENT_VM_IP="192.168.10.4"

MODEL_VM_USER="model"
MODEL_VM_IP="192.168.10.3"

# Copy setup scripts
echo "Copying setup script to Client VM..."
scp setup_client.sh $CLIENT_VM_USER@$CLIENT_VM_IP:/home/$CLIENT_VM_USER

echo "Copying setup script to MODEL VM..."
scp setup_model.sh $MODEL_VM_USER@$MODEL_VM_IP:/home/$MODEL_VM_USER

echo "Setup scripts copied to corresponding VM's home directories."
echo "You can now SSH into each VM and run the setup scripts to configure them."
echo "Example commands:"
echo "  ssh $CLIENT_VM_USER@$CLIENT_VM_IP  and ./setup_client.sh <direct/model>"
echo "  ssh $MODEL_VM_USER@$MODEL_VM_IP  and ./setup_model.sh"

echo "Make sure to run these scripts with appropriate execute permissions."

echo "Done!"
