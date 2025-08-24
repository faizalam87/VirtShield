<br>


<center>

# **VirtShield**: Evaluation of Firewall Performance in Virtualized and Containerized Systems
#Test

</center> 


## File Structure

# VirtShield VM Setup Guide (QEMU-based)

This guide walks you through setting up a **Virtual Machine (VM)** for the VirtShield platform using QEMU. Please follow the **order of execution** exactly to ensure correct setup.
---

##  Prerequisites

- **QEMU** QEMU is installed on the host. QEMU enables users to run multiple virtual machines on a single physical machine, facilitating cross-platform development and testing.
  > For installation details, refer to the [QEMU download page](https://www.qemu.org/download/).
- **UBUNTU ISO** The file ubuntu-22.04.5-live-server-amd64.iso should be placed in `VMs\setup` the directory that is used to initialize all virtual machines. This ensures consistent OS-level behavior across benchmarking runs, supporting reproducible container/VM workflows.
  > Download here: [Ubuntu 22.04.5 ISO](https://releases.ubuntu.com/22.04/)
- **Alternative ISO** If using a different ISO, update its name in `vm-client.sh`, `vm-model.sh`, and `vm-server.sh` present in the folder `VMs\setup`.

- **Sanity Check** Please ensure the following scripts are present in the cloned folder `VMs\setup`:
   `setup.sh`,  `vm-client.sh`, `vm-model.sh`, `vm-server.sh`, `vm_setup_file_transfer.sh`, `setup_client.sh`, `setup_model.sh`

---

## Step-by-Step VMs Setup
We would create, connect, and configure three VMs: a client (which contains the benchmarks), a server (that receives and processes the packets), and a model that mimics a cloud infrastructure, where the model VMs host the security module, either implemented in user-space or kernel-space.
### 1. Host Setup and VM Disk Creation

Run this **once on the host**:

```bash
./VMs/setup/setup.sh
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
.VMs/setup/vm-client.sh
.VMs/setup/vm-model.sh
.VMs/setup/vm-server.sh
```

- Each script launches the respective VM with the proper MAC address, disk image, and ISO. In case there are permission errors, please make sure that you upgrade/downgrade permissions as required.
- Follow along with the QEMU VM setup and press continue until you set up the username and password for client, server, and model.
### 3. Setting up the manual IP address 
    ip addr show        
    Output shows available interfaces and the associated bridge. (eg. ens3)
    - #### Add IP address to file /etc/netplan/01-netcfg.yaml
        
        sudo nano /etc/netplan/01-netcfg.yaml     
    
    - #### Add the following lines to the file:
 yaml
network:
  version: 2
  ethernets:
    ens3:
      dhcp4: no
      addresses: 192.168.10.4/24
      routes:
        - to: default
          via: 192.168.10.1
      nameservers:
        addresses: 8.8.8.8
      
         
    - #### Save the file and apply the configurations
        
        sudo netplan apply
- <b>Client:</b> 192.168.10.4  
- <b>Server:</b> 192.168.10.5  
- <b>Firewall:</b> 192.168.10.3
The script configures the following MAC addresses and IP addresses during the setup of the QEMU GUI.

| VM     | MAC Address         | IP Address     | Role              |
|--------|---------------------|----------------|-------------------|
| Client | 52:54:00:12:34:01   | 192.168.10.4   | Traffic Generator |
| Model  | 52:54:00:12:34:02   | 192.168.10.3   | Security Module   |
| Server | 52:54:00:12:34:03   | 192.168.10.5   | Receiver          |

---
**Additional Debugging Tips**
- If the system freezes due to high memory utilization, then restart your computer and rerun the scripts `setup.sh`, `vm-client.sh`, `vm-model.sh`, `vm-server.sh` 
  It will restart from the last VM snapshots.
- If the mouse cursor gets stuck with a QEMU window, try `Ctrl + Alt + G` or `Ctrl + Alt + Shift` to release it.
### 4. Transfer Setup Scripts to VMs

From the host, run:

```bash
./vm_setup_file_transfer.sh
```

>  To SSH into any VM, install OpenSSH Server **inside the VM**:
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
- IP forwarding and firewall rules in the model
- Benchmark tools installation (iperf3, fio, etc.)

Each step prints messages with `echo` so you can verify progress.

##  Benchmark Tools Installed

**Client/Model:**
- `iperf3`, `netperf`, `nuttcp`, `fio`, `mysql-client`, `redis-tools`, `sysbench`, `traceroute`

**Server:**
- `iperf3`, `netperf`, `nuttcp`, `fio`, `mysql-server`, `redis-server`

---

##  Security Model: Deployment and Evaluation

###  1. Deploying the Security Model

####  A. Source Code Location

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

#### ⚖ C. Building the Model

```bash
cd ~/VirtShield
make
```

Builds:
- `kernel_space.ko`
- `user_space_model`

####  D. Running the Model

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

##  2. Measuring Performance

VirtShield measures two performance dimensions:

###  A. Network Performance (Client VM)

####  Where:
```bash
ssh client
```

#### ⚖ Run benchmark:
```bash
cd ~/VirtShield
./run_test.sh
```

Measures:
- **Latency**
- **Throughput**

Tools used: `iperf3`, `netperf`, `nuttcp`

>  Results saved for both `direct` and `model` modes.

---

###  B. Microarchitectural Profiling (Model VM)

####  Where:
```bash
ssh model
cd ~/VirtShield/performance
```

####  Run perf profiling:
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

##  3. Logs and Debugging

| Component        | Command or File                                   |
|------------------|----------------------------------------------------|
| Kernel logs      | `dmesg`, `sudo journalctl -k | grep VirtShield`   |
| User-space logs  | Run binary with `> user_log.txt`                  |
| Perf outputs     | `perf_kernel.log`, `perf_user_space.log`          |
| Perf raw data    | `perf_kernel.data` + `perf report`                |

---

##  Troubleshooting: No Internet in VMs

If a VM can **ping 192.168.10.1** but **not the internet**:

###  Symptoms:
- `ping 8.8.8.8` fails
- Internal ping works
- `tcpdump` on host shows outgoing packets
- No `conntrack` entries
- ICMP unreachable (admin prohibited)

###  Fix:

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



# VirtShield Docker Setup Guide

This guide walks you through the **Docker-based setup** for the VirtShield platform. It mirrors the VM-based setup but uses lightweight containers to emulate the client, server, and firewall environments.

---

##  Prerequisites

- Docker installed and accessible without sudo (or use `sudo` with every command)
- Working directory: `VirtShield/`
- All necessary scripts and Dockerfiles placed correctly

---

##  Step-by-Step Setup

### 1. Launch Docker-Based Topology

Navigate to the `setup/` directory and run:

```bash
cd setup
./setup_containers.sh <direct|model>
```

Where:
- `direct` mode: Client sends traffic directly to the server
- `model` mode: Client routes traffic to the model (firewall) container, which forwards it to the server

---

### 2. Container IP Configuration

| Container | IP (client-net) | IP (server-net) | Role              |
|-----------|------------------|------------------|-------------------|
| Client    | 192.168.1.3      | 192.168.2.4*     | Traffic Generator |
| Model     | 192.168.1.2      | 192.168.2.2      | Firewall          |
| Server    | -                | 192.168.2.3      | Receiver          |

> In `direct` mode, the client is additionally connected to `server-net` with IP `192.168.2.4` to reach the server directly.

---

### 3. What Happens in `setup_containers.sh`

- Creates two Docker networks:
  - `client-net` (192.168.1.0/24)
  - `server-net` (192.168.2.0/24)

- Builds Docker images for `client`, `server`, and `model` from respective Dockerfiles

- Launches containers with fixed IPs

- **In `model` mode**:
  - Client talks to `192.168.2.3` via `192.168.1.2` (model)
  - Model container performs IP forwarding and NAT with `iptables`
  - Route added in client: `ip route add 192.168.2.3 via 192.168.1.2`

- **In `direct` mode**:
  - Client is also connected to `server-net`
  - Talks directly to `192.168.2.3` (server)

---

### 4. File Copy: What Goes Where

To avoid unnecessary clutter, only essential files are copied.

####  Client Container:
- `performance/configs/`
- `performance/env.container.sh`
- `performance/module/`
- `performance/common/`
- `performance/net/`
- `performance/run_tcp_dump.sh`
- `performance/run_iperf`
- `performance/run_ping`

####  Model Container:
- `performance/system/`
- `performance/run_perf.sh`
- `performance/run_pidstat.sh`

---

### 5. What the User Should Modify Inside Containers

Once the containers are up and required files are copied in, the user is expected to:

- Navigate to `/root/performance/workspace/` inside the model container
- Modify the required C source files to implement their own security logic
  - For example: `kernel_space.c`, `user_space_model.c`, `packet_queue.c`, etc.

After modifying the files:

1. Run `make` inside the workspace directory to compile:
   ```bash
   cd /root/performance/workspace
   make
   ```

2. Depending on which model you use, deploy it manually:
   - Kernel-space:
     ```bash
     sudo insmod kernel_space.ko
     ```
   - User-space:
     ```bash
     sudo nohup ./user_space_model &
     ```

>  Repeat the edit → compile → deploy cycle as needed.

---

##  Security Model: Deployment & Execution

### A. Location

Inside the **model** container:
```
/root/performance/workspace/
├── kernel_space.ko
├── user_space_model

These files are created during the `make` process and represent the compiled security model:
- `kernel_space.ko` is the kernel module to be inserted using `insmod`
- `user_space_model` is the user-space executable

As a user, your primary task is to **modify the source files** (such as `kernel_space.c`, `user_space_model.c`, or `packet_queue.c`) located in the corresponding workspace source directory. After modifying the code, rerun `make` inside the container to generate the updated `.ko` or binary files, and re-insert or restart the appropriate model implementation.

This is where you implement your actual firewall/security logic.
```

### B. Running the Model

Then in **model container**:
- Kernel-space:
```bash
sudo insmod /root/workspace/kernel_space.ko
```
- User-space:
```bash
sudo nohup /root/workspace/user_space_model &
```

To unload kernel module:
```bash
sudo rmmod kernel_space
```

---

##  Measuring Performance

### A. Network Benchmarks (Client)
Run tools like:
```bash
./run_test.sh
```
These compare network metrics in `direct` vs `model` mode.

### B. Microarchitectural Profiling (Model)
```bash
cd /root/performance
sudo ./run_perf.sh <logdir> <mode>
# mode: 0 = user-space, 1 = kernel-space
```

Outputs:
- `perf_kernel.log`, `perf_kernel.data`
- `perf_user_space.log`

---

##  Logs and Debugging

| Component        | Location or Tool                          |
|------------------|-------------------------------------------|
| Kernel logs      | `dmesg`, `journalctl -k`                  |
| User logs        | Redirect stdout from model binary         |
| Performance logs | `/root/performance/*.log`                 |

---

##  Benchmark Tools

Install these inside **client** and **server** containers (already handled in Dockerfiles):

- `iperf3`, `netperf`, `nuttcp`, `fio`, `mysql-client`, `redis-tools`, `sysbench`, `traceroute`
- `mysql-server`, `redis-server` on server container

---

##  Testing Checklist

- [ ] Containers up and running: `docker ps`
- [ ] Client can ping server (`ping 192.168.2.3`)
- [ ] Model forwards packets (`iptables -L` shows forwarding rules)
- [ ] Kernel/user-space model loaded
- [ ] `perf` logs collected

---

You're now ready to test, modify, and evaluate your firewall security model in a lightweight Docker environment. For VM-based setup, please take a look at the [VirtShield VM Setup Guide](vm_setup_README.md).

