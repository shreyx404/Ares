# VIVA_CHEATSHEET.md — Interplanetary Networking Viva & Oral Defense Cheatsheet
**Project ARES: The Mars Colony Network**  
*Master Oral Examination & Defense Guide for 3-Member Team*  
*Standard Textbooks: Kurose & Ross (8th Ed.), Forouzan (5th Ed.), Stevens (TCP/IP Illustrated)*

---

## Team Defense Strategy & Handoff Protocol

When the examination committee or professor asks a question:
1. **Listen to the Topic Trigger**: Identify whether the question concerns **Architecture/Routing** (Member 1), **Linux Kernel/NetEm** (Member 2), or **Transport Protocols/Math** (Member 3).
2. **Immediate Confident Ownership**: The assigned member immediately steps forward, maintains eye contact, and delivers the precise textbook-backed answer.
3. **No Hesitation or Overlap**: Other members remain attentive and confident. If the professor asks a follow-up, the primary owner responds first before optionally yielding to a teammate.

```text
+-----------------------------+-----------------------------+-----------------------------+
|    MEMBER 1: ARCHITECT      |   MEMBER 2: SPACE ENGINEER  |      MEMBER 3: ANALYST      |
|  - Subnetting & IP Design   |  - Linux Network Namespaces |  - TCP Window Dynamics      |
|  - Static vs Dynamic Routes |  - tc / NetEm Kernel Queues |  - Exact RTO & Jacobson Alg |
|  - Routing Table Mechanics  |  - Buffer Limits & Tail Drop|  - BDP Math & Buffer Sizing |
|  - DTN Architecture & Scope |  - Scaled Space Modeling    |  - QUIC vs UDP vs TCP Trade |
+-----------------------------+-----------------------------+-----------------------------+
```

---

## Category 1: Network Architecture & Subnetting (Member 1 — Network Architect)

### Question 01: "Why did you use static routing instead of standard dynamic protocols like OSPF or BGP?"
- **Assigned Presenter**: **Member 1 (Network Architect)**
- **Authoritative Textbook Answer**:
  > *"Dynamic interior and exterior routing protocols (such as OSPF, RIP, or BGP) are engineered around rapid keepalive messages and periodic neighbor state exchanges (e.g., OSPF Hello packets every 10 seconds with a 40-second Dead Interval, per RFC 2328).*
  > 
  > *Over an interplanetary link with a 10-second or multi-minute RTT, dynamic keepalives repeatedly time out. The router falsely declares the neighbor down, drops the adjacency, flushes its link-state database (LSDB), and triggers route flapping across the network.*
  > 
  > *Static routing eliminates all protocol protocol-overhead and ensures deterministic, loop-free forwarding across long-delay segments without keepalive timeout vulnerabilities (Kurose & Ross, Chapter 5)."*

---

### Question 02: "Explain your IP addressing design. Why did you choose `/30` subnets for the space segments instead of `/24`?"
- **Assigned Presenter**: **Member 1 (Network Architect)**
- **Authoritative Textbook Answer**:
  > *"We applied Classless Inter-Domain Routing (CIDR, RFC 4632) principles to conserve address space and strictly isolate broadcast domains.*
  > 
  > *For the Mars LAN (`192.168.10.0/24`) and Earth LAN (`10.10.10.0/24`), `/24` prefixes provide 254 usable host addresses, accommodating sensor clusters, habitat life-support units, and workstations.*
  > 
  > *For the space transit segments (`172.16.1.0/30` and `172.16.2.0/30`), a `/30` mask yields a 2-bit host field ($2^2 - 2 = 2$ usable IP addresses). Point-to-point links only connect two interface endpoints (e.g., Mars Router and Space Emulator). Allocating a `/24` to a point-to-point link wastes 252 host addresses, whereas `/30` is the standard professional design for serial and routed WAN segments (Forouzan, Chapter 19)."*

---

