# Live Demonstration Script — Project ARES: The Mars Colony Network

**Total Presentation Duration**: 9 Minutes 30 Seconds (strictly under 10 minutes)  
**Presenters**: 
- **Member 1 (Network Architect)**: Architecture, baseline connectivity, and conclusion.
- **Member 2 (Space Link Engineer)**: NetEm delay injection and channel physics.
- **Member 3 (Analyst & Tester)**: iPerf3 throughput testing, Wireshark traces, and BDP theory.

---

## Demo Schedule & Timeline Matrix

```
00:00          02:00          03:30          05:30          07:30          09:00     10:00
  |--------------|--------------|--------------|--------------|--------------|---------|
   Act 1: Intro   Act 2: Base    Act 3: Netem   Act 4: TCP vs  Act 5: Packet  Act 6:
   & Topology     Connectivity   Delay Injection  UDP Stream   Traces & BDP   Conclusion
   (Member 1)     (Member 1)     (Member 2)     (Member 3)     (Member 3)     (All)
```

---

## Act 1: Introduction and Architectural Overview (0:00 – 1:45)
**Speaker**: **Member 1 (Network Architect)**  
**Screen Display**: Topology Diagram (`build/topology.md` or GNS3 Canvas)

- **Spoken Script**:
  > *"Good morning professors and evaluators. Today we present Project ARES: The Mars Colony Network. Standard Internet protocols were conceived for terrestrial networks where propagation delay is measured in milliseconds. But between Earth and Mars, signal propagation takes up to 22 minutes one-way.*
  > 
  > *In this project, we simulated an end-to-end interplanetary architecture comprising three domains: the Mars Habitat LAN on `192.168.10.0/24`, the Earth Mission Control LAN on `10.10.10.0/24`, and an emulated Deep Space Link running Linux Traffic Control. Our objective is to prove empirically why standard TCP collapses over deep-space links, and why UDP telemetry or Delay-Tolerant Networking is mandatory for interplanetary missions."*

- **Visual Action**: Point out the three segments on the topology diagram, showing static routes directing traffic through the Space Emulator.

---

## Act 2: Baseline Terrestrial Connectivity (1:45 – 3:00)
**Speaker**: **Member 1 (Network Architect)**  
**Screen Display**: Split terminal: `[Mars Host]` on left, `[Earth Server]` on right.

- **Action on `[Earth Server]`**: Verify iPerf3 server is listening.
  ```bash
  # [Earth Server]
  ./iperf_test_server.sh status
  ```
  *(Shows: `[UP] iPerf3 server is active on port 5201`)*

- **Action on `[Mars Host]`**: Run baseline ICMP ping before adding delay.
  ```bash
  # [Mars Host]
  ping -c 3 10.10.10.10
  ```

- **Spoken Script**:
  > *"First, we verify baseline connectivity without space link impairments. Notice the ping responses return immediately with a round-trip time under 5 milliseconds. All static routes across the Mars and Earth routers are functioning with zero packet loss."*

---

## Act 3: Injecting Interplanetary Delay & Loss (3:00 – 4:30)
**Speaker**: **Member 2 (Space Link Engineer)**  
**Screen Display**: Terminal for `[Space Emulator]` and `[Mars Host]`

- **Spoken Script**:
  > *"Now we emulate the interplanetary vacuum. Real Earth-Mars one-way light time is between 3 and 22 minutes. For our 10-minute demonstration, we use our calibrated scaled model: Profile A, which injects 5,000 milliseconds of one-way delay and 2% stochastic packet loss, producing an exact 10-second round-trip time."*

- **Action on `[Space Emulator]`**: Execute NetEm injection.
  ```bash
  # [Space Emulator]
  sudo ./space_link_netem.sh profile_a
  ```
  *(Screen shows: `tc qdisc add dev eth0 root netem delay 5000ms 50ms loss 2% limit 10000`)*

- **Action on `[Mars Host]`**: Demonstrate the delayed echo.
  ```bash
  # [Mars Host]
  ping -c 2 10.10.10.10
  ```

- **Spoken Script (as ping runs)**:
  > *"Notice the terminal pauses. We send the ICMP echo request... it traverses the space link for 5 seconds, reaches Earth, and the reply takes 5 seconds to return. Exactly 10,012 milliseconds RTT. Our simulated space link is fully live."*

