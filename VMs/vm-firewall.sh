#!/bin/bash
# This script is used to configure and restart the firewall VM.


qemu-system-x86_64 -m 2048 -smp 2 -cdrom ubuntu-22.04.5-live-server-amd64.iso \
-netdev bridge,br=br0,id=net1 -device virtio-net-pci,netdev=net1,mac=52:54:00:12:34:02 \
-hda firewall.qcow2 -name "Firewall"