### Question 03: "What happens to the Time-to-Live (TTL) field of an IP packet traversing your 5-node topology?"
- **Assigned Presenter**: **Member 1 (Network Architect)**
- **Authoritative Textbook Answer**:
  > *"Per RFC 791, every Layer 3 routing hop decrements the IPv4 header's TTL field by exactly 1 before forwarding. If a packet enters with an initial TTL of 64 from Mars Host (`192.168.10.10`):*
  > 1. *Mars Router receives it, decrements TTL to 63, recalculates the header checksum, and forwards.*
  > 2. *Space Emulator receives it, decrements TTL to 62, recalculates checksum, and forwards.*
  > 3. *Earth Router receives it, decrements TTL to 61, recalculates checksum, and delivers to Earth Server.*
  > 
  > *When Earth Server receives the packet, the TTL reads 61. If any loop occurred, TTL would decrement to 0 and the dropping router would return an ICMP Type 11 (Time Exceeded) message to the sender."*

---

### Question 04: "Why can't you just place Mars and Earth inside the same flat Layer 2 subnet and bridge them?"
- **Assigned Presenter**: **Member 1 (Network Architect)**
- **Authoritative Textbook Answer**:
  > *"Bridging interplanetary distances across Layer 2 violates fundamental Ethernet design assumptions:*
  > 1. *Broadcast Storms: ARP requests are broadcast packets (`FF:FF:FF:FF:FF:FF`) flooded to all nodes. Over a 10-second link, ARP resolution would take 10 seconds before a single frame could transmit.*
  > 2. *Spanning Tree Protocol (STP) Failure: Bridge Protocol Data Units (BPDUs) have a Max Age of 20 seconds (IEEE 802.1D). High delay causes STP to declare bridges offline, inducing catastrophic bridging loops.*
  > 3. *MTU & Frame Collision: Ethernet CSMA/CD or frame timers collapse over astronomical propagation distances. Segmenting into routed Layer 3 domains terminates local broadcasts at the router boundary (Kurose & Ross, Chapter 6)."*

---

## Category 2: Linux Kernel & Network Emulation (Member 2 — Space Link Engineer)

### Question 05: "How do Linux Network Namespaces (`ip netns`) isolate network stacks on a single kernel?"
- **Assigned Presenter**: **Member 2 (Space Link Engineer)**
- **Authoritative Textbook Answer**:
  > *"Linux network namespaces provide complete virtualization of the operating system's network subsystem (`struct net` in the Linux kernel source).*
  > 
  > *Each namespace possesses its own completely isolated instance of:*
  > 1. *Network device list (`dev_base_head`).*
  > 2. *IPv4 and IPv6 routing tables (Forwarding Information Base, FIB).*
  > 3. *IPTables filter and NAT rule tables (`netfilter`).*
  > 4. *Socket tables and port binding spaces (TCP/UDP hash tables).*
  > 5. *`/proc/net` virtual filesystem.*
  > 
  > *Communication between namespaces is achieved using Virtual Ethernet (`veth`) pairs, which act as bidirectional software patch cables operating at Layer 2. A packet transmitted into one end emerges directly from the peer end in the other namespace via kernel memory buffers (`sk_buff`), bypassing hypervisor overhead entirely."*

---

### Question 06: "How does Linux Traffic Control (`tc netem`) actually inject delay and packet loss into the kernel?"
- **Assigned Presenter**: **Member 2 (Space Link Engineer)**
- **Authoritative Textbook Answer**:
  > *"Linux Traffic Control functions at the device egress queue level using Queuing Disciplines (qdiscs).*
  > 
  > *When a packet is routed out of an interface, the kernel calls `dev_queue_xmit()`, which enqueues the socket buffer (`sk_buff`) into the root qdisc.*
  > 
  > *Under `sch_netem`:*
  > 1. *Delay Injection: The netem scheduler computes an arrival timestamp ($T_{\text{send}} = T_{\text{current}} + \text{delay} \pm \text{jitter}$) and inserts the `sk_buff` into a time-ordered red-black tree or FIFO queue, setting a high-resolution kernel timer (`hrtimer`). When the timer fires, the packet is dequeued and transmitted.*
  > 2. *Packet Loss Injection: NetEm evaluates a pseudo-random number generator against the configured loss probability (e.g. 2%). If the random draw falls within the threshold, `kfree_skb()` is invoked, immediately dropping the packet and incrementing the interface drop counter without transmitting it (Hemminger, NetEm OSDL Paper)."*

