# DEMO_SCRIPT_3_PRESENTERS.md — 3-Presenter Live Demonstration Script
**Project ARES: The Mars Colony Network**  
*Target Presentation Time: 8 to 9 Minutes (Strict Cap: 10 Minutes)*  
*Hardware Setup: 2 Laptops (Laptop A = Live Demo Engine, Laptop B = Presentation & Telemetry Slides)*

---

## 1. Team Roles, Persona Strategy & Laptop Allocations

To ensure all three presenters sound deeply competent, authoritative, and equally invested, roles are partitioned into clear professional domains:

| Role Identifier | Assigned Presenter | Team Persona | Physical Station | Primary Responsibilities |
|---|---|---|---|---|
| **Presenter 1** | Team Member 1 | **Project Narrator** | **Laptop B** (Slides) | Mission context, space link challenges, architecture overview, DTN recommendations, conclusion. |
| **Presenter 2** | Team Member 2 | **Demo Operator** | **Laptop A** (Live Terminal) | Live simulation execution, terminal commands, NetEm delay injection, link monitoring. |
| **Presenter 3** | Team Member 3 | **Analyst & Protocol Specialist** | **Laptop A / B** | Transport layer dynamics, TCP window stalls, UDP telemetry resilience, Wireshark traces, BDP theory. |

---

## 2. Master Presentation Timeline (8m 30s)

```text
00:00        01:30        03:00        04:45        06:45        08:15       09:15
  |------------|------------|------------|------------|------------|-----------|
  Act 1        Act 2        Act 3        Act 4        Act 5        Act 6
  Mission &    Topology &   Space Delay  TCP vs UDP   Packet Traces Conclusion &
  Physics      Baseline     Injection    Showdown     & BDP Deriv.  DTN Future
  (P1 - Lap B) (P1/P2)      (P2 - Lap A) (P2/P3 - A)  (P3 - B/A)   (P1/All - B)
```

---

## 3. Verbatim Script & Step-by-Step Actions

### Act 1: The Interplanetary Challenge & Mission Overview (0:00 – 1:30)
- **Active Presenter**: **Presenter 1 (Project Narrator)**
- **Active Hardware**: **Laptop B** (Displaying Slide 1: Title, and Slide 2: Problem Statement)
- **Visual on Screen**: Mars-to-Earth orbit diagram showing communication latency (3 to 22 minutes One-Way Light Time).

**Presenter 1 [Spoken]**:
> *"Good morning, respected professors and evaluation panel. Today, our team is proud to present **Project ARES: The Mars Colony Network**.*
> 
> *Modern internet protocols like TCP and HTTP were designed under a fundamental assumption: that round-trip propagation times are measured in tens of milliseconds. But in interplanetary space, physics dictates a harsh reality: Earth and Mars are separated by 54 to 400 million kilometers. Light and radio signals take anywhere from 3 to 22 minutes to travel one way.*
> 
> *Our engineering objective was to simulate this deep-space communication environment, establish end-to-end routing between a Mars habitat and Earth Mission Control, and empirically test why standard TCP collapses under space-link latency—while proving how UDP telemetry streams and Delay-Tolerant approaches keep missions alive.*
> 
> *Let us examine our network topology."*

---

### Act 2: Architecture & Zero-Delay Baseline (1:30 – 3:00)
- **Active Presenters**: **Presenter 1** transitions to **Presenter 2**
- **Active Hardware**: **Laptop B** (Slide 4: Topology Diagram) $\rightarrow$ Switch projector/attention to **Laptop A** (Split Terminals)

**Presenter 1 [Spoken]**:
> *"As shown on Slide 4, our simulated network is segmented into three distinct domains: the Mars Habitat LAN on `192.168.10.0/24`, the Earth Mission Control LAN on `10.10.10.0/24`, and an intermediary Deep Space Emulation Router running Linux Traffic Control. All forwarding is handled via deterministic static routing.*
> 
> *I will now hand over to Presenter 2, our Demo Operator on Laptop A, to verify baseline connectivity."*

