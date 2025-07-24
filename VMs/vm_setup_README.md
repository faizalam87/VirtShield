# 🖥️ VirtShield VM Setup Guide (QEMU-based)

This guide walks you through the **Virtual Machine (VM)** setup for the VirtShield platform using QEMU. Please follow the **order of execution** exactly to ensure correct setup.

---

## ✅ Prerequisites

- QEMU installed on host  
- Ubuntu ISO `ubuntu-22.04.5-live-server-amd64.iso` placed in the working directory  
  > Download here: [Ubuntu 22.04.5 ISO](https://releases.ubuntu.com/22.04/)
- If using a different ISO, update its name in `vm-client.sh`, `vm-model.sh`, and `vm-server.sh`.

The following scripts must be present:
- `setup.sh`
- `vm-client.sh`, `vm-model.sh`, `vm-server.sh`
- `vm_setup_file_transfer.sh`
- `setup_client.sh`, `setup_model.sh`

---

## 🛠️ Step-by-Step Setup

### 1. Host Setup and VM Disk Creation

Run this **once on the host**:

```bash
./setup.sh
```

This will:
- Create the Linux bridge (`br0`)
- Set up NAT and routing
- Make QEMU ready to use the bridge
- Create empty disk images (`client.qcow2`, `model.qcow2`, `server.qcow2`)

---

### 2. Launch the VMs

In three terminals or background sessions, run:

```bash
./vm-client.sh
./vm-model.sh
./vm-server.sh
```

Each script launches the respective VM with proper MAC, disk image, and ISO.

---

### 3. VM MAC & IP Configuration

| VM     | MAC Address         | IP Address     | Role              |
|--------|---------------------|----------------|-------------------|
| Client | 52:54:00:12:34:01   | 192.168.10.4   | Traffic Generator |
| Model  | 52:54:00:12:34:02   | 192.168.10.3   | Firewall          |
| Server | 52:54:00:12:34:03   | 192.168.10.5   | Receiver          |

---

### 4. Transfer Setup Scripts to VMs

From the host, run:

```bash
./vm_setup_file_transfer.sh
```

This copies the respective setup scripts into each VM using `scp`.

> 🔐 To SSH into any VM, install OpenSSH Server **inside the VM**:
>
> ```bash
> sudo apt install openssh-server
> ```

---

### 5. Run Setup Inside Each VM

SSH into each VM (or use QEMU terminal) and execute the appropriate script:

- **Client VM**:
  ```bash
  ./setup_client.sh <direct|model>
  ```
  - Use `direct` if traffic should go straight from client to server.
  - Use `model` if traffic should go through the firewall (model VM).

- **Model VM (Firewall)**:
  ```bash
  ./setup_model.sh
  ```

- **Server VM**:
  No additional setup needed (SSH is optional for remote access).

These scripts configure:
- Static IP and gateway via netplan
- ARP redirection from client to model
- IP forwarding and firewall rules in model
- Benchmark tools installation (iperf3, fio, etc.)

Each step prints messages with `echo` so you can verify progress.

---

### 🔁 Packet Flow Configuration

Once all VMs are set up:

> 🧭 **Traffic from the client is routed to the server via the model (firewall) VM** — unless `direct` mode is used, in which case the client reaches the server directly.

---

## 🧪 Benchmark Tools Installed

**Client/Model:**
- `iperf3`, `netperf`, `nuttcp`, `fio`, `mysql-client`, `redis-tools`, `sysbench`, `traceroute`

**Server:**
- `iperf3`, `netperf`, `nuttcp`, `fio`, `mysql-server`, `redis-server`

---

## 📊 Performance and Benchmarking (Coming Soon)

This section will describe:
- How to run end-to-end benchmarks from the Client VM
- How to capture microarchitectural metrics from the Model VM using `perf`
- How to compare performance between `direct` and `model` paths
- Best practices for logging and result interpretation

→ Detailed instructions will be added in the next update.

---

## 🛠️ Troubleshooting: VM Has No Internet Access

If your VM can **ping internal IPs (e.g., 192.168.10.1)** but **cannot reach the internet**, this is likely caused by `firewalld` on the host blocking NAT or forwarding.

### 🔍 Symptoms
- `ping 8.8.8.8` from VM fails
- `ping 192.168.10.1` works
- `tcpdump` on host shows packets leaving `br0` but not `eno1`
- `conntrack` has no entries
- ICMP unreachable with **“admin prohibited”**

### ✅ Fix

1. **Check if firewalld is running:**
   ```bash
   sudo firewall-cmd --state
   ```

2. **Assign `br0` to a trusted zone:**
   ```bash
   sudo firewall-cmd --permanent --zone=trusted --add-interface=br0
   sudo firewall-cmd --reload
   ```

3. **Enable masquerading:**
   ```bash
   sudo firewall-cmd --zone=trusted --permanent --add-masquerade
   sudo firewall-cmd --reload
   ```

4. **Enable IP forwarding:**
   ```bash
   sudo sysctl -w net.ipv4.ip_forward=1
   ```

5. **Test connectivity again from VM:**
   ```bash
   ping 8.8.8.8
   ```

If this works, the issue was with firewalld blocking NAT. These changes make the setup persistent and safe without disabling the firewall entirely.
