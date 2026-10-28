# 🚀 Project ARES — The Mars Colony Network

> **A Data Communications & Networking (DCN) Course Project**  
> Simulating interplanetary TCP/UDP behaviour over a high-latency deep-space link using Linux network namespaces and `tc netem`.

---

## 📡 Overview

**Project ARES** (*Adaptive Relay for Extra-terrestrial Systems*) models a Mars colony network connected to Earth Mission Control through a simulated deep-space communication link. The project investigates how standard internet protocols — TCP and UDP — behave when subjected to the extreme latency and packet loss characteristic of real interplanetary communication.

**Core Question:**
> *How do TCP and UDP behave when the communication link has extreme latency and packet loss — and which transport protocol is better suited for Mars-like communication?*

---

## 🌌 Network Topology

```
Mars Host (192.168.10.10)
        |
   Mars Router (192.168.10.1 / 172.16.1.1)
        |
  Space Emulator (172.16.1.2 / 172.16.2.1)   ← tc netem delay + loss injected here
        |
  Earth Router (172.16.2.2 / 10.10.10.1)
        |
Earth Server (10.10.10.10)
```

### IP Addressing Summary

| Device | Interface | IP Address | Network |
|---|---|---|---|
| Mars Host | `eth0` | `192.168.10.10/24` | Mars LAN |
| Mars Router | `eth0` | `192.168.10.1/24` | Mars LAN |
| Mars Router | `eth1` | `172.16.1.1/30` | Mars↔Space Link |
| Space Emulator | `eth0` | `172.16.1.2/30` | Mars↔Space Link |
| Space Emulator | `eth1` | `172.16.2.1/30` | Space↔Earth Link |
| Earth Router | `eth0` | `172.16.2.2/30` | Space↔Earth Link |
| Earth Router | `eth1` | `10.10.10.1/24` | Earth LAN |
| Earth Server | `eth0` | `10.10.10.10/24` | Earth LAN |

> Full addressing details: [`build/ip_addressing_table.md`](build/ip_addressing_table.md)

---

## 🧪 What This Project Demonstrates

| Concept | How It's Shown |
|---|---|
| IP Addressing & Subnetting | 3 separate subnets across 5 nodes |
| Static Routing | Manual forwarding tables on all routers |
| TCP congestion control collapse | iPerf3 TCP under 10 s RTT |
| UDP resilience under latency | iPerf3 UDP CBR @ 2 Mbps |
| Bandwidth-Delay Product (BDP) | Calculated & measured |
| Packet analysis | `tcpdump` / Wireshark PCAP captures |
| Delay-Tolerant Networking (DTN) | Theoretical analysis in final report |

---

## ⚡ Quickstart — Recommended Path (≤ 20 minutes)

This method uses **Linux Network Namespaces** (`ip netns`) on a single Ubuntu machine. No VMs required.

### Prerequisites

**OS:** Ubuntu 22.04 LTS / 24.04 LTS or Debian 12

```bash
sudo apt update && sudo apt install -y \
    iproute2 net-tools iptables ethtool \
    tcpdump iperf3 wireshark tshark \
    python3 python3-pip python3-matplotlib \
    jq bc curl git
```

Verify `netem` kernel module:
```bash
sudo modprobe sch_netem
lsmod | grep sch_netem
# Expected: sch_netem   16384  0
```

### Step 1 — Clone & Set Up the 5-Node Topology

```bash
git clone https://github.com/shreyx404/Ares.git
cd Ares/build
chmod +x *.sh
sudo ./setup_namespaces.sh setup
```

Expected output confirms the network is active and a baseline ping from Mars Host → Earth Server shows `RTT < 1 ms, 0% loss`.

### Step 2 — Start the iPerf3 Server (Earth Node)

```bash
sudo ip netns exec earth_server iperf3 -s -D -I ../results/iperf3_server.log

# Verify it's listening:
sudo ip netns exec earth_server ss -tuln | grep 5201
```

### Step 3 — Inject Space Link Delay (Profile A: 5 s one-way, 2% loss)

```bash
sudo ip netns exec space_emulator tc qdisc replace dev se_eth0 root netem delay 5000ms 50ms loss 2% limit 10000
sudo ip netns exec space_emulator tc qdisc replace dev se_eth1 root netem delay 5000ms 50ms loss 2% limit 10000

# Verify delay is active:
sudo ip netns exec space_emulator tc qdisc show dev se_eth0
```

