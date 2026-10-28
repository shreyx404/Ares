# IP Addressing Table — Project ARES: The Mars Colony Network

This document defines the complete IP addressing schema, subnet boundaries, gateway assignments, and interface specifications for Project ARES.

---

## 1. Primary 5-Node Architecture IP Addressing Plan

### 1.1 Complete Device Interface Table

| Device Name | Interface Identifier (Linux / Cisco) | IPv4 Address | Subnet Mask (Dotted Decimal) | CIDR Prefix | Default Gateway | Network Purpose |
|---|---|---|---|---|---|---|
| **Mars Host** | `eth0` / `e0` | `192.168.10.10` | `255.255.255.0` | `/24` | `192.168.10.1` | Mars habitat scientific workstation |
| **Mars Router** | `eth0` / `FastEthernet0/0` | `192.168.10.1` | `255.255.255.0` | `/24` | *None (Local GW)* | Mars LAN default gateway |
| **Mars Router** | `eth1` / `FastEthernet0/1` | `172.16.1.1` | `255.255.255.252` | `/30` | *None* | Mars-side uplink to Space Emulator |
| **Space Emulator** | `eth0` | `172.16.1.2` | `255.255.255.252` | `/30` | *None* | Deep Space Link Mars-facing interface |
| **Space Emulator** | `eth1` | `172.16.2.1` | `255.255.255.252` | `/30` | *None* | Deep Space Link Earth-facing interface |
| **Earth Router** | `eth0` / `FastEthernet0/1` | `172.16.2.2` | `255.255.255.252` | `/30` | *None* | Earth-side downlink from Space Emulator |
| **Earth Router** | `eth1` / `FastEthernet0/0` | `10.10.10.1` | `255.255.255.0` | `/24` | *None (Local GW)* | Earth LAN default gateway |
| **Earth Server** | `eth0` / `e0` | `10.10.10.10` | `255.255.255.0` | `/24` | `10.10.10.1` | Earth Mission Control telemetry server |

---

## 2. Subnet Breakdown & Boundary Details

| Subnet Identifier | Network Address | Prefix | Dotted Decimal Netmask | Usable Host Range | Broadcast Address | Total Usable Hosts | Role Description |
|---|---|---|---|---|---|---|---|
| **Mars LAN** | `192.168.10.0` | `/24` | `255.255.255.0` | `192.168.10.1` – `192.168.10.254` | `192.168.10.255` | 254 | Habitat sensor cluster and workstation LAN |
| **Mars-Space P2P** | `172.16.1.0` | `/30` | `255.255.255.252` | `172.16.1.1` – `172.16.1.2` | `172.16.1.3` | 2 | Point-to-point link between Mars Router & Space Link |
| **Space-Earth P2P** | `172.16.2.0` | `/30` | `255.255.255.252` | `172.16.2.1` – `172.16.2.2` | `172.16.2.3` | 2 | Point-to-point link between Space Link & Earth Router |
| **Earth LAN** | `10.10.10.0` | `/24` | `255.255.255.0` | `10.10.10.1` – `10.10.10.254` | `10.10.10.255` | 254 | Mission Control storage and monitoring LAN |

---

## 3. Fallback 3-Node Architecture IP Addressing Plan

When operating in the consolidated 3-node topology (Mars Host $\leftrightarrow$ Space Emulator $\leftrightarrow$ Earth Server):

| Device | Interface | IP Address | Netmask | CIDR | Gateway | Purpose |
|---|---|---|---|---|---|---|
| **Mars Host** | `eth0` | `192.168.10.10` | `255.255.255.0` | `/24` | `192.168.10.1` | Scientific endpoint |
| **Space Emulator** | `eth0` | `192.168.10.1` | `255.255.255.0` | `/24` | *None* | Mars habitat gateway & netem emulator |
| **Space Emulator** | `eth1` | `10.10.10.1` | `255.255.255.0` | `/24` | *None* | Earth Mission Control gateway & netem emulator |
| **Earth Server** | `eth0` | `10.10.10.10` | `255.255.255.0` | `/24` | `10.10.10.1` | Mission Control server |

---

## 4. Static Routing Forwarding Table

### 4.1 Mars Router Routing Table
| Destination Network | Subnet Mask | Next-Hop IP | Outgoing Interface | Route Type |
|---|---|---|---|---|
| `192.168.10.0` | `255.255.255.0` | Directly Connected | `eth0` / `Fa0/0` | Connected |
| `172.16.1.0` | `255.255.255.252` | Directly Connected | `eth1` / `Fa0/1` | Connected |
| `0.0.0.0` (Default) | `0.0.0.0` | `172.16.1.2` | `eth1` / `Fa0/1` | Static Default |

### 4.2 Space Emulator Routing Table
| Destination Network | Subnet Mask | Next-Hop IP | Outgoing Interface | Route Type |
|---|---|---|---|---|
| `172.16.1.0` | `255.255.255.252` | Directly Connected | `eth0` | Connected |
| `172.16.2.0` | `255.255.255.252` | Directly Connected | `eth1` | Connected |
| `192.168.10.0` | `255.255.255.0` | `172.16.1.1` | `eth0` | Static |
| `10.10.10.0` | `255.255.255.0` | `172.16.2.2` | `eth1` | Static |

### 4.3 Earth Router Routing Table
| Destination Network | Subnet Mask | Next-Hop IP | Outgoing Interface | Route Type |
|---|---|---|---|---|
| `10.10.10.0` | `255.255.255.0` | Directly Connected | `eth1` / `Fa0/0` | Connected |
| `172.16.2.0` | `255.255.255.252` | Directly Connected | `eth0` / `Fa0/1` | Connected |
| `0.0.0.0` (Default) | `0.0.0.0` | `172.16.2.1` | `eth0` / `Fa0/1` | Static Default |

---

## 5. Verification Matrix (Baseline Reachability)

| Source Device | Target Device | Target IP Address | Command | Expected Output |
|---|---|---|---|---|
| Mars Host | Mars Router | `192.168.10.1` | `ping -c 3 192.168.10.1` | 0% packet loss, RTT $< 2\text{ ms}$ |
| Mars Host | Space Emulator | `172.16.1.2` | `ping -c 3 172.16.1.2` | 0% packet loss, RTT $< 5\text{ ms}$ |
| Mars Host | Earth Router | `172.16.2.2` | `ping -c 3 172.16.2.2` | 0% packet loss, RTT $< 8\text{ ms}$ |
| **Mars Host** | **Earth Server** | **`10.10.10.10`** | **`ping -c 5 10.10.10.10`** | **0% packet loss, RTT $< 10\text{ ms}$ (End-to-End Baseline)** |
