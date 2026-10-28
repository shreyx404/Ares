# EVIDENCE_PACK.md — Academic Submission Artifact Guide
**Project ARES: The Mars Colony Network**  
*Quality Assurance & Evidence Collection Protocol*  
*Target Archive: `results/evidence/`*

---

## 1. Master Evidence Manifest

Before submitting the final project report or presenting to evaluators, you must assemble the **11 core evidence artifacts** listed below. Each artifact serves as proof for specific networking principles.

| # | Artifact Description | Standard File Name | Storage Path | Primary Proof Purpose |
|---|---|---|---|---|
| **E-01** | Network Topology Diagram | `evidence_01_topology.png` | `results/evidence/` | Validates multi-segment subnet architecture and router placement. |
| **E-02** | Baseline Ping Output | `evidence_02_ping_baseline.log` | `results/evidence/` | Proves end-to-end static routing with RTT $< 10\text{ ms}$ (no delay). |
| **E-03** | Delayed Ping Output (5000ms) | `evidence_03_ping_delayed_5s.log` | `results/evidence/` | Proves space link emulator is actively injecting 10s RTT. |
| **E-04** | TCP Bulk Test Output & JSON | `evidence_04_tcp_delay.json` | `results/evidence/` | Proves TCP throughput collapse and window stall under latency. |
| **E-05** | UDP Telemetry Output & JSON | `evidence_05_udp_delay.json` | `results/evidence/` | Proves UDP sustained delivery rate at 2 Mbps despite delay. |
| **E-06** | Deep-Space Packet Trace PCAP | `evidence_06_project_ares.pcap` | `results/evidence/` | Raw packet trace for Wireshark inspection. |
| **E-07** | Wireshark Delayed ACK Screenshot | `evidence_07_wireshark_retrans.png` | `results/evidence/` | Visual proof of delayed ACKs and retransmissions. |
| **E-08** | NetEm Queue & Loss Configuration | `evidence_08_netem_qdisc.png` | `results/evidence/` | Proves exact Linux `tc` kernel queuing parameters and limit. |
| **E-09** | Router Forwarding Tables | `evidence_09_routing_tables.png` | `results/evidence/` | Proves static routing without loops across all 5 nodes. |
| **E-10** | Result Comparison Summary Table | `evidence_10_results_summary.csv` | `results/evidence/` | Quantitative comparison of throughput, loss, and RTT. |
| **E-11** | Throughput Comparative Graph | `tcp_vs_udp_throughput.png` | `results/` | Publication-grade visual comparison of TCP vs UDP over time. |

---

## 2. Detailed Generation Guide for Each Artifact

### Artifact E-01: Network Topology Screenshot
- **File Name**: `evidence_01_topology.png`
- **How to Generate**:
  - Render the Mermaid diagram in `build/topology.md` or capture your GNS3 canvas showing the 5 nodes with IP labels (`192.168.10.0/24`, `172.16.1.0/30`, `172.16.2.0/30`, `10.10.10.0/24`).
- **What It Proves**: End-to-end architectural compliance with academic requirements.

---

### Artifact E-02: Baseline Ping Output (Before Delay)
- **File Name**: `evidence_02_ping_baseline.log` (and optional `.png`)
- **How to Generate**:
  ```bash
  # Execute on Mars Host before netem is applied:
  sudo ip netns exec mars_host ping -c 5 10.10.10.10 | tee results/evidence/evidence_02_ping_baseline.log
  ```
- **What It Proves**: Confirms network routing is fully functional and natural simulation delay is $< 1\text{ ms}$.

---

### Artifact E-03: Delayed Ping Output (After Delay Injection)
- **File Name**: `evidence_03_ping_delayed_5s.log` (and optional `.png`)
- **How to Generate**:
  ```bash
  # Execute on Mars Host after netem Profile A is active:
  sudo ip netns exec mars_host ping -c 3 10.10.10.10 | tee results/evidence/evidence_03_ping_delayed_5s.log
  ```
- **What It Proves**: Confirms that round-trip delay jumped from $< 1\text{ ms}$ to **~10,012 ms (10 seconds)**, demonstrating channel emulation.

---

### Artifact E-04: TCP iPerf3 Experiment Log
- **File Name**: `evidence_04_tcp_delay.json`
- **How to Generate**:
  ```bash
  # Execute on Mars Host:
  sudo ip netns exec mars_host iperf3 -c 10.10.10.10 -p 5201 -t 30 -i 1 --json > results/evidence/evidence_04_tcp_delay.json
  ```
