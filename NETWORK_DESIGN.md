# NETWORK_DESIGN.md — Project ARES Topology

## High-Level Topology

The network has three main sections:

1. Mars Colony LAN.
2. Space Link Emulator.
3. Earth Mission Control LAN.

Simplified topology:

    Mars Host
        |
    Mars Router
        |
    Space Link Emulator
        |
    Earth Router
        |
    Earth Server

For a simpler fallback topology, use only three Linux machines:

    Mars Host <-> Space Emulator <-> Earth Host

## Recommended IP Addressing Plan

| Segment | Network | Device | IP Address |
|---|---:|---|---:|
| Mars LAN | 192.168.10.0/24 | Mars Host | 192.168.10.10 |
| Mars LAN Gateway | 192.168.10.0/24 | Mars Router LAN interface | 192.168.10.1 |
| Mars-Space Link | 172.16.1.0/30 | Mars Router space interface | 172.16.1.1 |
| Mars-Space Link | 172.16.1.0/30 | Space Emulator Mars-side interface | 172.16.1.2 |
| Space-Earth Link | 172.16.2.0/30 | Space Emulator Earth-side interface | 172.16.2.1 |
| Space-Earth Link | 172.16.2.0/30 | Earth Router space interface | 172.16.2.2 |
| Earth LAN | 10.10.10.0/24 | Earth Router LAN interface | 10.10.10.1 |
| Earth LAN | 10.10.10.0/24 | Earth Server | 10.10.10.10 |

## Routing Plan

Use static routing only.

### Mars Router

Mars Router should have:

- Directly connected Mars LAN: 192.168.10.0/24
- Directly connected Mars-Space link: 172.16.1.0/30
- Default route toward Space Emulator: 172.16.1.2

Conceptual route:

    ip route 0.0.0.0 0.0.0.0 172.16.1.2

### Space Emulator

Space Emulator should have:

- Directly connected Mars-side link: 172.16.1.0/30
- Directly connected Earth-side link: 172.16.2.0/30
- Route to Mars LAN via Mars Router.
- Route to Earth LAN via Earth Router.

Conceptual routes:

    ip route add 192.168.10.0/24 via 172.16.1.1
    ip route add 10.10.10.0/24 via 172.16.2.2

### Earth Router

Earth Router should have:

- Directly connected Earth LAN: 10.10.10.0/24
- Directly connected Space-Earth link: 172.16.2.0/30
- Default route toward Space Emulator: 172.16.2.1

Conceptual route:

    ip route 0.0.0.0 0.0.0.0 172.16.2.1

## Space Link Delay Design

Use scaled delay values for demonstration.

### Profile A — Safe Demo Profile

Recommended for live presentation:

- One-way delay: 5000 ms.
- Round-trip time: approximately 10000 ms.
- Packet loss: 2%.
- Jitter: optional, 100 ms.

### Profile B — Stronger Mars Effect

Use if demo time allows:

- One-way delay: 15000 ms.
- Round-trip time: approximately 30000 ms.
- Packet loss: 5%.
- Jitter: optional, 500 ms.

### Profile C — Extreme Analysis Profile

Use only for report analysis, not live demo:

- One-way delay: 60000 ms or more.
- Packet loss: 5% to 10%.

## Linux netem Command Pattern

Apply delay on the Space Emulator interfaces.

Example for Profile A:

    sudo tc qdisc add dev eth0 root netem delay 5000ms loss 2%
    sudo tc qdisc add dev eth1 root netem delay 5000ms loss 2%

To remove delay:

    sudo tc qdisc del dev eth0 root
    sudo tc qdisc del dev eth1 root

To replace an existing rule:

    sudo tc qdisc replace dev eth0 root netem delay 5000ms loss 2%
    sudo tc qdisc replace dev eth1 root netem delay 5000ms loss 2%

## Important Note

If the Space Emulator is a Linux VM, ensure IP forwarding is enabled:

    sudo sysctl -w net.ipv4.ip_forward=1

To make it persistent:

    echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p