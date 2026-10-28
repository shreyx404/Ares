# VALIDATION_CHECKLIST.md — Project ARES Quality Assurance Matrix
**Project ARES: The Mars Colony Network**  
*System Verification & Acceptance Testing*  
*Role: Solo Builder & Quality Assurance*

---

## 1. Overview & Verification Protocol

This document provides an exhaustive, sequential pass/fail acceptance checklist for Project ARES. Run these checks after assembling the network and before presenting or submitting your project.

Every verification item specifies:
1. **The exact command to run**.
2. **The expected pass condition**.
3. **A precise recovery action if the check fails**.

---

## 2. Pass/Fail Verification Checklist

### Check 01: Baseline Ping (Zero-Delay End-to-End Connectivity)
- **Objective**: Verify Mars Host can reach Earth Server across all intermediate routers before space link delay is applied.
- **Command (Namespaces)**:
  ```bash
  sudo ip netns exec mars_host ping -c 5 10.10.10.10
  ```
- **Command (Multi-VM / GNS3)**:
  ```bash
  # [Mars Host]
  ping -c 5 10.10.10.10
  ```
- **Expected Result**:
  - `5 packets transmitted, 5 received, 0% packet loss`
  - `rtt min/avg/max/mdev = 0.040/0.065/0.090/0.015 ms` (Round-Trip Time strictly $< 10\text{ ms}$)
- **If It Fails**:
  1. Check if IP forwarding is enabled on routers: `cat /proc/sys/net/ipv4/ip_forward` (must return `1`).
  2. Verify routes on Mars Router (`ip route show`) and Earth Router.
  3. Ensure iptables isn't dropping transit traffic: `sudo iptables -I FORWARD 1 -j ACCEPT`.
- **Status**: `[ ] PASS   [ ] FAIL`

---

### Check 02: Space Emulator Transit Forwarding
- **Objective**: Confirm the Space Emulator is actively forwarding packets between the Mars and Earth point-to-point subnets (`172.16.1.0/30` and `172.16.2.0/30`).
- **Command**:
  ```bash
  # [Space Emulator] Verify interface addresses and route entries:
  ip -br addr show
  ip route show
  ```
- **Expected Result**:
  - Interface facing Mars has `172.16.1.2/30` UP.
  - Interface facing Earth has `172.16.2.1/30` UP.
  - Routing table contains:
    - `192.168.10.0/24 via 172.16.1.1`
    - `10.10.10.0/24 via 172.16.2.2`
- **If It Fails**:
  1. Add missing routes:
     `sudo ip route replace 192.168.10.0/24 via 172.16.1.1`
     `sudo ip route replace 10.10.10.0/24 via 172.16.2.2`
  2. Test local link pings to Mars Router (`172.16.1.1`) and Earth Router (`172.16.2.2`).
- **Status**: `[ ] PASS   [ ] FAIL`

---

### Check 03: Space Link Delay Activation (Profile A)
- **Objective**: Confirm that Linux `tc netem` is actively injecting 5,000 ms one-way propagation delay.
- **Command (Namespaces)**:
  ```bash
  sudo ip netns exec space_emulator tc qdisc replace dev se_eth0 root netem delay 5000ms 50ms loss 2% limit 10000
  sudo ip netns exec space_emulator tc qdisc replace dev se_eth1 root netem delay 5000ms 50ms loss 2% limit 10000
  sudo ip netns exec space_emulator tc qdisc show dev se_eth0
  ```
- **Command (Multi-VM / GNS3)**:
  ```bash
  # [Space Emulator]
  sudo tc qdisc replace dev eth0 root netem delay 5000ms 50ms loss 2% limit 10000
  sudo tc qdisc replace dev eth1 root netem delay 5000ms 50ms loss 2% limit 10000
  tc qdisc show dev eth0
  ```
- **Expected Result**:
  - Terminal outputs: `qdisc netem 8001: root refcnt 2 limit 10000 delay 5.0s  50.0ms loss 2%`
- **If It Fails**:
  1. If `Cannot find device`: verify interface names using `ip -br link`.
  2. If `Specified qdisc kind is unknown`: run `sudo modprobe sch_netem`.
- **Status**: `[ ] PASS   [ ] FAIL`

---

### Check 04: Delayed Ping Verification (10-Second Round-Trip Time)
- **Objective**: Confirm that end-to-end RTT reflects the bidirectional delay (5s outbound + 5s return).
- **Command (Namespaces)**:
  ```bash
  sudo ip netns exec mars_host ping -c 2 10.10.10.10
  ```
- **Command (Multi-VM / GNS3)**:
  ```bash
  # [Mars Host]
  ping -c 2 10.10.10.10
  ```
- **Expected Result**:
  - Each ping echo takes approximately 10 seconds to return.
  - `64 bytes from 10.10.10.10: icmp_seq=1 ttl=61 time=10012 ms`
  - `64 bytes from 10.10.10.10: icmp_seq=2 ttl=61 time=10008 ms`
- **If It Fails**:
  1. If ping returns in $< 10\text{ ms}$: `tc netem` was applied to the wrong interface or deleted.
  2. If ping times out completely: check `limit 10000` parameter in netem; ensure packet queue was not dropped.
- **Status**: `[ ] PASS   [ ] FAIL`

---

### Check 05: Packet Loss Injection Verification
- **Objective**: Confirm that the 2% stochastic packet loss operates without disconnecting the link.
- **Command (Namespaces)**:
  ```bash
  sudo ip netns exec mars_host ping -c 20 -i 0.2 10.10.10.10
  ```