---

## Act 4: The Core Experiment — TCP Failure vs UDP Telemetry (4:30 – 7:00)
**Speaker**: **Member 3 (Analyst & Tester)**  
**Screen Display**: Terminal for `[Mars Host]` (running `iperf_test_client.sh`)

- **Spoken Script**:
  > *"Now we run our core scientific experiment. We will transmit two types of traffic: first, bulk scientific data using standard TCP; second, mission-critical habitat life-support telemetry using UDP at 2 Megabits per second."*

- **Action on `[Mars Host]`**: Launch Fast Demo Suite.
  ```bash
  # [Mars Host]
  ./iperf_test_client.sh demo
  ```

- **Live Observation (TCP Stream)**:
  - Terminal prints dots as TCP attempts transmission.
  - Spoken commentary:
    > *"Observe the TCP stream: Because every TCP packet requires an ACK that takes 10 seconds to return, TCP's congestion window is severely throttled. The mean throughput plummets to barely 0.2 Megabits per second, and retransmissions spike because the Retransmission Timer expires before ACKs arrive."*

- **Live Observation (UDP Telemetry Stream)**:
  - Terminal prints UDP stream results.
  - Spoken commentary:
    > *"Now look at the UDP stream. UDP does not wait for round-trip acknowledgments. It streams habitat oxygen and pressure telemetry at 1.96 Megabits per second, maintaining full line rate with only ~2% stochastic loss. The life-support telemetry gets through continuously without stalling."*

---

## Act 5: Packet Traces & Bandwidth-Delay Product (7:00 – 8:45)
**Speaker**: **Member 3 (Analyst & Tester)**  
**Screen Display**: Python Generated Plot (`tcp_vs_udp_throughput.png`) and Wireshark Capture

- **Spoken Script**:
  > *"Here is the graphical proof generated by our Python analysis pipeline. The blue line represents UDP, maintaining constant throughput. The red line is TCP, suffering severe throughput collapse.*
  > 
  > *This phenomenon is governed by the Bandwidth-Delay Product: $\text{BDP} = \text{Bandwidth} \times \text{RTT}$. At 2 Mbps with a 10-second RTT, the BDP is 2.5 Megabytes. Standard operating systems allocate default TCP socket buffers of only 64 Kilobytes. Because the socket buffer is orders of magnitude smaller than the in-flight data pipe, the sender buffer fills and blocks, starving transmission.*
  > 
  > *In our Wireshark traces, filtered by `tcp.analysis.retransmission`, you can see multiple spurious retransmissions because the sender assumes packets were lost when they were merely in flight."*

---

## Act 6: Conclusion and Recommendations (8:45 – 9:45)
**Speaker**: **Member 1 (Network Architect)**  
**Screen Display**: Summary slide / `REPORT_TEMPLATE.md` Overview

- **Spoken Script**:
  > *"In conclusion, Project ARES successfully proves that:
  > 1. Terrestrial TCP cannot function over interplanetary distances without specialized modifications.
  > 2. UDP is resilient for continuous, loss-tolerant telemetry streams.
  > 3. For reliable data, deep-space exploration requires Delay-Tolerant Networking (DTN) and the Bundle Protocol (RFC 5050), using custody transfer and hop-by-hop storage instead of end-to-end handshakes.
  > 
  > Thank you. We are now open for questions."*

---

## Contingency Backup Plan (If Live Hardware Fails)

| Failure Scenario | Immediate Fallback Action | Responsible Member |
|---|---|---|
| **VM network bridge disconnects** | Switch to the 1-script Linux Network Namespace demo on the laptop: `sudo ./setup_namespaces.sh`. | Member 1 |
| **Space Emulator kernel module error** | Switch NetEm interface: verify `ip link show` to ensure interface name matches `eth0`/`ens3`. | Member 2 |
| **iPerf3 test takes longer than expected** | Cancel with `Ctrl+C` and immediately run `python3 analyze_iperf.py`, which loads the pre-cached results from `results/parsed_iperf_summary.csv`. | Member 3 |
| **Evaluator asks to see delay removed** | Run `sudo ./remove_netem.sh` on `[Space Emulator]` and show `ping` returning instantly to $< 5\text{ ms}$. | Member 2 |
