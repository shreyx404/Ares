# SLIDES_CONTENT.md — Complete Presentation Deck Content
**Project ARES: The Mars Colony Network**  
*Interplanetary Transport Protocol Benchmarking under Scaled Delay and Stochastic Loss*  
*Target Deck: 10 Slides | Presentation Time: 8 to 9 Minutes | Equipment: 2 Laptops*

---

## Slide 1: Title Slide

### Visual Cue & Staging
- **Display**: **Laptop B** (Full-screen presentation on projector).
- **Visual Asset**: High-contrast rendering of Earth-to-Mars orbital trajectory with the Project ARES mission patch.
- **Presenter at Mic**: **Presenter 1 (Project Narrator)**.

### Slide Content (Bullets)
* **Project ARES**: Autonomous Relay for Extraterrestrial Systems
* **Core Investigation**: Performance of Terrestrial Protocols over Deep-Space Delays
* **Experimental Platform**: 5-Node Routed Interplanetary Emulation Network
* **Core Comparison**: TCP Bulk Scientific Data vs. UDP Mission-Critical Telemetry
* **Course & Team**: Data Communication & Networking (DCN) — Presenters 1, 2, & 3

### Speaker Notes (Presenter 1)
> *"Good morning, respected professors and evaluation committee. Today, our team presents **Project ARES: The Mars Colony Network**.*
> 
> *Modern Internet transport protocols were engineered under the assumption that network delay is measured in tens of milliseconds. Across interplanetary distances, however, signal propagation is constrained by the speed of light—taking between 3 and 22 minutes to travel between Earth and Mars.*
> 
> *In this project, we designed and simulated an end-to-end interplanetary network to investigate how standard transport protocols behave under extreme space latency, and why Delay-Tolerant architectures are vital for interplanetary exploration."*

---

## Slide 2: Problem Statement

### Visual Cue & Staging
- **Display**: **Laptop B**.
- **Visual Asset**: Split comparison graphic: Terrestrial fiber RTT ($< 20\text{ ms}$) vs. Interplanetary radio RTT ($6\text{ to }44\text{ minutes}$).
- **Presenter at Mic**: **Presenter 1 (Project Narrator)**.

### Slide Content (Bullets)
* **Terrestrial Assumptions**: Sub-100ms round trips, low bit-error rates, continuous line-of-sight.
* **Deep-Space Reality**: Distance ranges from 54.6M km to 401M km (RTT: 6 to 44 minutes).
* **TCP Vulnerability**: Reliance on rapid ACK clocking causes severe transmission starvation.
* **Loss Misinterpretation**: Stochastic channel noise triggers aggressive congestion window collapse.
* **Core Research Question**: Which transport architecture reliably sustains Mars habitat operations?

### Speaker Notes (Presenter 1)
> *"Terrestrial networking takes rapid feedback for granted. In low-latency networks, TCP utilizes returning ACKs to continuously clock new data packets into the network.*
> 
> *In deep space, however, astronomical distances introduce massive latency. When an acknowledgment takes minutes to return, TCP's transmission clock halts. Worse, standard TCP misinterprets random radiation-induced bit loss as severe router buffer overflow, slashing its transmission rate by 50% unnecessarily.*
> 
> *Our research investigates: Can standard transport protocols function on Mars, or must mission architectures fundamentally change?"*

---

## Slide 3: Why Mars Communication is Different

### Visual Cue & Staging
- **Display**: **Laptop B**.
- **Visual Asset**: Heliocentric orbital diagram showing Mars and Earth orbits, highlighting Perihelic Opposition ($54.6\text{M km}$) vs. Solar Conjunction ($401\text{M km}$).
- **Presenter at Mic**: **Presenter 1 (Project Narrator)**.

### Slide Content (Bullets)
* **Dynamic Geometry**: Distance fluctuates by a factor of 7 throughout the synodic cycle.
* **Extreme Propagation Delay**: One-Way Light Time (OWLT) spans **3.03 to 22.2 minutes**.
* **Solar Conjunction Blackouts**: Sun blocks line-of-sight for ~2 weeks every 26 months.
* **Stochastic Channel Noise**: Cosmic radiation and plasma scintillation induce random packet drops.
* **Engineering Mandate**: Protocol must endure high BER and multi-minute latency without failing.

