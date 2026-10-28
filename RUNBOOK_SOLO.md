# RUNBOOK_SOLO.md — Single Builder Practical Execution Guide
**Project ARES: The Mars Colony Network**  
*Document Version: 2.0 (Solo Implementation Edition)*  
*Target OS: Ubuntu 22.04 / 24.04 LTS or Debian 12*

---

## 1. Executive Summary & Solo Operator Strategy

As the **sole builder and engineer** for Project ARES, your objective is to implement, test, and package this interplanetary network simulation quickly and reliably without getting bogged down in tool complexity.

The project is structured into three execution paths based on your available hardware and time:
1. **Fast 1-Hour Setup Path (Recommended)**: Uses native **Linux Network Namespaces** (`ip netns`). Runs on a single Ubuntu machine or VM, creates the exact 5-node topology in 30 seconds, has zero virtualization overhead, and is 100% immune to hypervisor bridge failures.
2. **Full Multi-VM Setup Path**: Uses 3 or 5 separate virtual machines (VirtualBox, VMware, or KVM) connected via internal host-only networks. Provides complete OS-level separation.
3. **Fallback Path (GNS3 / Cisco IOS Rescue)**: If GNS3 crashes, Dynamips fails to start, or Cisco IOS images fail to boot, this path immediately transitions your simulation to lightweight Linux routers in under 5 minutes without changing a single IP address or script.

---

## 2. Global Environment & Prerequisites

Run these commands once on your primary Ubuntu/Debian development machine to install all necessary packages.

### 2.1 Package Installation
```bash
# [Host Machine] Update repository indices and install required networking tools
sudo apt update && sudo apt install -y \
    iproute2 \
    net-tools \
    iptables \
    ethtool \
    tcpdump \
    iperf3 \
    wireshark \
    tshark \
    python3 \
    python3-pip \
    python3-matplotlib \
    jq \
    bc \
    curl \
    git
```

### 2.2 Verify Kernel Modules
Ensure Traffic Control and NetEm are enabled in your Linux kernel:
```bash
# [Host Machine] Verify netem scheduler
sudo modprobe sch_netem
lsmod | grep sch_netem
```
*Expected Output:*
```text
sch_netem              16384  0
```

---

## 3. Path A: The Fast 1-Hour Setup Path (Linux Namespaces)

> **Why this path?**  
> It implements the **exact 5-node topology** specified in academic requirements, uses the exact same IP addresses, executes all tests, generates real Wireshark PCAPs, and runs on a single laptop in under 15 minutes with zero RAM strain.

### Architecture in Namespaces:
- `mars_host` (192.168.10.10/24) $\leftrightarrow$ `mars_router` (192.168.10.1 / 172.16.1.1)
- `mars_router` $\leftrightarrow$ `space_emulator` (172.16.1.2 / 172.16.2.1)
- `space_emulator` $\leftrightarrow$ `earth_router` (172.16.2.2 / 10.10.10.1)
- `earth_router` $\leftrightarrow$ `earth_server` (10.10.10.10/24)

### Step A.1: Navigate to Build Directory & Execute Automated Setup
```bash
# [Host Machine] From the DCN_CP project root:
cd build
chmod +x setup_namespaces.sh space_link_netem.sh remove_netem.sh iperf_test_client.sh iperf_test_server.sh capture_traffic.sh analyze_iperf.py
sudo ./setup_namespaces.sh setup
```

*Expected Output:*
```text
==================================================================
    PROJECT ARES: INSTANT SINGLE-MACHINE NAMESPACE LAB BUILDER    
==================================================================
[+] Creating 5 network namespaces...
[+] Creating virtual cable pairs (veth)...
[+] Connecting interfaces to respective nodes...
[+] Configuring [Mars Host] (192.168.10.10/24)...
[+] Configuring [Mars Router]...
[+] Configuring [Space Emulator]...
[+] Configuring [Earth Router]...
[+] Configuring [Earth Server] (10.10.10.10/24)...

==================================================================
 [SUCCESS] 5-Node Interplanetary Network Emulation is ACTIVE!    
==================================================================
Immediate Baseline Ping Test:
PING 10.10.10.10 (10.10.10.10) 56(84) bytes of data.
64 bytes from 10.10.10.10: icmp_seq=1 ttl=61 time=0.048 ms
64 bytes from 10.10.10.10: icmp_seq=2 ttl=61 time=0.062 ms
64 bytes from 10.10.10.10: icmp_seq=3 ttl=61 time=0.059 ms
--- 10.10.10.10 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2048ms
rtt min/avg/max/mdev = 0.048/0.056/0.062/0.006 ms
```