---

### Question 07: "Why is the `limit 10000` parameter critical in your `tc netem` command? What happens if you omit it?"
- **Assigned Presenter**: **Member 2 (Space Link Engineer)**
- **Authoritative Textbook Answer**:
  > *"By default, the Linux `tc netem` scheduler allocates an internal queue buffer capacity of only 1,000 packets (`limit 1000`).*
  > 
  > *At a 5,000 ms delay with standard 1,500-byte MTU frames:*
  > $$\text{1,000 packets} \times 1,500\text{ bytes} = 1.5\text{ Megabytes of buffer storage}$$
  > *If an iPerf3 burst transmits at 4 Mbps across a 5-second delay pipe, the pipe requires $4,000,000 \times 5 = 20\text{ Mbits} = 2.5\text{ MB}$ of in-flight buffer.*
  > 
  > *If `limit` remains at default 1,000, the queue overflows, causing uncommanded tail-drop buffer drops. By explicitly setting `limit 10000`, we provide 15 MB of buffer headroom, ensuring that packet loss is strictly governed by our intentional 2% stochastic parameter rather than unintended buffer congestion."*

---

### Question 08: "Why did you apply NetEm bidirectionally on both `se_eth0` and `se_eth1`?"
- **Assigned Presenter**: **Member 2 (Space Link Engineer)**
- **Authoritative Textbook Answer**:
  > *"In Linux Traffic Control, queuing disciplines are fundamentally egress-only schedulers (`dev_queue_xmit`). They can only delay packets departing an interface, not packets arriving.*
  > 
  > *To emulate an authentic interplanetary space link where outbound traffic (Mars $\rightarrow$ Earth) and return traffic (Earth $\rightarrow$ Mars) each experience 5,000 ms of physical radio propagation through space:*
  > - *Applying netem on `se_eth1` delays outbound traffic transmitting to Earth by 5,000 ms.*
  > - *Applying netem on `se_eth0` delays return ACK packets transmitting back to Mars by 5,000 ms.*
  > 
  > *This guarantees an exact Round-Trip Time of $5,000 + 5,000 = 10,000\text{ ms}$, replicating bidirectional physical channel delay."*

---

### Question 09: "Why did you disable TCP Segmentation Offload (TSO) and Generic Segmentation Offload (GSO) on the Space Emulator?"
- **Assigned Presenter**: **Member 2 (Space Link Engineer)**
- **Authoritative Textbook Answer**:
  > *"Modern Network Interface Cards (NICs) use TSO and GSO to optimize CPU performance by passing huge buffer segments (up to 64 KB) to the network adapter, which slices them into 1,500-byte MTU frames in hardware.*
  > 
  > *However, when `tc netem` operates on an interface with offloading enabled, it treats the entire 64 KB super-packet as a single queue entry. If NetEm applies a 2% packet loss rule to a 64 KB super-packet, it drops all 64 KB at once instead of dropping a single 1,500-byte frame!*
  > 
  > *Disabling TSO, GSO, and GRO via `ethtool -K eth0 tso off gso off gro off` forces the Linux kernel to slice packets into individual 1,500-byte MTU frames before queuing, guaranteeing microsecond-accurate queue delay and realistic stochastic loss modeling."*

---

## Category 3: Transport Protocol Dynamics & BDP Math (Member 3 — Protocol Analyst)

