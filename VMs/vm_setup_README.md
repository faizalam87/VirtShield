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

## 🔁 Packet Flow Configuration

Once all VMs are set up:

> 🧭 **Traffic from the client is routed to the server via the model (firewall) VM** — unless `direct` mode is used, in which case the client reaches the server directly.

---

## 📊 Benchmark Tools Installed

**Client/Model:**
- `iperf3`, `netperf`, `nuttcp`, `fio`, `mysql-client`, `redis-tools`, `sysbench`, `traceroute`

**Server:**
- `iperf3`, `netperf`, `nuttcp`, `fio`, `mysql-server`, `redis-server`

---

## 🔐 Security Model: Deployment and Evaluation

### 🚀 1. Deploying the Security Model

#### 📉 A. Source Code Location

In the **Model (Firewall) VM**, the security model lives in:

```
~/VirtShield/
├── kernel_space.c
├── user_space_model.c
├── packet_queue.c/h
├── Makefile
└── performance/
```

#### 🔧 B. Modifying the Model

- **Kernel-space model**: edit `kernel_space.c`
- **User-space model**: edit `user_space_model.c` and `packet_queue.c/h`

#### ⚖️ C. Building the Model

```bash
cd ~/VirtShield
make
```

Builds:
- `kernel_space.ko`
- `user_space_model`

#### 📌 D. Running the Model

From **Client VM**:
```bash
./setup_client.sh model
```

Then in **Model VM**:

- **Kernel-space**:
  ```bash
  sudo insmod kernel_space.ko
  ```
- **User-space**:
  ```bash
  sudo ./user_space_model
  ```

To unload kernel module:
```bash
sudo rmmod kernel_space
```

---

## 📈 2. Measuring Performance

VirtShield measures two performance dimensions:

### 🚁 A. Network Performance (Client VM)

#### ✅ Where:
```bash
ssh client
```

#### ⚖️ Run benchmark:
```bash
cd ~/VirtShield
./run_test.sh
```

Measures:
- **Latency**
- **Throughput**

Tools used: `iperf3`, `netperf`, `nuttcp`

> 📂 Results saved for both `direct` and `model` modes.

---

### 🧠 B. Microarchitectural Profiling (Model VM)

#### ✅ Where:
```bash
ssh model
cd ~/VirtShield/performance
```

#### ⚖️ Run perf profiling:
```bash
sudo ./run_perf.sh <logdir> <mode>
# mode: 0 = user-space, 1 = kernel-space
```

**What it does:**

- **Kernel-space (`mode=1`)**:
  - Records system-wide events for 10 seconds
  - Uses `perf record` + `perf report --dsos=kernel_space.ko`
  - Logs:
    - `<logdir>/perf_kernel.log`
    - `<logdir>/perf_kernel.data`

- **User-space (`mode=0`)**:
  - Runs `user_space_model` under `perf stat`
  - Logs:
    - `<logdir>/perf_user_space.log`

---

## 📁 3. Logs and Debugging

| Component        | Command or File                                   |
|------------------|----------------------------------------------------|
| Kernel logs      | `dmesg`, `sudo journalctl -k | grep VirtShield`   |
| User-space logs  | Run binary with `> user_log.txt`                  |
| Perf outputs     | `perf_kernel.log`, `perf_user_space.log`          |
| Perf raw data    | `perf_kernel.data` + `perf report`                |

---

## 🥵 Troubleshooting: No Internet in VMs

If a VM can **ping 192.168.10.1** but **not the internet**:

### ⚡ Symptoms:
- `ping 8.8.8.8` fails
- Internal ping works
- `tcpdump` on host shows outgoing packets
- No `conntrack` entries
- ICMP unreachable (admin prohibited)

### ✅ Fix:

```bash
sudo firewall-cmd --permanent --zone=trusted --add-interface=br0
sudo firewall-cmd --zone=trusted --permanent --add-masquerade
sudo firewall-cmd --reload
sudo sysctl -w net.ipv4.ip_forward=1
```

Then test again:
```bash
ping 8.8.8.8
```

---

You're now ready to run VirtShield with or without the security model, and compare performance across modes using both network benchmarks and CPU-level instrumentation.