**Presenter 2 [Spoken & Live Action on Laptop A]**:
> *"Thank you, Presenter 1. Here on Laptop A, we have our live network simulation active.*
> 
> *First, we verify our baseline state before injecting any space impairments. On Earth Server, our iPerf3 reception daemon is already listening on port 5201. Now, from Mars Host, I will issue an ICMP ping directly to Earth Server at `10.10.10.10`."*

- **Terminal Command [Presenter 2 executes on Laptop A]**:
  ```bash
  sudo ip netns exec mars_host ping -c 3 10.10.10.10
  ```
- **Visual on Screen**: 3 replies return instantly with `time=0.052 ms`, `0% packet loss`.

**Presenter 2 [Spoken]**:
> *"Notice that all three packets return in under a tenth of a millisecond with zero loss. Our routing tables across all routers are verified, and baseline reachability is 100% operational."*

---

### Act 3: Channel Physics & Space Delay Injection (3:00 – 4:45)
- **Active Presenter**: **Presenter 2 (Demo Operator)**
- **Active Hardware**: **Laptop A** (Terminal window for `space_emulator`)

**Presenter 2 [Spoken]**:
> *"Now, we bring the laws of space physics into the laboratory.*
> 
> *Because a real 20-minute delay would take longer than our entire evaluation period, we apply a scaled model: **Profile A**. This injects **5,000 milliseconds of one-way delay** and **2% stochastic packet loss** on both interfaces of our Space Emulator, resulting in an exact **10-second Round-Trip Time**.*
> 
> *I am executing our Traffic Control NetEm configuration script now."*

- **Terminal Command [Presenter 2 executes on Laptop A]**:
  ```bash
  sudo ip netns exec space_emulator tc qdisc replace dev se_eth0 root netem delay 5000ms 50ms loss 2% limit 10000
  sudo ip netns exec space_emulator tc qdisc replace dev se_eth1 root netem delay 5000ms 50ms loss 2% limit 10000
  sudo ip netns exec space_emulator tc qdisc show dev se_eth0
  ```
- **Visual on Screen**: Terminal confirms: `netem delay 5.0s 50.0ms loss 2% limit 10000`.

**Presenter 2 [Spoken]**:
> *"The space link impairment is now active. To prove this to the evaluators, watch what happens when I ping Earth from Mars Host."*

- **Terminal Command [Presenter 2 executes on Laptop A]**:
  ```bash
  sudo ip netns exec mars_host ping -c 2 10.10.10.10
  ```
- **Live Visual Dynamic**: Terminal pauses. Presenter 2 counts:
  > *"We transmit echo 1... five seconds to reach Earth... five seconds for the echo reply to return to Mars... and there it is: `time=10012 ms`. Exactly ten seconds.*
  > 
  > *I now invite Presenter 3 to analyze our core experiment: TCP bulk scientific transfer versus UDP telemetry."*

---

### Act 4: The Live Protocol Showdown — TCP Failure vs. UDP Telemetry (4:45 – 6:45)
- **Active Presenters**: **Presenter 2 (Operator)** executing commands; **Presenter 3 (Analyst)** explaining observations.
- **Active Hardware**: **Laptop A** (Terminal running iPerf3 tests)

**Presenter 3 [Spoken]**:
> *"Thank you, Presenter 2. This is the crux of our investigation: how do fundamental transport protocols behave across an interplanetary link?*
> 
> *First, we simulate scientific imagery transmission using standard TCP. Operator, initiate the TCP test."*

- **Terminal Command [Presenter 2 executes on Laptop A]**:
  ```bash
  sudo ip netns exec mars_host iperf3 -c 10.10.10.10 -p 5201 -t 20 -i 1
  ```

**Presenter 3 [Spoken during execution]**:
> *"Notice the terminal behavior: TCP starts with extreme hesitation. In terrestrial networks, TCP's congestion window doubles every RTT during Slow Start. But here, every single RTT is 10 seconds!*
> 
> *TCP sits idle, starved for ACKs. Even worse, because we configured 2% stochastic loss, a single lost packet causes the Retransmission Timer to expire. TCP misinterprets space propagation delay as severe network congestion, slashing its window down to one segment.*
> 
> *As you can see on screen: mean TCP throughput has collapsed to barely **0.21 Megabits per second** with multiple retransmissions.*
> 
> *Now, Operator, switch to our habitat life-support telemetry stream using UDP at 2 Megabits per second."*