### Checkpoint A.1: Success Confirmation
Run a manual 5-packet ping from Mars Host to Earth Server:
```bash
sudo ip netns exec mars_host ping -c 5 10.10.10.10
```
- **Pass**: 5 packets transmitted, 5 received, 0% packet loss, RTT < 1 ms.
- **Fail**: Destination Host Unreachable. (See [TROUBLESHOOTING.md](file:///c:/Users/shrey/Downloads/DCN_CP/TROUBLESHOOTING.md#issue-1-mars-cannot-ping-earth)).

### Rollback Command for Path A:
```bash
sudo ./setup_namespaces.sh teardown
```

---

### Step A.2: Start iPerf3 Server on Earth Node
Start the iPerf3 listening daemon inside the `earth_server` namespace:
```bash
# [Host Machine -> earth_server]
sudo ip netns exec earth_server iperf3 -s -D -I results/iperf3_server.log
```

*Verification Checkpoint:*
```bash
sudo ip netns exec earth_server ss -tuln | grep 5201
```
*Expected Output:*
```text
tcp   LISTEN 0      128          0.0.0.0:5201       0.0.0.0:*
```

---

### Step A.3: Inject Interplanetary Space Delay (Profile A)
Apply 5,000 ms one-way delay and 2% packet loss to the space emulator interfaces (`se_eth0` and `se_eth1`):
```bash
# [Host Machine -> space_emulator]
sudo ip netns exec space_emulator tc qdisc replace dev se_eth0 root netem delay 5000ms 50ms loss 2% limit 10000
sudo ip netns exec space_emulator tc qdisc replace dev se_eth1 root netem delay 5000ms 50ms loss 2% limit 10000
```

*Verify Delay Active:*
```bash
sudo ip netns exec space_emulator tc qdisc show dev se_eth0
```
*Expected Output:*
```text
qdisc netem 8001: root refcnt 2 limit 10000 delay 5.0s  50.0ms loss 2%
```

---

### Step A.4: Execute Delayed Ping Test
Run a 2-packet ping to confirm 10-second Round-Trip Time:
```bash
# [Host Machine -> mars_host]
sudo ip netns exec mars_host ping -c 2 10.10.10.10
```

*Expected Output (Note the ~10,000 ms time):*
```text
PING 10.10.10.10 (10.10.10.10) 56(84) bytes of data.
64 bytes from 10.10.10.10: icmp_seq=1 ttl=61 time=10015 ms
64 bytes from 10.10.10.10: icmp_seq=2 ttl=61 time=10008 ms
--- 10.10.10.10 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 10012ms
rtt min/avg/max/mdev = 10008.210/10011.605/10015.000/3.395 ms
```

---

### Step A.5: Start Packet Capture
Start `tcpdump` inside `mars_host` in the background to record Wireshark evidence:
```bash
# [Host Machine -> mars_host]
mkdir -p results
sudo ip netns exec mars_host tcpdump -i mh_eth0 -w results/project_ares_capture.pcap "host 10.10.10.10" &
TCPDUMP_PID=$!
echo "tcpdump started with PID $TCPDUMP_PID"
```

---

### Step A.6: Run Fast iPerf3 Protocol Experiments (TCP & UDP)
Execute a 25-second TCP stream, followed by a 25-second UDP telemetry stream:

```bash
# [Host Machine -> mars_host] 1. TCP Scientific Bulk Transfer
echo "[*] Running TCP Test under 10s RTT..."
sudo ip netns exec mars_host iperf3 -c 10.10.10.10 -p 5201 -t 25 -i 1 --json > results/tcp_test_live.json

# [Host Machine -> mars_host] 2. UDP Telemetry Stream (2 Mbps CBR)
echo "[*] Running UDP Telemetry Test..."
sudo ip netns exec mars_host iperf3 -c 10.10.10.10 -p 5201 -u -b 2M -t 25 -i 1 --json > results/udp_test_live.json
```

*Stop Packet Capture:*
```bash
sudo kill $TCPDUMP_PID || true
```

---

### Step A.7: Generate Comparison Plots and CSV Tables
Process the JSON files using the Python analytics script:
```bash
# [Host Machine]
python3 analyze_iperf.py results/tcp_test_live.json results/udp_test_live.json
```

*Expected Output:*
```text
[+] Loading TCP log: results/tcp_test_live.json
[+] Loading UDP log: results/udp_test_live.json
[+] Exported interval time-series: results/parsed_iperf_intervals.csv
[+] Exported test summary table : results/parsed_iperf_summary.csv
[SUCCESS] High-resolution comparative graph saved: tcp_vs_udp_throughput.png
======================================================================
            PROJECT ARES — INTERPLANETARY PROTOCOL ANALYSIS       
======================================================================
Scaled One-Way Delay     : 5,000 ms (RTT: 10.0 seconds)
Nominal Space Bandwidth  : 2.0 Mbps
Theoretical Link BDP     : 20,000,000 bits (2,500,000 Bytes / 2.38 MB)
----------------------------------------------------------------------
PROTOCOL PERFORMANCE MATRIX:
| Protocol | Mean Throughput | Retransmits | Loss (%) | Jitter (ms) |
|:---------|:---------------:|:-----------:|:--------:|:-----------:|
| TCP Bulk |      0.216 Mbps |          14 |      N/A |         N/A |
| UDP CBR  |      1.962 Mbps |         N/A |    2.10% |    48.50 ms |
======================================================================
```

**Congratulations! You have completed the entire experimental pipeline in under 20 minutes.**

---

## 4. Path B: Full Detailed Multi-VM Setup Path

If you prefer operating with full VirtualBox/VMware virtual machines, follow this sequential deployment.

### 4.1 Topology Machine Mapping
- **VM 1: `mars-host`** (1 vCPU, 1 GB RAM, Ubuntu 22.04) — NIC 1: Host-Only / Internal (`mars-lan`)
- **VM 2: `mars-router`** (1 vCPU, 1 GB RAM, Ubuntu 22.04) — NIC 1: `mars-lan`, NIC 2: `mars-space`
- **VM 3: `space-emulator`** (1 vCPU, 1 GB RAM, Ubuntu 22.04) — NIC 1: `mars-space`, NIC 2: `space-earth`
- **VM 4: `earth-router`** (1 vCPU, 1 GB RAM, Ubuntu 22.04) — NIC 1: `space-earth`, NIC 2: `earth-lan`
- **VM 5: `earth-server`** (1 vCPU, 1 GB RAM, Ubuntu 22.04) — NIC 1: `earth-lan`

*(Note: For 3-VM setup, consolidate Mars Router into Mars Host, and Earth Router into Earth Server, as detailed in Section 3 of [NETWORK_DESIGN.md](file:///c:/Users/shrey/Downloads/DCN_CP/NETWORK_DESIGN.md)).*

---

### Step B.1: Configure Mars Host (`mars-host`)
```bash
# [mars-host] Flush and configure IP
sudo ip addr flush dev eth0
sudo ip addr add 192.168.10.10/24 dev eth0
sudo ip link set dev eth0 up
sudo ip route add default via 192.168.10.1 dev eth0

# Verify
ip addr show dev eth0
ip route show
```

---

### Step B.2: Configure Mars Router (`mars-router`)
```bash
# [mars-router] Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.d/99-ipforward.conf

# Configure interfaces
sudo ip addr flush dev eth0
sudo ip addr flush dev eth1
sudo ip addr add 192.168.10.1/24 dev eth0
sudo ip addr add 172.16.1.1/30 dev eth1
sudo ip link set dev eth0 up
sudo ip link set dev eth1 up

# Static default route toward Space Emulator
sudo ip route add default via 172.16.1.2 dev eth1

# Permit forwarding in iptables
sudo iptables -F FORWARD
sudo iptables -A FORWARD -j ACCEPT
```

---

### Step B.3: Configure Space Emulator (`space-emulator`)
```bash
# [space-emulator] Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.d/99-ipforward.conf

# Configure interfaces
sudo ip addr flush dev eth0
sudo ip addr flush dev eth1
sudo ip addr add 172.16.1.2/30 dev eth0
sudo ip addr add 172.16.2.1/30 dev eth1
sudo ip link set dev eth0 up
sudo ip link set dev eth1 up

# Static routes back to Mars and Earth LANs
sudo ip route add 192.168.10.0/24 via 172.16.1.1 dev eth0
sudo ip route add 10.10.10.0/24 via 172.16.2.2 dev eth1

# Disable offloading to avoid netem packet burst distortion
sudo ethtool -K eth0 tso off gso off gro off || true
sudo ethtool -K eth1 tso off gso off gro off || true

# Permit forwarding
sudo iptables -F FORWARD
sudo iptables -A FORWARD -j ACCEPT
```

---

### Step B.4: Configure Earth Router (`earth-router`)
```bash
# [earth-router] Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.d/99-ipforward.conf

# Configure interfaces
sudo ip addr flush dev eth0
sudo ip addr flush dev eth1
sudo ip addr add 172.16.2.2/30 dev eth0
sudo ip addr add 10.10.10.1/24 dev eth1
sudo ip link set dev eth0 up
sudo ip link set dev eth1 up

# Static default route toward Space Emulator
sudo ip route add default via 172.16.2.1 dev eth0

# Permit forwarding
sudo iptables -F FORWARD
sudo iptables -A FORWARD -j ACCEPT
```

---

### Step B.5: Configure Earth Server (`earth-server`)
```bash
# [earth-server] Configure IP
sudo ip addr flush dev eth0
sudo ip addr add 10.10.10.10/24 dev eth0
sudo ip link set dev eth0 up
sudo ip route add default via 10.10.10.1 dev eth0

# Start iPerf3 daemon
sudo apt install -y iperf3
iperf3 -s -D
```

---

### Step B.6: Baseline End-to-End Verification
```bash
# [mars-host] Test reachability
ping -c 5 10.10.10.10
```
- **Pass Criteria**: `5 packets transmitted, 5 received, 0% packet loss, RTT < 5 ms`.

---

### Step B.7: Space Link Impairment Injection
On `[space-emulator]`:
```bash
# [space-emulator] Apply Profile A
sudo tc qdisc replace dev eth0 root netem delay 5000ms 50ms loss 2% limit 10000
sudo tc qdisc replace dev eth1 root netem delay 5000ms 50ms loss 2% limit 10000
```

To remove later:
```bash
# [space-emulator] Remove delay
sudo tc qdisc del dev eth0 root
sudo tc qdisc del dev eth1 root
```

---

### Step B.8: Protocol Execution from Mars Host
On `[mars-host]`:
```bash
# [mars-host] 1. Verify delayed ping
ping -c 3 10.10.10.10

# [mars-host] 2. Run TCP bulk test
iperf3 -c 10.10.10.10 -t 30 -i 1 --json > tcp_results.json

# [mars-host] 3. Run UDP telemetry test
iperf3 -c 10.10.10.10 -u -b 2M -t 30 -i 1 --json > udp_results.json
```

---

## 5. Path C: Fallback Strategy if GNS3 or Cisco IOS Fails

If you initially attempted to build this in GNS3 with Cisco IOS and encounter:
- Cisco 7200 image not found or license error
- GNS3 VM fails to establish QEMU/KVM bridge
- CPU spikes to 100% due to Dynamips idle-PC misconfiguration
- Packet corruption across GNS3 virtual links

### The 5-Minute Rescue Protocol:
1. **Do not panic or restart your PC**.
2. Close GNS3 completely: `killall gns3server gns3 dynamips || true`.
3. Open an Ubuntu terminal on Laptop A.
4. Execute:
   ```bash
   cd ~/DCN_CP/build
   sudo ./setup_namespaces.sh setup
   ```
5. All 5 nodes are now running natively in kernel memory.
6. Continue your demonstration seamlessly using the commands in Section 3.

---

## 6. Pre-Demo Verification Checkpoints

Before stepping in front of your evaluators or team members, verify all items:

| # | Item | Verification Command | Expected Output |
|---|---|---|---|
| 1 | Baseline ping | `ping -c 2 10.10.10.10` (no netem) | `RTT < 2 ms, 0% loss` |
| 2 | NetEm delayed ping | `ping -c 2 10.10.10.10` (netem on) | `RTT ~10,000 ms, 0% or 2% loss` |
| 3 | NetEm queue limit | `tc qdisc show dev se_eth0` | `limit 10000` |
| 4 | iPerf3 server status | `ss -tuln \| grep 5201` on Earth | `LISTEN on 0.0.0.0:5201` |
| 5 | Output directory writable | `touch results/test.txt && rm results/test.txt` | Success |
| 6 | Python plot engine | `python3 analyze_iperf.py` | `tcp_vs_udp_throughput.png generated` |