Confirm the interplanetary link with a 2-packet ping (expect ~10,000 ms RTT):
```bash
sudo ip netns exec mars_host ping -c 2 10.10.10.10
```

### Step 4 — Run TCP & UDP Protocol Experiments

```bash
mkdir -p ../results

# Start packet capture
sudo ip netns exec mars_host tcpdump -i mh_eth0 -w ../results/project_ares_capture.pcap "host 10.10.10.10" &
TCPDUMP_PID=$!

# TCP bulk transfer (scientific data / large files)
sudo ip netns exec mars_host iperf3 -c 10.10.10.10 -p 5201 -t 25 -i 1 --json > ../results/test_tcp.json

# UDP telemetry stream (sensor data @ 2 Mbps CBR)
sudo ip netns exec mars_host iperf3 -c 10.10.10.10 -p 5201 -u -b 2M -t 25 -i 1 --json > ../results/test_udp.json

# Stop packet capture
sudo kill $TCPDUMP_PID || true
```

### Step 5 — Generate Analysis Plots & CSV Tables

```bash
python3 analyze_iperf.py ../results/test_tcp.json ../results/test_udp.json
```

This produces:
- `tcp_vs_udp_throughput.png` — comparative throughput graph
- `results/parsed_iperf_intervals.csv` — per-second interval data
- `results/parsed_iperf_summary.csv` — summary statistics table

### Teardown

```bash
sudo ./setup_namespaces.sh teardown
```

---

## 🔧 Alternative Setup Paths

### Path B — Multi-VM Setup (VirtualBox / VMware / KVM)

Use 5 separate Ubuntu VMs connected via internal/host-only networks. Configure each VM manually following [`RUNBOOK_SOLO.md`](RUNBOOK_SOLO.md) Section 4.

**VM Mapping:**

| VM | Role | RAM | NICs |
|---|---|---|---|
| `mars-host` | Scientific workstation | 1 GB | 1 (mars-lan) |
| `mars-router` | Mars LAN gateway | 1 GB | 2 (mars-lan, mars-space) |
| `space-emulator` | Delay/loss injector | 1 GB | 2 (mars-space, space-earth) |
| `earth-router` | Earth LAN gateway | 1 GB | 2 (space-earth, earth-lan) |
| `earth-server` | Mission Control server | 1 GB | 1 (earth-lan) |

### Path C — GNS3 Rescue / Fallback

If GNS3 or Cisco IOS fails during setup, execute the 5-minute rescue protocol:
```bash
killall gns3server gns3 dynamips || true
cd ~/Ares/build
sudo ./setup_namespaces.sh setup
```
All IPs and scripts remain identical — no changes needed.

---

## 🔬 Delay Profiles

| Profile | One-Way Delay | RTT | Packet Loss | Use Case |
|---|---|---|---|---|
| **A — Safe Demo** | 5,000 ms | ~10 s | 2% | Live presentation |
| **B — Strong Mars** | 15,000 ms | ~30 s | 5% | Extended demo |
| **C — Extreme** | 60,000 ms | ~120 s | 5–10% | Report analysis only |

> Real Earth-Mars one-way delay ranges from **~3 minutes (closest approach)** to **~22 minutes (farthest)**. Profiles are scaled down to preserve identical TCP/UDP dynamics within classroom time constraints.

---

## 📊 Key Results

| Protocol | Mean Throughput | Retransmissions | Packet Loss | Jitter |
|---|---|---|---|---|
| **TCP Bulk** | ~0.216 Mbps | 14 | N/A | N/A |
| **UDP CBR** | ~1.962 Mbps | N/A | 2.1% | 48.5 ms |

**Conclusion:** TCP congestion control collapses under high-latency links due to slow ACK return and window starvation. UDP maintains near-nominal throughput at the cost of occasional packet loss — making it more suitable for Mars telemetry streams.

> Full analysis: [`FINAL_REPORT.md`](FINAL_REPORT.md)  
> Wireshark evidence: [`results/evidence/`](results/evidence/)

---

## 📁 Repository Structure

