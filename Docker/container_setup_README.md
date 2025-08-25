# 🐳 VirtShield Docker Setup Guide

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

You're now ready to test, modify, and evaluate your firewall security model in a lightweight Docker environment. For VM-based setup, refer to the [VirtShield VM Setup Guide](vm_setup_README.md).