- **What It Proves**: Captures interval-by-interval throughput degradation, slow start delays, and TCP retransmission counts.

---

### Artifact E-05: UDP iPerf3 Telemetry Log
- **File Name**: `evidence_05_udp_delay.json`
- **How to Generate**:
  ```bash
  # Execute on Mars Host:
  sudo ip netns exec mars_host iperf3 -c 10.10.10.10 -p 5201 -u -b 2M -t 30 -i 1 --json > results/evidence/evidence_05_udp_delay.json
  ```
- **What It Proves**: Demonstrates that UDP telemetry sustains 1.96 Mbps at line rate regardless of propagation delay.

---

### Artifact E-06: Deep-Space Packet Trace (PCAP)
- **File Name**: `evidence_06_project_ares.pcap`
- **How to Generate**:
  ```bash
  # Capture on Mars Host interface during iPerf3 runs:
  sudo ip netns exec mars_host tcpdump -i mh_eth0 -w results/evidence/evidence_06_project_ares.pcap -c 200 "host 10.10.10.10"
  ```
- **What It Proves**: Authentic packet-level proof containing ICMP echo sequences, TCP 3-way handshakes, and UDP datagrams.

---

### Artifact E-07: Wireshark Delayed ACKs & Retransmissions Screenshot
- **File Name**: `evidence_07_wireshark_retrans.png`
- **How to Generate**:
  1. Open `evidence_06_project_ares.pcap` in Wireshark.
  2. In the display filter bar, enter: `tcp.analysis.retransmission || tcp.analysis.ack_rtt > 1.0`.
  3. Ensure the Time column is formatted as "Seconds Since Previous Displayed Packet".
  4. Capture a clean screenshot of the packet listing showing retransmission flags and multi-second RTT.
- **What It Proves**: Direct visual evidence of TCP sliding window stalling due to delayed ACKs and subsequent spurious retransmits.

---

### Artifact E-08: NetEm Configuration Screenshot
- **File Name**: `evidence_08_netem_qdisc.png`
- **How to Generate**:
  ```bash
  # On Space Emulator, run:
  sudo ip netns exec space_emulator tc -s qdisc show dev se_eth0
  ```
  Take a screenshot showing `qdisc netem`, `delay 5000ms`, `loss 2%`, and `limit 10000`.
- **What It Proves**: Verifies that delay was injected at the kernel queuing discipline level with explicit queue limits to prevent artificial buffer drops.

---

### Artifact E-09: Router Forwarding Tables Screenshot
- **File Name**: `evidence_09_routing_tables.png`
- **How to Generate**:
  Run `ip route show` across Mars Router, Space Emulator, and Earth Router, placing outputs side by side.
- **What It Proves**: Confirms static route symmetry and loop-free forwarding across all subnets.

---

### Artifact E-10: Results Summary Table
- **File Name**: `evidence_10_results_summary.csv`
- **How to Generate**:
  Populated directly by `build/analyze_iperf.py` or copied from `results/parsed_iperf_summary.csv`.
- **What It Proves**: Provides structured quantitative evidence comparing mean throughput, retransmissions, and jitter.

---

### Artifact E-11: Comparative Throughput Graph
- **File Name**: `tcp_vs_udp_throughput.png`
- **How to Generate**:
  ```bash
  python3 build/analyze_iperf.py results/evidence/evidence_04_tcp_delay.json results/evidence/evidence_05_udp_delay.json
  cp tcp_vs_udp_throughput.png results/evidence/
  ```
- **What It Proves**: Publication-grade comparative visualization showing TCP throughput collapse alongside stable UDP line-rate streaming.

---

## 3. Automated Evidence Packaging Script

Run this command from your project root to automatically generate the evidence folder and bundle it into a compressed tarball for submission:

```bash
# [Host Machine] Bundle all evidence into submission archive
mkdir -p results/evidence
cp tcp_vs_udp_throughput.png results/evidence/ 2>/dev/null || true
cp results/*.csv results/evidence/ 2>/dev/null || true
tar -czvf project_ares_evidence_pack.tar.gz results/evidence/
echo "[+] Evidence pack successfully created: project_ares_evidence_pack.tar.gz"
```
