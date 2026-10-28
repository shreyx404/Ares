# SLIDES_OUTLINE.md — 10-Slide Final Evaluation Presentation Outline
**Project ARES: The Mars Colony Network**  
*Interplanetary Transport Protocol Benchmarking & Emulation*  
*Target Deck Length: 10 Slides (8 to 9 Minutes Total Presentation Time)*

---

## Slide 1: Title Slide
- **Slide Title**: Project ARES: The Mars Colony Network
- **Subtitle**: Performance Evaluation of Interplanetary Protocols under Scaled Latency and Stochastic Packet Loss
- **Presenter**: **Presenter 1 (Project Narrator)**
- **Bullet Points**:
  - Course: Data Communication and Networking (DCN) — Fall 2026
  - Department of Computer Science & Engineering
  - Team Presenters:
    - Member 1: Project Narrator & Network Architect
    - Member 2: Demo Operator & Space Link Engineer
    - Member 3: Protocol Analyst & Quality Assurance
- **Visual / Graphic**: High-contrast rendering of Earth-to-Mars orbital link with deep space background.
- **Key Takeaway**: Project ARES is an empirical investigation into why standard Internet protocols fail across interplanetary distances.

---

## Slide 2: Problem Statement
- **Slide Title**: The Fundamental Fragility of Terrestrial Internet Protocols
- **Presenter**: **Presenter 1 (Project Narrator)**
- **Bullet Points**:
  - Terrestrial protocols (TCP/IP) rely on sub-100ms round-trip acknowledgment clocks.
  - Deep space introduces massive propagation delays (light travels at $300,000\text{ km/s}$).
  - Standard TCP misinterprets long propagation delay and random loss as severe router congestion.
  - Core Research Question: How do fundamental transport protocols behave across an interplanetary link, and what is required to maintain mission communication?
- **Visual / Graphic**: Diagram comparing terrestrial fiber ping (< 20 ms) vs. interplanetary radio ping (6 to 44 minutes).
- **Key Takeaway**: Standard TCP cannot distinguish between a packet delayed by astronomical distance and a packet lost to network congestion.

---

## Slide 3: Why Mars Communication is Different
- **Slide Title**: Orbital Mechanics & Channel Physics
- **Presenter**: **Presenter 1 (Project Narrator)**
- **Bullet Points**:
  - Distance fluctuates drastically: $54.6\text{M km}$ at closest approach to $401\text{M km}$ at conjunction.
  - One-Way Light Time (OWLT) ranges between **3.03 minutes and 22.2 minutes** (RTT: 6 to 44 mins).
  - High bit-error rate caused by solar radiation, plasma scintillation, and cosmic interference.
  - Periodic complete blackouts occur during Solar Conjunction (Sun blocks direct line of sight).
- **Visual / Graphic**: Orbit diagram showing Earth and Mars orbiting the Sun, illustrating perihelic opposition vs. solar conjunction.
- **Key Takeaway**: End-to-end continuous connections cannot exist across deep space; latency is dominated by the speed of light.

---

## Slide 4: Project Topology & Architecture
- **Slide Title**: Multi-Segment Interplanetary Network Architecture
- **Presenter**: **Presenter 1 (Narrator)** transitioning to **Presenter 2 (Demo Operator)**
- **Bullet Points**:
  - 3 Isolated Operational Domains: Mars LAN, Interplanetary Space Link, Earth LAN.
  - Mars Colony LAN (`192.168.10.0/24`): Habitat life-support telemetry & scientific workstations.
  - Deep Space Link (`172.16.1.0/30` & `172.16.2.0/30`): Dedicated point-to-point emulation segment.
  - Earth Mission Control LAN (`10.10.10.0/24`): Data repository and command uplink server.
- **Visual / Graphic**: Network topology diagram showing Mars Host $\leftrightarrow$ Mars Router $\leftrightarrow$ Space Emulator $\leftrightarrow$ Earth Router $\leftrightarrow$ Earth Server.
- **Key Takeaway**: Clean architectural separation guarantees that local habitat traffic remains low-latency while long-haul traffic traverses the space link.

---

## Slide 5: IP Addressing & Deterministic Routing
- **Slide Title**: Addressing Schema & Loop-Free Static Routing
- **Presenter**: **Presenter 2 (Demo Operator)**
- **Bullet Points**:
  - Clean Class C (`/24`) subnets for habitat endpoints; tight Class B (`/30`) subnets for space links.
  - Mars Router: Default static route forward to Space Emulator (`172.16.1.2`).
  - Earth Router: Default static route forward to Space Emulator (`172.16.2.1`).
  - Space Emulator: Bi-directional routing to Mars (`192.168.10.0/24`) and Earth (`10.10.10.0/24`).
  - Dynamic routing (OSPF/RIP) intentionally avoided to prevent protocol hello/keepalive timeouts.
- **Visual / Graphic**: Table of subnets and interface assignments alongside a visual packet flow diagram.
- **Key Takeaway**: Static routing eliminates protocol overhead and guarantees deterministic packet forwarding across the space barrier.

---