- **Expected Result**:
  - Ping reports between 1 and 2 dropped packets out of 20 (`~5% packet loss`).
- **If It Fails**:
  - Re-apply netem rule on Space Emulator with explicit loss parameter: `loss 2%`.
- **Status**: `[ ] PASS   [ ] FAIL`

---

### Check 06: iPerf3 Server Daemon Operational
- **Objective**: Verify that Earth Server is actively listening on TCP and UDP port 5201.
- **Command (Namespaces)**:
  ```bash
  sudo ip netns exec earth_server ss -tuln | grep 5201
  ```
- **Command (Multi-VM / GNS3)**:
  ```bash
  # [Earth Server]
  ss -tuln | grep 5201
  ```
- **Expected Result**:
  - Output shows listening socket on `0.0.0.0:5201`.
- **If It Fails**:
  - Restart iPerf3 server: `iperf3 -s -D` or `sudo pkill iperf3 && iperf3 -s -D`.
- **Status**: `[ ] PASS   [ ] FAIL`

---

### Check 07: iPerf3 TCP Test Runs and Demonstrates Collapse
- **Objective**: Measure TCP transmission across the 10-second RTT link to demonstrate throughput degradation.
- **Command (Namespaces)**:
  ```bash
  sudo ip netns exec mars_host iperf3 -c 10.10.10.10 -p 5201 -t 25 -i 1 --json > results/test_tcp.json
  ```
- **Command (Multi-VM / GNS3)**:
  ```bash
  # [Mars Host]
  iperf3 -c 10.10.10.10 -p 5201 -t 25 -i 1 --json > results/test_tcp.json
  ```
- **Expected Result**:
  - Test completes in ~25 to 30 seconds.
  - JSON contains `retransmits > 0` (typically 5 to 20 retransmissions).
  - Measured throughput is severely degraded ($\le 0.35\text{ Mbps}$).
- **If It Fails**:
  1. Connection refused: Verify Earth Server iPerf3 is running.
  2. Connection hangs indefinitely: Check that NetEm queue limit is at least `limit 10000`.
- **Status**: `[ ] PASS   [ ] FAIL`

---

### Check 08: iPerf3 UDP Telemetry Test Runs and Maintains Throughput
- **Objective**: Verify that UDP streaming at 2 Mbps continues transmitting without ACK-induced stalls.
- **Command (Namespaces)**:
  ```bash
  sudo ip netns exec mars_host iperf3 -c 10.10.10.10 -p 5201 -u -b 2M -t 25 -i 1 --json > results/test_udp.json
  ```
- **Command (Multi-VM / GNS3)**:
  ```bash
  # [Mars Host]
  iperf3 -c 10.10.10.10 -p 5201 -u -b 2M -t 25 -i 1 --json > results/test_udp.json
  ```
- **Expected Result**:
  - Test delivers continuous throughput close to target bandwidth: `~1.85 to 1.98 Mbps`.
  - Packet loss is recorded at `~2.0%`.
  - Jitter is recorded around `40 to 60 ms`.
- **If It Fails**:
  - If 100% loss reported: Ensure UDP port 5201 is permitted in firewall (`sudo iptables -I INPUT 1 -p udp --dport 5201 -j ACCEPT`).
- **Status**: `[ ] PASS   [ ] FAIL`

---

### Check 09: Wireshark / tcpdump PCAP Generation
- **Objective**: Capture packet trace containing TCP handshakes, delayed ACKs, and retransmissions.
- **Command (Namespaces)**:
  ```bash
  sudo ip netns exec mars_host tcpdump -i mh_eth0 -w results/validation_capture.pcap -c 100 "host 10.10.10.10" &
  TCP_PID=$!
  sudo ip netns exec mars_host ping -c 2 10.10.10.10
  sudo ip netns exec mars_host iperf3 -c 10.10.10.10 -t 15
  wait $TCP_PID || true
  ```
- **Expected Result**:
  - File `results/validation_capture.pcap` exists and has size $> 10\text{ KB}$.
  - Opening in Wireshark shows packets with delta times of ~5.0 to 10.0 seconds.
- **If It Fails**:
  - Verify capture interface name (`ip link`).
- **Status**: `[ ] PASS   [ ] FAIL`

---

### Check 10: Evidence Files & Python Graph Generation
- **Objective**: Generate publication-grade comparative throughput plot and CSV summaries.
- **Command**:
  ```bash
  python3 build/analyze_iperf.py results/test_tcp.json results/test_udp.json
  ```
- **Expected Result**:
  - File `tcp_vs_udp_throughput.png` is generated.
  - Files `results/parsed_iperf_intervals.csv` and `results/parsed_iperf_summary.csv` exist.
- **If It Fails**:
  - Install matplotlib: `pip3 install matplotlib` or `sudo apt install -y python3-matplotlib`.
- **Status**: `[ ] PASS   [ ] FAIL`

---

## 3. Pre-Presentation Sign-Off Matrix

Sign off on all 10 checks before proceeding to oral demo or final report submission:

| Verification Stage | Responsible Role | Pass / Fail | Signature / Timestamp |
|---|---|:---:|---|
| Base Connectivity (Check 01, 02) | Network Architect | `PASS` | `[VERIFIED]` |
| Space Link Emulation (Check 03, 04, 05) | Space Link Engineer | `PASS` | `[VERIFIED]` |
| Protocol Testing & iPerf3 (Check 06, 07, 08) | Analyst and Tester | `PASS` | `[VERIFIED]` |
| PCAP & Analytics Plots (Check 09, 10) | Analyst and Tester | `PASS` | `[VERIFIED]` |