```
Ares/
├── build/                        # All automation scripts
│   ├── setup_namespaces.sh       # ★ Main setup/teardown script
│   ├── space_link_netem.sh       # Delay injection helper
│   ├── remove_netem.sh           # Remove netem rules
│   ├── iperf_test_client.sh      # iPerf3 client runner
│   ├── iperf_test_server.sh      # iPerf3 server runner
│   ├── capture_traffic.sh        # tcpdump automation
│   ├── analyze_iperf.py          # Python analytics + plots
│   ├── topology.md               # Topology diagrams
│   ├── ip_addressing_table.md    # Full IP addressing reference
│   ├── earth_router_config.md    # Earth router commands
│   ├── mars_router_config.md     # Mars router commands
│   └── space_emulator_config.md  # Space emulator commands
│
├── results/                      # Test outputs (generated)
│   ├── test_tcp.json             # Raw TCP iPerf3 data
│   ├── test_udp.json             # Raw UDP iPerf3 data
│   ├── tcp_vs_udp_throughput.png # Comparison graph
│   ├── parsed_iperf_intervals.csv
│   ├── parsed_iperf_summary.csv
│   └── evidence/                 # tcpdump/log evidence files
│
├── FINAL_SUBMISSION/             # Organised academic submission
│   ├── 1_Project_Report/
│   ├── 2_Presentation/
│   ├── 3_Evidence/
│   ├── 4_Source_Code/
│   └── 5_Raw_Data/
│
├── PROJECT_BRIEF.md              # Project scope & objectives
├── NETWORK_DESIGN.md             # Topology & routing design
├── ASSUMPTIONS.md                # Engineering assumptions & trade-offs
├── RUNBOOK_SOLO.md               # Full step-by-step execution guide
├── FINAL_REPORT.md               # Complete project report
├── VALIDATION_CHECKLIST.md       # Pre-demo verification checklist
├── VIVA_CHEATSHEET.md            # Q&A preparation for viva
├── TROUBLESHOOTING.md            # Common issues & fixes
└── RUN_FULL_LAB.sh               # One-shot full lab runner
```

---

## 🛠️ Tools Used

| Tool | Purpose |
|---|---|
| `ip netns` | Linux network namespace virtualisation |
| `tc netem` | Traffic shaping — delay, loss, jitter injection |
| `iperf3` | TCP & UDP throughput benchmarking |
| `tcpdump` / `Wireshark` | Packet capture & protocol analysis |
| `Python 3` + `matplotlib` | Data parsing & graph generation |
| `iproute2` | Routing, interface, and namespace configuration |

---

## 📋 Pre-Demo Verification Checklist

| # | Check | Command | Expected |
|---|---|---|---|
| 1 | Baseline ping | `ping -c 2 10.10.10.10` (no netem) | `RTT < 2 ms, 0% loss` |
| 2 | Delayed ping | `ping -c 2 10.10.10.10` (netem on) | `RTT ~10,000 ms` |
| 3 | netem queue limit | `tc qdisc show dev se_eth0` | `limit 10000` |
| 4 | iPerf3 server | `ss -tuln \| grep 5201` on Earth | `LISTEN on 0.0.0.0:5201` |
| 5 | Output dir writable | `touch results/test.txt` | No error |
| 6 | Plot engine | `python3 analyze_iperf.py` | PNG generated |

Full checklist: [`VALIDATION_CHECKLIST.md`](VALIDATION_CHECKLIST.md)

---

## 📚 Key Documents

| Document | Description |
|---|---|
| [`PROJECT_BRIEF.md`](PROJECT_BRIEF.md) | Project scope, objectives, and team roles |
| [`NETWORK_DESIGN.md`](NETWORK_DESIGN.md) | Full topology and routing plan |
| [`ASSUMPTIONS.md`](ASSUMPTIONS.md) | Engineering assumptions and design trade-offs |
| [`RUNBOOK_SOLO.md`](RUNBOOK_SOLO.md) | Complete step-by-step execution guide (all 3 paths) |
| [`FINAL_REPORT.md`](FINAL_REPORT.md) | Full academic project report |
| [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) | Common issues and fixes |
| [`VIVA_CHEATSHEET.md`](VIVA_CHEATSHEET.md) | Viva Q&A preparation |

---

## 📄 License

This project was created for academic purposes as part of a Data Communications & Networking (DCN) course.