### Question 10: "Calculate the Bandwidth-Delay Product (BDP) if bandwidth is 10 Mbps and RTT is 10 seconds. What is its networking significance?"
- **Assigned Presenter**: **Member 3 (Analyst & Protocol Specialist)**
- **Authoritative Textbook Answer**:
  > *"The Bandwidth-Delay Product (BDP) represents the volume of unacknowledged data that can be actively 'in flight' within the transmission channel at any given instant:*
  > $$\text{BDP} = \text{Bandwidth (bits/sec)} \times \text{Round-Trip Time (seconds)}$$
  > 
  > *Calculation:*
  > $$\text{BDP} = 10,000,000\text{ bps} \times 10\text{ sec} = 100,000,000\text{ bits}$$
  > *Converting to Bytes:*
  > $$\text{BDP}_{\text{bytes}} = \frac{100,000,000\text{ bits}}{8\text{ bits/byte}} = 12,500,000\text{ Bytes}$$
  > *Converting to Megabytes (binary mebibytes):*
  > $$\text{BDP}_{\text{MB}} = \frac{12,500,000}{1024 \times 1024} \approx \mathbf{11.92\text{ MiB}} \quad (\text{or } 12.5\text{ MB decimal})$$
  > 
  > *Significance:*
  > *To achieve 100% link utilization without transmitter stalling, the sender's TCP Congestion Window ($cwnd$) and Socket Send/Receive Buffer must be at least 11.92 MiB. If the window is smaller, the sender empties its window and halts, leaving the link starved (Kurose & Ross, Chapter 3)."*

---

### Question 11: "Why exactly does the TCP congestion window close or collapse under high latency?"
- **Assigned Presenter**: **Member 3 (Analyst & Protocol Specialist)**
- **Authoritative Textbook Answer**:
  > *"TCP congestion control (RFC 5681, Reno / Cubic) relies on self-clocking driven by ACK reception:*
  > 1. *Slow-Start Throttling: During Slow Start, $cwnd$ increases by 1 MSS for every received ACK ($cwnd \leftarrow cwnd + MSS$). In a 10ms network, $cwnd$ doubles every 10ms. In our space link, an ACK takes 10,000 ms to return; thus, $cwnd$ doubles only once every 10 seconds, leaving the window minuscule for minutes.*
  > 2. *Multiplicative Decrease: When our 2% stochastic loss drops a single segment, the sender fails to receive an ACK. Upon detecting loss via 3 duplicate ACKs (Fast Retransmit), TCP halves its window ($cwnd \leftarrow cwnd / 2$).*
  > 3. *RTO Expiration Collapse: If a timeout occurs, TCP enters the most severe penalty state: it resets $cwnd = 1\text{ MSS}$, sets slow-start threshold $ssthresh = cwnd/2$, and resets transmission to Slow Start. Because space loss is stochastic rather than buffer-overflow congestion, TCP unnecessarily penalizes itself repeatedly (Stevens, TCP/IP Illustrated Vol. 1)."*

---

### Question 12: "What is the exact Retransmission Timeout (RTO) formula according to RFC 6298 (Jacobson's Algorithm)?"
- **Assigned Presenter**: **Member 3 (Analyst & Protocol Specialist)**
- **Authoritative Textbook Answer**:
  > *"RFC 6298 computes the Retransmission Timeout (RTO) using Jacobson's smoothed round-trip time (SRTT) and round-trip time variation (RTTVAR):*
  > 
  > 1. *First Measurement:*
  >    $$\text{SRTT} \leftarrow \text{SampleRTT}$$
  >    $$\text{RTTVAR} \leftarrow \frac{\text{SampleRTT}}{2}$$
  > 2. *Subsequent Measurements:*
  >    $$\text{RTTVAR} \leftarrow (1 - \beta) \cdot \text{RTTVAR} + \beta \cdot |\text{SRTT} - \text{SampleRTT}| \quad (\text{where } \beta = 0.25)$$
  >    $$\text{SRTT} \leftarrow (1 - \alpha) \cdot \text{SRTT} + \alpha \cdot \text{SampleRTT} \quad (\text{where } \alpha = 0.125)$$
  > 3. *RTO Calculation:*
  >    $$\text{RTO} = \text{SRTT} + \max(G, 4 \cdot \text{RTTVAR})$$
  >    *(where $G$ is the clock granularity, typically $\le 1\text{ ms}$).*
  > 
  > *Crucial Space Gotcha — Karn's Algorithm:*
  > *Karn's algorithm mandates that SampleRTT must NOT be measured for retransmitted segments. In a lossy high-delay channel where retransmissions are frequent, SRTT cannot update, causing RTO to double exponentially ($RTO \leftarrow 2 \cdot RTO$, exponential backoff) up to maximum caps (60 to 120 seconds), stalling communication completely."*