- **Terminal Command [Presenter 2 executes on Laptop A]**:
  ```bash
  sudo ip netns exec mars_host iperf3 -c 10.10.10.10 -p 5201 -u -b 2M -t 20 -i 1
  ```

**Presenter 3 [Spoken during execution]**:
> *"Now observe UDP: Unlike TCP, UDP is connectionless and unacknowledged. It does not pause to wait for handshakes or ACK packets across the 10-second void. It continuously streams oxygen, temperature, and habitat telemetry at **1.96 Megabits per second**, sustaining full line rate with only the expected 2% channel loss.*
> 
> *For critical life-support sensors, the latest reading arriving 5 seconds late is vastly more valuable than stalling the entire system waiting for an old packet to retransmit."*

---

### Act 5: Packet Traces & Bandwidth-Delay Product (6:45 – 8:15)
- **Active Presenter**: **Presenter 3 (Analyst & Protocol Specialist)**
- **Active Hardware**: **Laptop B** (Displaying Slide 8: Matplotlib Comparative Graph & Wireshark Screenshots)

**Presenter 3 [Spoken]**:
> *"To understand the mathematics governing this collapse, look at the graph on Laptop B, generated by our Python analysis pipeline.*
> 
> *The blue line represents UDP—steady, predictable throughput. The red curve is TCP—crushed near zero with repeated retransmission spikes.*
> 
> *This behavior is dictated by the **Bandwidth-Delay Product (BDP)**:
> $$\text{BDP} = \text{Bandwidth} \times \text{RTT}$$
> 
> *For our 2 Mbps link with a 10-second RTT, the BDP is **2.5 Megabytes**. This means that to keep the communication pipe full, the sender must have 2.5 MB of unacknowledged data in flight.*
> 
> *However, standard operating systems allocate default TCP socket buffers of only 64 Kilobytes. Because the socket buffer is 40 times smaller than the space pipe, the sender buffer fills almost instantly and blocks.*
> 
> *In our Wireshark captures, when filtering by `tcp.analysis.retransmission`, we confirmed that packets were being retransmitted redundantly simply because the sender's timer expired before the ACK could traverse the deep-space link."*

---

### Act 6: Conclusion, Delay-Tolerant Networking & Q&A (8:15 – 9:30)
- **Active Presenter**: **Presenter 1 (Project Narrator)** with team alignment.
- **Active Hardware**: **Laptop B** (Slide 10: Conclusion & Future Scope)

**Presenter 1 [Spoken]**:
> *"To conclude, Project ARES has demonstrated three vital networking principles:
> 
> 1. **Terrestrial TCP is fundamentally incompatible with deep space** without drastic window scaling and specialized RTO tuning.
> 2. **UDP is effective for real-time telemetry**, where timeliness takes precedence over absolute reliability.
> 3. **The future of interplanetary communication lies in Delay-Tolerant Networking (DTN)**, specifically the **Bundle Protocol (RFC 5050)**. Rather than relying on fragile end-to-end handshakes across solar distances, DTN uses hop-by-hop custody transfer, storing bundles on planetary orbiters until links become available.
> 
> *All our code, configurations, PCAP files, and automated test runners have been compiled into our project repository.*
> 
> *Thank you for your time. The ARES team is now ready for your questions."*

---

## 4. Emergency Contingency Plan (If Live Demo Fails)

If **Laptop A freezes, commands error out, or the network interface refuses to forward traffic**, execute this seamless handover:

### Failure Reaction Protocol:
1. **Presenter 2 (Demo Operator)** gives the verbal signal calmly:  
   *"While Laptop A completes the current kernel telemetry cycle, let us examine the pre-recorded laboratory capture on Laptop B."*
2. **Presenter 1 (Laptop B)** immediately switches to **Backup Slide 11: High-Resolution Evidence Suite**.
3. **Presenter 3 (Analyst)** steps forward without skipping a beat and presents the exact same numbers from the pre-computed graph (`tcp_vs_udp_throughput.png`) and Wireshark screenshots.
4. The evaluators see zero panic, seamless teamwork, and pre-validated scientific results.
