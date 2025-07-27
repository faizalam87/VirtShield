#!/bin/bash

# CONFIGURATION
CLIENT_VM_USER="client"
CLIENT_VM_IP="192.168.10.4"

FIREWALL_VM_USER="model"
FIREWALL_VM_IP="192.168.10.3"

FIREWALL_DEPLOY_DIR="/home/$FIREWALL_VM_USER/virtshield_deploy"
CODE_DIR="../"  # Change this if your code is in a specific subfolder

# TEMP TAR FILE
ARCHIVE_NAME="virtshield_code.tar.gz"

# Archive and copy all user+kernel code to firewall
echo "Creating archive of user/kernel code..."
tar -czf $ARCHIVE_NAME $(find $CODE_DIR -maxdepth 1 -name '*.c' -o -name '*.h' -o -name 'Makefile')

echo "Copying code archive to Firewall VM..."
scp $ARCHIVE_NAME $FIREWALL_VM_USER@$FIREWALL_VM_IP:/home/$FIREWALL_VM_USER

echo "Extracting code on Firewall VM..."
ssh $FIREWALL_VM_USER@$FIREWALL_VM_IP "mkdir -p $FIREWALL_DEPLOY_DIR && tar -xzf /home/$FIREWALL_VM_USER/$ARCHIVE_NAME -C $FIREWALL_DEPLOY_DIR"

# Cleanup local archive
rm -f $ARCHIVE_NAME

echo "Done!"