### Speaker Notes (Presenter 1)
> *"Interplanetary links do not have static characteristics. Because Earth and Mars orbit at different velocities, their distance varies by more than 700% over a 26-month cycle.*
> 
> *At closest approach, one-way delay is 3 minutes. At solar conjunction, it exceeds 22 minutes, and the Sun completely severs the radio path for two weeks.*
> 
> *These physical constraints break fundamental internet assumptions: there is no continuous end-to-end path, propagation delays exceed application timeouts, and bit errors are stochastic rather than congestion-driven."*

---

## Slide 4: Project Topology & Architecture

### Visual Cue & Staging
- **Display**: **Laptop B** (Topology Architecture) $\rightarrow$ Cue **Laptop A** (Terminal staging).
- **Visual Asset**: Segmented 5-Node Architecture diagram showing Mars LAN, Space Link Emulator, and Earth LAN.
- **Presenter Transition**: **Presenter 1** introduces architecture; hands over to **Presenter 2 (Demo Operator)**.

### Slide Content (Bullets)
* **Mars Habitat LAN (`192.168.10.0/24`)**: Workstations and life-support telemetry sensors.
* **Mars Edge Router (`172.16.1.1/30`)**: Local gateway routing planetary outbound traffic.
* **Deep Space Link Emulator (`NetEm`)**: Intermediate router injecting calibrated latency & loss.
* **Earth Edge Router (`172.16.2.2/30`)**: Downlink gateway to terrestrial ground station.
* **Earth Mission Control LAN (`10.10.10.0/24`)**: Telemetry ingest servers and data archives.

### Speaker Notes (Presenter 1 $\rightarrow$ Presenter 2)
> **Presenter 1**: *"To evaluate this scenario, we designed an end-to-end 5-node architecture segmented into three operational domains: the Mars Habitat LAN, an emulated Interplanetary Space Link, and Earth Mission Control. I now hand over to Presenter 2 on Laptop A to demonstrate baseline connectivity."*
> 
> **Presenter 2**: *"Thank you. On Laptop A, our 5-node network simulation is live. Before injecting space delays, I will run a baseline ICMP ping from Mars Host to Earth Server at `10.10.10.10`."*
> *(Presenter 2 executes `ping -c 3 10.10.10.10`)*
> *"All three packets return in 0.05 milliseconds with 0% loss, confirming our baseline routing is 100% operational."*

---

## Slide 5: IP Addressing & Deterministic Routing

### Visual Cue & Staging
- **Display**: **Laptop B** (Addressing Table & Packet Flow).
- **Visual Asset**: High-contrast IP addressing matrix showing CIDR blocks, interface IDs, and static routing paths.
- **Presenter at Mic**: **Presenter 2 (Demo Operator)**.

### Slide Content (Bullets)
* **Habitat Subnets**: Clean `/24` Class C networks for Mars Habitat and Earth Mission Control.
* **Space WAN Links**: Dedicated `/30` point-to-point subnets (`172.16.1.0/30` and `172.16.2.0/30`).
* **Deterministic Static Routing**: Eliminates dynamic hello/keepalive timeout failures over delay.
* **Kernel IP Forwarding**: Intermediate nodes forward packets at line rate via Linux IPv4 stack.
* **Isolated Namespaces**: High-performance execution with zero hypervisor virtualization overhead.

### Speaker Notes (Presenter 2)
> *"Addressing is structured into two endpoint LANs on `/24` subnets, interconnected by two point-to-point WAN links on `/30` subnets.*
> 
> *Notice that we deliberately avoided dynamic routing protocols such as OSPF or RIP. Over multi-minute space delays, dynamic routing protocols fail because their hello packets and neighbor keepalives time out, tearing down valid routes.*
> 
> *By implementing deterministic static routing, we guarantee loop-free, predictable packet forwarding across the interplanetary boundary."*

---

## Slide 6: Space-Link Delay Emulation (Linux NetEm)

### Visual Cue & Staging
- **Display**: **Laptop A** (Terminal execution of `space_link_netem.sh`) + **Laptop B** (NetEm Queue Parameter Slide).
- **Visual Asset**: Terminal screenshot displaying `tc qdisc add ... netem delay 5000ms loss 2% limit 10000`.
- **Presenter at Mic**: **Presenter 2 (Demo Operator)**.

