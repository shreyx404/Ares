# ASSUMPTIONS.md — Project ARES Engineering Assumptions

This document records all baseline assumptions, design trade-offs, and operational decisions made during the architecture and implementation of Project ARES: The Mars Colony Network.

---

## 1. Physical vs. Scaled Latency Modeling
- **Real-World Reality**: Earth-Mars distance varies from approximately $54.6 \times 10^6\text{ km}$ (perihelic opposition) to $401 \times 10^6\text{ km}$ (conjunction). Corresponding one-way light time (OWLT) ranges from **~3.03 minutes (182 seconds)** to **~22.2 minutes (1,334 seconds)**, yielding Round-Trip Times (RTT) of **6 to 44 minutes**.
- **Laboratory Scaled Model**:
  - Running interactive classroom demonstrations and multiple statistical test runs under a 20-minute RTT is physically impractical (a single 3-way TCP handshake would take 60 minutes).
  - Therefore, delay is **scaled down** while preserving identical protocol dynamics:
    - **Profile A (Standard Demo)**: One-way delay = **5,000 ms (5 s)** $\rightarrow$ RTT = **10,000 ms (10 s)**, Loss = **2%**.
    - **Profile B (Strong Mars Effect)**: One-way delay = **15,000 ms (15 s)** $\rightarrow$ RTT = **30,000 ms (30 s)**, Loss = **5%**.
    - **Profile C (Extended Analysis)**: One-way delay = **60,000 ms (60 s)** $\rightarrow$ RTT = **120,000 ms (120 s)**, Loss = **10%**.
- **Theoretical Justification**: The scaling maintains the core constraint where RTT vastly exceeds standard TCP initial Retransmission Timeout ($RTO \approx 1\text{ s}$) and standard socket buffer capacities, causing identical congestion window collapse and ACK starvation.

---

## 2. Linux `tc netem` Queue Limit Sizing
- **Problem**: In Linux `tc netem`, the default packet queue limit is 1,000 packets (`limit 1000`).
- **Assumption & Mitigation**: At a 5,000 ms or 15,000 ms delay with even modest transmission bursts (e.g., 2–10 Mbps), 1,000 packets represents only ~1.5 MB of data. The queue would experience uncommanded tail-drop buffer overflow, injecting unintended packet drops independent of the configured loss percentage.
- **Decision**: All `tc netem` rules in Project ARES explicitly define `limit 10000` (or `limit 20000`) to decouple queuing buffer limits from intentional stochastic packet loss.

---

## 3. Network Topologies (Dual Architecture Support)
To accommodate varied student hardware capabilities:
1. **Primary 5-Node Architecture**:
   - Comprises Mars Host, Mars Router, Space Emulator, Earth Router, and Earth Server.
   - Routers may be Cisco IOS (in GNS3/EVE-NG) or dual-homed Linux VMs with kernel IP forwarding.
2. **Fallback 3-Node Architecture**:
   - Mars Host $\leftrightarrow$ Space Emulator / Router $\leftrightarrow$ Earth Server.
   - For resource-constrained student systems where running 5 virtual machines causes CPU/RAM thrashing.
3. **Single-Machine Linux Network Namespaces**:
   - Provides an instant zero-overhead implementation where all 5 or 3 nodes run inside lightweight Linux network namespaces (`ip netns`) on an Ubuntu host without requiring virtual machines.

---

## 4. Operating System and Interface Conventions
- **Target OS**: Ubuntu 22.04 LTS / 24.04 LTS or Debian 12 (applicable across VMware, VirtualBox, GNS3, or bare metal).
- **Interface Naming**: Linux network interfaces are assumed to be named `eth0` and `eth1` (standard in virtual environments / GNS3).
  - All shell scripts support overriding interface names via environment variables (`MARS_IF` and `EARTH_IF`) or CLI arguments to support predictable naming (`ens3`, `enp0s3`).

---

## 5. Traffic Profiles and Telemetry Modeling
- **Telemetry Simulation (UDP)**:
  - Mars colony environmental sensor telemetry (life support, oxygen levels, habitat pressure, radiation monitors) is modeled as a constant bitrate (CBR) stream at **2 Mbps** (`-u -b 2M`).
  - Assumption: Sensor streams prioritize low overhead and immediate delivery of latest readings over guaranteed retransmission.
- **Mission Control Data Transfer (TCP)**:
  - Large scientific imagery, system software updates, and log archives are modeled using unconstrained TCP streams.
  - Default TCP congestion control: Linux standard `cubic` (with notes on `bbr` and `reno`).

---

## 6. Time Synchronization & Measurement Precision
- Because Mars Host and Earth Server operate across an emulated link, clocks between VMs should be synchronized via local host time or NTP prior to packet capture to ensure Wireshark delta time measurements match true one-way propagation.
- iPerf3 sender and receiver JSON outputs are collected at the client to ensure consistent statistical parsing.

---

## 7. Solo Implementation vs. 3-Presenter Academic Model
- **Implementation Reality**: The entire simulation framework, test automation scripts, network namespaces, and data analytics pipeline are built and executed by a single engineer (the solo builder).
- **Presentation Model**: To satisfy academic evaluation criteria requiring a 3-member team, responsibilities are cleanly bifurcated into three distinct presentation personas:
  - **Presenter 1 (Project Narrator)**: Interplanetary physics, mission scope, topology, and DTN conclusions.
  - **Presenter 2 (Demo Operator)**: Live terminal commands, delay injection, and link monitoring.
  - **Presenter 3 (Analyst & Protocol Specialist)**: Transport layer mechanics, TCP collapse, UDP telemetry, Wireshark packet traces, and BDP mathematics.
- **Academic Consistency**: All documentation, reports, and commit structures reflect the 3-member split while all runbooks (`RUNBOOK_SOLO.md`) are optimized for seamless solo execution.

---

## 8. Dual-Laptop Hardware Architecture
- **Live Presentation Setup**: Two laptops are utilized during the final oral examination:
  - **Laptop A (Primary Demo Engine)**: Dedicated solely to executing the simulation, NetEm scripts, and iPerf3 traffic generation. Runs terminal windows with 18pt font.
  - **Laptop B (Presentation & Fallback Station)**: Displays the slide deck, high-resolution Wireshark captures, and pre-computed Matplotlib plots. Hosts an identical cloned standby copy of the repository in case Laptop A encounters hardware issues.
