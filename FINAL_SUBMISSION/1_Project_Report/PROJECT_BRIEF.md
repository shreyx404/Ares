# PROJECT_BRIEF.md — Project ARES

## Project Title

Project ARES: The Mars Colony Network

## One-Line Summary

Project ARES simulates a Mars colony network connected to Earth Mission Control through a high-latency space link, then tests how TCP and UDP behave under extreme delay and packet loss.

## Problem Statement

Standard internet protocols are designed for relatively low-latency Earth networks. TCP assumes acknowledgments will return quickly. In deep-space communication, delay can be extremely high, causing TCP performance to collapse.

This project investigates the following question:

> How do common network protocols behave when the communication link has extreme latency and packet loss, and which transport approach is more suitable for Mars-like communication?

## Project Objectives

1. Design a simple Mars colony network.
2. Design an Earth Mission Control network.
3. Connect Mars and Earth through a simulated space link.
4. Inject artificial delay and packet loss into the space link.
5. Test ICMP, TCP, and UDP behavior.
6. Capture and analyze packet traces.
7. Compare TCP and UDP performance.
8. Explain the results using networking theory.
9. Recommend suitable communication methods for high-latency space networks.

## Core Concepts Demonstrated

- Network topology design.
- IP addressing and subnetting.
- Static routing.
- Latency.
- Packet loss.
- TCP three-way handshake.
- TCP acknowledgments and retransmissions.
- TCP congestion control.
- UDP connectionless communication.
- Bandwidth-delay product.
- Delay-tolerant networking.
- Packet analysis with Wireshark.

## Expected Conclusion

The project is expected to show that:

1. TCP becomes slow and inefficient over high-latency links.
2. TCP retransmissions and delayed acknowledgments reduce throughput.
3. UDP can continue sending data despite delay.
4. UDP may be more suitable for telemetry or sensor data where occasional loss is acceptable.
5. Space communication may require delay-tolerant networking techniques.

## Team Structure

### Member 1 — Network Architect

Responsibilities:

- Build the Mars and Earth networks.
- Configure IP addresses.
- Configure routing.
- Verify basic connectivity.
- Prepare topology diagrams.

### Member 2 — Space Link Engineer

Responsibilities:

- Configure the space-link emulator.
- Add delay using `tc netem` or GNS3 link settings.
- Add packet loss.
- Verify delay using ping.
- Create delay profiles for testing.

### Member 3 — Analyst and Tester

Responsibilities:

- Run iPerf3 tests.
- Capture Wireshark/tcpdump traces.
- Compare TCP and UDP results.
- Create tables and graphs.
- Write the analysis section.

## Final Deliverables

1. Working simulation topology.
2. IP addressing table.
3. Router or host configuration commands.
4. Space-link delay configuration script.
5. iPerf3 test commands.
6. Wireshark/tcpdump captures.
7. Result comparison table.
8. Final project report.
9. Short presentation or demo script.