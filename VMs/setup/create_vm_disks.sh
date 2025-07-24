#!/bin/bash
# Create disk images for client, firewall, and server VMs

set -e

echo "[+] Creating VM disk images (10G each)..."

for vm in client model server; do
    if [ -f "$vm.qcow2" ]; then
        echo "[!] $vm.qcow2 already exists. Skipping..."
    else
        qemu-img create -f qcow2 $vm.qcow2 10G
        chmod +x ./vm-$vm.sh
        echo "  Created $vm.qcow2"
    fi
done
echo "[+] VM disk images created successfully!"
echo "Step 1: You can now start the VMs using the following commands:"
echo "Run './vm-client.sh', './vm-model.sh', and './vm-server.sh' to start the VMs."
echo "      The following will be the IP addresses configured :"
echo "          - Client: 192.168.10.4"
echo "          - Model: 192.168.10.3"
echo "          - Server: 192.168.10.5"
echo "Step 2: After starting the VMs, run './vm_setup_file_transfer.sh' and follow the steps mentioned there to configure the VM networks."