## Slide 6: Space-Link Delay Emulation (Linux NetEm)
- **Slide Title**: Scaled Interplanetary Latency Modeling
- **Presenter**: **Presenter 2 (Demo Operator)**
- **Bullet Points**:
  - Scaled Model Rationale: True 20-minute RTT prevents live evaluation; a scaled 10-second RTT reproduces identical protocol dynamics.
  - **Profile A (Standard Demo)**: 5,000 ms one-way delay $\rightarrow$ **10,000 ms RTT**, **2% packet loss**, 50 ms jitter.
  - Implemented using Linux Traffic Control (`tc netem`) queuing disciplines.
  - Explicit queue limit sizing (`limit 10000`) prevents artificial tail-drop buffer overflow.
- **Visual / Graphic**: Terminal screenshot of `tc qdisc show dev se_eth0` and 10,012 ms ICMP ping output.
- **Key Takeaway**: Linux `tc netem` provides a deterministic, repeatable, kernel-level space channel simulation.

---

## Slide 7: TCP Test Results — Window Starvation & Collapse
- **Slide Title**: The Collapse of TCP Bulk Data Transfer
- **Presenter**: **Presenter 3 (Analyst & Protocol Specialist)**
- **Bullet Points**:
  - Target: Scientific bulk file transmission across the 10-second RTT link.
  - **Result**: Throughput collapsed to **0.216 Mbps** (over 90% performance loss).
  - Slow Start stalled: Each window expansion requires a 10-second round-trip ACK arrival.
  - Multiplicative Decrease: Single 2% loss drops the congestion window back to 1 segment.
  - Premature Retransmissions: Retransmission timer (RTO) expires while segments are legitimately in flight.
- **Visual / Graphic**: iPerf3 TCP terminal output showing retransmission counter (14 retransmits) and low throughput numbers.
- **Key Takeaway**: TCP's fundamental requirement for end-to-end feedback starves the transmission channel.

---

## Slide 8: UDP Test Results — Telemetry Resilience
- **Slide Title**: The Resilience of UDP Life-Support Telemetry
- **Presenter**: **Presenter 3 (Analyst & Protocol Specialist)**
- **Bullet Points**:
  - Target: Mars habitat environmental telemetry (oxygen, pressure, radiation) at 2.0 Mbps CBR.
  - **Result**: Sustained throughput of **1.962 Mbps** (98% channel utilization).
  - Unacknowledged Streaming: UDP continuously pushes packets without waiting for ACK handshakes.
  - Tolerate Channel Errors: Absorbed 2.1% stochastic loss without stalling the application stream.
  - Timeliness over Completeness: For live life-support monitoring, the newest sensor reading is vastly more critical than retransmitting old data.
- **Visual / Graphic**: iPerf3 UDP terminal output showing smooth 1.96 Mbps delivery rate and 2.1% loss.
- **Key Takeaway**: UDP enables continuous, unblocked sensor telemetry across multi-second propagation delays.

---

## Slide 9: Packet Forensics & Bandwidth-Delay Product (BDP)
- **Slide Title**: Mathematical Analysis & Wireshark Forensic Evidence
- **Presenter**: **Presenter 3 (Analyst & Protocol Specialist)**
- **Bullet Points**:
  - Mathematical Derivation: $\text{BDP} = \text{Bandwidth} \times \text{RTT} = 2\text{ Mbps} \times 10\text{ s} = 2.5\text{ Megabytes}$.
  - Socket Buffer Mismatch: Operating systems allocate default TCP socket buffers of only 64 KB.
  - The Buffer Bottleneck: $64\text{ KB} \ll 2.5\text{ MB}$; the sender window fills in milliseconds and blocks for 9.9 seconds.
  - Wireshark Evidence: Traces filtered by `tcp.analysis.retransmission` reveal duplicate packets sent while original packets were still traversing the space link.
- **Visual / Graphic**: High-resolution Matplotlib plot (`tcp_vs_udp_throughput.png`) and annotated Wireshark packet capture screenshot.
- **Key Takeaway**: Mathematical BDP limits prove that terrestrial socket architectures are physically incapable of saturating space links.

---

## Slide 10: Conclusion & The DTN Future
- **Slide Title**: Architectural Conclusions & Interplanetary Protocol Design
- **Presenter**: **Presenter 1 (Project Narrator)** with entire team
- **Bullet Points**:
  - Summary of Findings:
    - Terrestrial TCP collapses over interplanetary delays.
    - UDP is effective for unacknowledged, loss-tolerant telemetry.
  - The Definitive Solution: **Delay-Tolerant Networking (DTN)** and the **Bundle Protocol (RFC 5050)**.
  - Custody Transfer: Deep-space relays store bundles on persistent flash storage until the next hop is reachable, avoiding solar-distance handshakes.
  - Complete reproducible test suite, runbook, and evidence pack submitted in repository.
- **Visual / Graphic**: Conceptual diagram of NASA's Interplanetary Internet architecture showing Mars Orbiter hop-by-hop custody transfer.
- **Key Takeaway**: Interplanetary internetworking requires a paradigm shift from synchronous end-to-end streaming to asynchronous store-and-forward bundle architectures.