### Slide Content (Bullets)
* **Scaled Emulation Rationale**: True 20-minute RTT prevents live demo; 10s RTT preserves identical dynamics.
* **Profile A (Standard Demo)**: 5,000 ms one-way delay $\rightarrow$ **10,000 ms RTT**, **2% loss**, 50 ms jitter.
* **Profile B (Strong Mars Effect)**: 15,000 ms one-way delay $\rightarrow$ **30,000 ms RTT**, **5% loss**, 200 ms jitter.
* **Linux Traffic Control (`tc`)**: Kernel queuing discipline injecting delay bidirectionally.
* **Queue Sizing (`limit 10000`)**: Prevents unintended tail-drop buffer drops at multi-second delays.

### Speaker Notes (Presenter 2)
> *"To bring space physics into the lab, we use Linux Traffic Control NetEm. A full 20-minute delay would make an 8-minute presentation impossible, so we use a scientifically calibrated scaled model: Profile A.*
> 
> *Profile A injects 5,000 milliseconds of one-way delay and 2% packet loss on both emulator interfaces, yielding an exact 10-second Round-Trip Time.*
> 
> *I am executing the NetEm injection script now on Laptop A. Watch what happens when I ping Earth from Mars Host:*
> *(Presenter 2 executes `ping -c 2 10.10.10.10`)*
> *One... two... five seconds outbound... five seconds return... and echo returns at exactly 10,012 milliseconds. Our space link is active."*

---

## Slide 7: TCP Test Results — Window Collapse

### Visual Cue & Staging
- **Display**: **Laptop A** (Terminal running TCP iPerf3) $\rightarrow$ **Laptop B** (Throughput Table).
- **Visual Asset**: Terminal output of iPerf3 TCP stream showing stalled intervals and retransmission counts.
- **Presenter at Mic**: **Presenter 3 (Analyst & Protocol Specialist)**.

### Slide Content (Bullets)
* **Workload**: Bulk scientific data transfer from Mars Habitat to Earth Mission Control.
* **Throughput Collapse**: Drops from gigabit LAN rates to **0.216 Mbps** (>90% loss).
* **Slow Start Starvation**: Congestion window doubles only once every 10 seconds.
* **RTO Timer Expiry**: Sender timer expires before delayed ACKs return, triggering retransmits.
* **Multiplicative Drop**: Single 2% packet loss resets congestion window to 1 Maximum Segment Size.

### Speaker Notes (Presenter 3)
> *"Thank you, Presenter 2. Here lies the core finding of our research. When we attempt to transmit bulk scientific data using standard TCP over the 10-second RTT space link, performance collapses completely.*
> 
> *As shown on screen, throughput drops to barely 0.21 Megabits per second. Why? Because TCP's Slow Start mechanism doubles the congestion window once per RTT. With an RTT of 10 seconds, it takes minutes just to ramp up.*
> 
> *Furthermore, when our 2% channel loss drops a single packet, TCP misinterprets this as catastrophic network congestion, slashes its window to 1 segment, and enters exponential timeout backoff."*

---

## Slide 8: UDP Test Results — Telemetry Resilience

### Visual Cue & Staging
- **Display**: **Laptop A** (Terminal running UDP iPerf3) $\rightarrow$ **Laptop B** (CBR Telemetry Chart).
- **Visual Asset**: Terminal output of UDP stream showing steady 1.96 Mbps delivery rate.
- **Presenter at Mic**: **Presenter 3 (Analyst & Protocol Specialist)**.

### Slide Content (Bullets)
* **Workload**: Mission-critical life-support telemetry (oxygen, pressure, habitat power) at 2 Mbps CBR.
* **Line-Rate Sustained**: Achieved **1.962 Mbps** delivery rate (98.1% channel utilization).
* **Connectionless Streaming**: Zero acknowledgment dependencies; stream never stalls for return trips.
* **Loss Absorption**: Absorbs 2.1% stochastic channel loss without interrupting transmission.
* **Timeliness vs. Completeness**: A 5-second-old telemetry reading is vastly more valuable than a halted connection.

