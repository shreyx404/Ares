# REPORT_TEMPLATE.md — Final Project Report Structure

Use this structure for the final academic report.

## 1. Title Page

Project Title:

Project ARES: The Mars Colony Network

Include:

- Course name.
- Course code.
- Team members.
- Date.
- Institution.

## 2. Abstract

Write a short paragraph explaining:

- The purpose of the project.
- The Mars-Earth simulation scenario.
- The tools used.
- The main result.
- The conclusion.

Example direction:

> This project simulates a Mars colony network connected to Earth Mission Control through a high-latency space link. The simulation uses GNS3/Linux network emulation to introduce artificial delay and packet loss. TCP and UDP behavior are compared using iPerf3 and Wireshark. The results show that TCP performance degrades significantly under high latency, while UDP is more suitable for certain delay-tolerant telemetry traffic.

## 3. Introduction

Explain:

- Why latency matters in networking.
- Why space communication is different from Earth networking.
- Why standard TCP may fail in high-delay environments.

## 4. Objectives

List the project objectives clearly.

## 5. Network Design

Include:

- Topology diagram.
- Mars network design.
- Earth network design.
- Space-link emulator.
- IP addressing table.
- Routing plan.

## 6. Implementation

Include:

- Tools used.
- Installation steps.
- Device configurations.
- Space-link delay configuration.
- Commands used to enable delay and packet loss.

## 7. Testing Methodology

Explain:

- Baseline test.
- Delayed ping test.
- TCP test.
- UDP test.
- Packet loss test.
- Wireshark capture method.

## 8. Results and Analysis

Include:

- Ping output screenshots.
- iPerf3 results.
- TCP vs UDP comparison table.
- Throughput graph.
- Wireshark evidence.
- Explanation of TCP retransmissions.
- Explanation of delayed acknowledgments.

## 9. Bandwidth-Delay Product Explanation

Explain:

Bandwidth-Delay Product = Bandwidth × Round-Trip Time

Example:

If bandwidth is 2 Mbps and RTT is 10 seconds:

    2,000,000 bits/sec × 10 sec = 20,000,000 bits
    20,000,000 bits = 2.5 MB

This means TCP needs enough window space to keep data in flight. If the TCP window is too small, throughput becomes very low.

## 10. Discussion

Answer:

- Why did TCP perform poorly?
- Why did UDP continue?
- What type of Mars traffic should use TCP?
- What type of Mars traffic should use UDP?
- Why is Delay-Tolerant Networking important?

## 11. Conclusion

Summarize:

- The experiment worked.
- High latency harmed TCP.
- UDP was more tolerant.
- Space networks need special protocol design.

## 12. Future Scope

Possible future improvements:

- Implement DTN store-and-forward.
- Test QUIC.
- Test file transfer protocols.
- Use real DTN software.
- Simulate intermittent connectivity.
- Add multiple Mars habitats.

## 13. References

Include references such as:

- Forouzan, Data Communications and Networking.
- Kurose and Ross, Computer Networking: A Top-Down Approach.
- TCP/IP Illustrated, Stevens.
- Linux tc/netem documentation.
- iPerf3 documentation.
- Wireshark documentation.