---

### Question 13: "Why did UDP achieve ~1.96 Mbps while TCP collapsed to ~0.21 Mbps under the exact same channel conditions?"
- **Assigned Presenter**: **Member 3 (Analyst & Protocol Specialist)**
- **Authoritative Textbook Answer**:
  > *"The performance divergence stems from transport layer decoupling:*
  > 1. *Connectionless and Unacknowledged: UDP (RFC 768) does not implement a 3-way handshake, does not wait for ACK confirmation, does not maintain a sliding window, and has no congestion control mechanisms.*
  > 2. *Application-Clocked Rate: When iPerf3 is configured for 2.0 Mbps Constant Bitrate (`-u -b 2M`), UDP packages datagrams and pushes them into the kernel socket buffer continuously at line rate regardless of propagation latency.*
  > 3. *Stochastic Loss Tolerance: The 2.0% packet loss dropped 2.0% of the datagrams in transit. However, UDP did not halve its rate or halt transmission. It simply continued streaming the remaining 98% of packets.*
  > 
  > *For environmental telemetry (habitat oxygen, pressure, radiation), timeliness is vastly more important than reliable retransmission. A sensor reading delivered 5 seconds late is useful; stalling the link for 30 seconds to retransmit old data is detrimental."*

---

### Question 14: "Why not just use QUIC (HTTP/3) instead of UDP for Mars communication?"
- **Assigned Presenter**: **Member 3 (Analyst & Protocol Specialist)**
- **Authoritative Textbook Answer**:
  > *"While QUIC (RFC 9000) runs on top of UDP and resolves TCP's head-of-line blocking across multiple streams, it is still fundamentally an end-to-end acknowledged protocol:*
  > 1. *Mandatory Handshake: QUIC requires a 1-RTT cryptographic handshake (TLS 1.3). Over a 20-minute RTT, establishing a QUIC session still takes 20 minutes before data can transmit.*
  > 2. *ACK-Driven Congestion Control: QUIC implements congestion control algorithms (CUBIC or BBR). It still requires ACK frames returning from the receiver to expand its congestion window. Over a 10-second or multi-minute RTT, QUIC suffers identical window starvation to TCP.*
  > 3. *Connection Migration: QUIC's connection IDs are valuable for mobile rovers switching antennas, but cannot solve physical speed-of-light propagation delays.*
  > 
  > *Therefore, QUIC does not solve interplanetary latency. The only architectural solution is store-and-forward Delay-Tolerant Networking (RFC 5050)."*

---

### Question 15: "What is Delay-Tolerant Networking (DTN) and how does the Bundle Protocol (RFC 5050) solve deep space communication?"
- **Assigned Presenter**: **Member 1 (Network Architect)** *with technical support from* **Member 3**
- **Authoritative Textbook Answer**:
  > *"Delay-Tolerant Networking (DTN, RFC 4838) replaces synchronous end-to-end communication with an asynchronous **Store-and-Forward Overlay Architecture** using the **Bundle Protocol (RFC 5050 / RFC 9171)**.*
  > 
  > *Key Mechanisms:*
  > 1. *Custody Transfer: When a node transmits a bundle of data to the next hop (e.g., Mars Habitat $\rightarrow$ Mars Reconnaissance Orbiter), the intermediate orbiter accepts 'custody' and writes the bundle to persistent non-volatile storage (flash memory).*
  > 2. *Hop-by-Hop Reliability: If packet loss occurs on the space link between the orbiter and Earth ground station, retransmission occurs only across that single physical segment, rather than requiring an acknowledgment from Earth to Mars.*
  > 3. *Tolerance to Partitioning: If an orbital eclipse or planetary rotation severs line-of-sight, the bundle remains safely in storage on the orbiter for hours or days until the link reappears.*
  > 
  > *DTN shifts the transport paradigm from an end-to-end conversation to postal-like asynchronous bundle custody (Cerf et al., RFC 4838)."*

---
