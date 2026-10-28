# TEST_MATRIX.md — Project ARES Experiments

## Test Environment Variables

Use these variables in commands:

    EARTH_SERVER_IP=10.10.10.10
    MARS_HOST_IP=192.168.10.10
    SPACE_EMULATOR_MARS_IF=eth0
    SPACE_EMULATOR_EARTH_IF=eth1

## Test 0 — Baseline Connectivity

Purpose:

Verify normal connectivity before adding delay.

Command on Mars:

    ping -c 10 10.10.10.10

Expected Result:

- Ping succeeds.
- RTT is very low, usually less than 10 ms in a local simulation.

Evidence:

- Screenshot or terminal output.

## Test 1 — Delayed Ping

Purpose:

Verify that the space-link delay is active.

Command on Mars:

    ping -c 10 10.10.10.10

Expected Result:

- Ping succeeds but RTT is much higher.
- With 5000 ms one-way delay, RTT should be around 10000 ms.

Evidence:

- Screenshot or terminal output.

## Test 2 — TCP Throughput Test

Purpose:

Measure TCP behavior under high latency.

Start iPerf3 server on Earth:

    iperf3 -s

Run TCP test from Mars:

    iperf3 -c 10.10.10.10 -t 60 -i 1 --json > tcp_delay_test.json

Expected Result:

- TCP throughput is low or unstable.
- TCP may show retransmissions.
- TCP may increase slowly because acknowledgments are delayed.

Evidence:

- iPerf3 JSON file.
- Terminal output.
- Wireshark capture.

## Test 3 — UDP Throughput Test

Purpose:

Measure UDP behavior under high latency.

Run UDP test from Mars:

    iperf3 -c 10.10.10.10 -u -b 2M -t 60 -i 1 --json > udp_delay_test.json

Expected Result:

- UDP continues sending traffic.
- UDP does not slow down like TCP.
- Some packet loss may be reported.

Evidence:

- iPerf3 JSON file.
- Terminal output.
- Wireshark capture.

## Test 4 — Wireshark Capture

Purpose:

Capture packet-level evidence.

Capture on Mars host or Space Emulator:

    sudo tcpdump -i any -w project_ares_capture.pcap

Then run:

    ping -c 5 10.10.10.10
    iperf3 -c 10.10.10.10 -t 30

Stop capture with Ctrl+C.

Expected Result:

- PCAP file contains ICMP, TCP, or UDP traffic.
- TCP traffic shows delayed acknowledgments or retransmissions.

Evidence:

- PCAP file.
- Wireshark screenshot.

## Test 5 — Packet Loss Effect

Purpose:

Observe how packet loss affects TCP and UDP.

Example netem rule:

    sudo tc qdisc replace dev eth0 root netem delay 5000ms loss 5%
    sudo tc qdisc replace dev eth1 root netem delay 5000ms loss 5%

Then repeat TCP and UDP tests.

Expected Result:

- TCP performance becomes worse.
- TCP retransmissions increase.
- UDP may report lost packets but continues transmission.

Evidence:

- iPerf3 logs.
- Wireshark capture.
- Result table.

## Result Table Format

Create a table like this:

| Test | Delay | Loss | Protocol | Observation | Evidence |
|---|---:|---:|---|---|---|
| Baseline Ping | 0 ms | 0% | ICMP | Fast reply | screenshot |
| Delayed Ping | 5000 ms | 2% | ICMP | RTT around 10 seconds | screenshot |
| TCP Test | 5000 ms | 2% | TCP | Low throughput, retransmissions | iperf3 log, pcap |
| UDP Test | 5000 ms | 2% | UDP | Stream continues, possible loss | iperf3 log, pcap |
| TCP Loss Test | 5000 ms | 5% | TCP | Worse throughput | iperf3 log, pcap |
| UDP Loss Test | 5000 ms | 5% | UDP | Continues with loss | iperf3 log, pcap |

## Analysis Requirement

The AI agent should generate a Python script that:

1. Reads iPerf3 JSON files.
2. Extracts interval throughput.
3. Converts results to CSV.
4. Plots TCP vs UDP throughput over time.
5. Saves the graph as `tcp_vs_udp_throughput.png`.