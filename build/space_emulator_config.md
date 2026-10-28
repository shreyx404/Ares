# Space Emulator Configuration — Project ARES

The **Space Emulator** represents the physical and electromagnetic channel between Earth and Mars. It acts as an intermediate router while hosting Linux Traffic Control (`tc netem`) queuing disciplines to inject propagation delay, jitter, and stochastic packet loss.

---

## 1. Operating Prerequisites

**Target Device**: `[Space Emulator]` (Ubuntu 22.04 / 24.04 or Debian 12)  
**Hardware Interfaces**:
- `eth0`: Mars-facing link (`172.16.1.2/30`)
- `eth1`: Earth-facing link (`172.16.2.1/30`)

**Required Packages**:
```bash
# [Space Emulator] Install iproute2, net-tools, and iptables
sudo apt update && sudo apt install -y iproute2 net-tools iptables ethtool iperf3
```

---

## 2. Immediate Configuration Commands

Run the following commands directly in the shell of `[Space Emulator]`:

```bash
# [Space Emulator] 1. Enable IPv4 Kernel Forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-project-ares.conf
sudo sysctl -p /etc/sysctl.d/99-project-ares.conf

# [Space Emulator] 2. Assign IP Addresses to Mars and Earth interfaces
sudo ip addr flush dev eth0
sudo ip addr flush dev eth1

sudo ip addr add 172.16.1.2/30 dev eth0
sudo ip addr add 172.16.2.1/30 dev eth1

# [Space Emulator] 3. Bring interfaces UP
sudo ip link set dev eth0 up
sudo ip link set dev eth1 up

# [Space Emulator] 4. Add Static Routes to Mars LAN and Earth LAN
sudo ip route add 192.168.10.0/24 via 172.16.1.1 dev eth0
sudo ip route add 10.10.10.0/24 via 172.16.2.2 dev eth1

# [Space Emulator] 5. Configure IPTables to permit transit forwarding
sudo iptables -F FORWARD
sudo iptables -A FORWARD -j ACCEPT

# [Space Emulator] 6. Disable TCP segmentation offload (TSO/GSO) to guarantee precise tc netem queue modeling
sudo ethtool -K eth0 tso off gso off gro off || true
sudo ethtool -K eth1 tso off gso off gro off || true
```

---

## 3. Persistent Configuration via Netplan

To ensure settings persist across reboots, save this configuration:

File: `/etc/netplan/01-space-emulator.yaml`
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        - 172.16.1.2/30
      routes:
        - to: 192.168.10.0/24
          via: 172.16.1.1
    eth1:
      addresses:
        - 172.16.2.1/30
      routes:
        - to: 10.10.10.0/24
          via: 172.16.2.2
```

Apply the netplan:
```bash
# [Space Emulator]
sudo netplan apply
```

---

## 4. Verification and Reachability Testing

Execute the following commands on `[Space Emulator]`:

```bash
# [Space Emulator] 1. Check interface status
ip -br addr show

# [Space Emulator] 2. Verify complete routing table
ip route show

# [Space Emulator] 3. Ping Mars Router
ping -c 3 172.16.1.1

# [Space Emulator] 4. Ping Earth Router
ping -c 3 172.16.2.2

# [Space Emulator] 5. Ping Mars Host (verifies routing through Mars Router)
ping -c 3 192.168.10.10

# [Space Emulator] 6. Ping Earth Server (verifies routing through Earth Router)
ping -c 3 10.10.10.10
```

---

## 5. Expected Success Criteria

1. **IP Forwarding**: Output of `cat /proc/sys/net/ipv4/ip_forward` returns `1`.
2. **Interface Addressing**:
   - `eth0` has `172.16.1.2/30`
   - `eth1` has `172.16.2.1/30`
3. **Routing Table**:
   - `192.168.10.0/24 via 172.16.1.1 dev eth0`
   - `10.10.10.0/24 via 172.16.2.2 dev eth1`
4. **End-to-End Baseline Reachability**:
   - Space Emulator can reach both `192.168.10.10` (Mars Host) and `10.10.10.10` (Earth Server) with `0% packet loss` and RTT $< 5\text{ ms}$ (prior to netem activation).