### Speaker Notes (Presenter 3)
> *"Now observe what happens when we switch to User Datagram Protocol (UDP) for Mars habitat life-support telemetry at 2 Megabits per second.*
> 
> *Unlike TCP, UDP does not wait for acknowledgments across the 10-second void. It streams environmental data continuously, achieving 1.96 Megabits per second—sustaining 98% line-rate efficiency.*
> 
> *For life-critical habitat telemetry, timeliness is paramount. Mission Control needs the latest oxygen and pressure readings now. Stalling the entire habitat network to wait 20 seconds for an old retransmission could be catastrophic."*

---

## Slide 9: Packet Forensics & BDP Derivation

### Visual Cue & Staging
- **Display**: **Laptop B** (Displaying `images/tcp_vs_udp_throughput.png` and Wireshark trace).
- **Visual Asset**: High-resolution Matplotlib plot comparing TCP vs. UDP curves alongside annotated Wireshark packet capture.
- **Presenter at Mic**: **Presenter 3 (Analyst & Protocol Specialist)**.

### Slide Content (Bullets)
* **Bandwidth-Delay Product**: $\text{BDP} = \text{Bandwidth} \times \text{RTT} = 2\text{ Mbps} \times 10\text{ s} = \mathbf{2.5\text{ Megabytes}}$.
* **Socket Buffer Bottleneck**: Default OS socket buffer is only **64 KB** ($64\text{ KB} \ll 2.5\text{ MB}$).
* **Buffer Starvation**: Sender transmits 64 KB in 250 ms, then blocks idle for 9,750 ms awaiting ACKs.
* **Wireshark Evidence**: Filter `tcp.analysis.retransmission` reveals redundant in-flight retransmits.
* **Empirical Validation**: Theoretical mathematical limit matches our measured 0.216 Mbps throughput.

### Speaker Notes (Presenter 3)
> *"This throughput collapse is governed by the Bandwidth-Delay Product: BDP equals Bandwidth times RTT.*
> 
> *At 2 Mbps with a 10-second round trip, the physical data pipe holds 2.5 Megabytes. To achieve full utilization, the sender must keep 2.5 MB of unacknowledged data in flight.*
> 
> *However, standard operating systems allocate default TCP socket buffers of only 64 Kilobytes—nearly 40 times smaller than the pipe! The sender fills its buffer in 250 milliseconds, and then sits completely frozen for 9.75 seconds awaiting an ACK.*
> 
> *In our Wireshark captures on Laptop B, filtering by `tcp.analysis.retransmission` proves that the sender retransmits packets that were not lost at all, but were simply still in transit across interplanetary space."*

---

## Slide 10: Conclusion & DTN Future Roadmap

### Visual Cue & Staging
- **Display**: **Laptop B** (Summary Matrix & NASA DTN Architecture Diagram).
- **Visual Asset**: NASA Interplanetary Internet architecture diagram showing Mars Reconnaissance Orbiter custody transfer.
- **Presenter at Mic**: **Presenter 1 (Project Narrator)** with all three presenters at the podium.

### Slide Content (Bullets)
* **Empirical Proof**: Terrestrial TCP is fundamentally broken over deep-space latency.
* **UDP Role**: Highly resilient for unacknowledged, loss-tolerant environmental telemetry.
* **The Interplanetary Solution**: **Delay-Tolerant Networking (DTN)** and **Bundle Protocol (RFC 5050)**.
* **Custody Transfer**: Hop-by-hop persistent storage on orbiters replaces fragile end-to-end handshakes.
* **Deliverables**: Complete reproducible simulation code, audited runbooks, PCAPs, and evidence submitted.

### Speaker Notes (Presenter 1)
> *"To conclude, Project ARES has empirically proven three fundamental networking truths:*
> 
> *First: Terrestrial TCP cannot function across interplanetary distances without complete protocol restructuring.*
> *Second: UDP is ideal for time-sensitive sensor streams where current data takes precedence over absolute reliability.*
> *Third: For reliable interplanetary data transfer, space agencies must utilize **Delay-Tolerant Networking (DTN)** and the **Bundle Protocol (RFC 5050)**. By utilizing custody transfer and hop-by-hop storage on Mars orbiters, DTN eliminates solar-distance handshakes entirely.*
> 
> *All our source scripts, automated test harnesses, and evidence packages are submitted in our project archive.*
> 
> *Thank you. The Project ARES team is now ready for your questions."*

---
