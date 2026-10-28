# Mars Router Configuration — Project ARES

This guide provides complete, copy-paste-ready configuration commands for the **Mars Router** and **Mars Host**. Both Cisco IOS (GNS3) and Pure Linux (Ubuntu/Debian) implementations are provided.

---

## 1. Cisco IOS Configuration (GNS3 / Cisco 7200 / 3725)

**Target Device**: `[Mars Router]`  
**Console Access**: Connect via GNS3 serial console or Telnet.

```cisco
! Enter Privileged EXEC and Global Configuration Mode
enable
configure terminal

! Set Hostname
hostname Mars-Router

! Configure Mars LAN Interface (Facing Mars Colony Host)
interface FastEthernet0/0
 description Mars Habitat Internal LAN
 ip address 192.168.10.1 255.255.255.0
 no shutdown
 exit

! Configure Space Link Interface (Facing Space Emulator)
interface FastEthernet0/1
 description Interplanetary Link Uplink to Space Emulator
 ip address 172.16.1.1 255.255.255.252
 no shutdown
 exit

! Configure Static Default Route toward Space Emulator
ip route 0.0.0.0 0.0.0.0 172.16.1.2

! Save Running Configuration to NVRAM
end
write memory
```

### Verification on Cisco IOS `[Mars Router]`
```cisco
show ip interface brief
show ip route
ping 172.16.1.2
```

**Expected Success Criteria**:
- `FastEthernet0/0` status: `up`, protocol: `up`, IP `192.168.10.1`.
- `FastEthernet0/1` status: `up`, protocol: `up`, IP `172.16.1.1`.
- Route `S* 0.0.0.0/0 [1/0] via 172.16.1.2` appears in routing table.
- Ping to `172.16.1.2` returns `Success rate is 100 percent (5/5)`.

---

## 2. Pure Linux Fallback Configuration (Ubuntu / Debian VM)

If Cisco IOS images are not available, use a dual-homed Ubuntu 22.04/24.04 VM as the Mars Router.

**Target Device**: `[Mars Router]`  
Assume interfaces:
- `eth0` = Connected to Mars LAN (`192.168.10.0/24`)
- `eth1` = Connected to Space Emulator (`172.16.1.0/30`)

### 2.1 Live Shell Commands (Immediate Execution)
```bash
# [Mars Router] Enable IPv4 Kernel Forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.d/99-ipforward.conf

# [Mars Router] Flush any existing IP addresses on operational interfaces
sudo ip addr flush dev eth0
sudo ip addr flush dev eth1

# [Mars Router] Assign IP addresses
sudo ip addr add 192.168.10.1/24 dev eth0
sudo ip addr add 172.16.1.1/30 dev eth1

# [Mars Router] Bring interfaces up
sudo ip link set dev eth0 up
sudo ip link set dev eth1 up

# [Mars Router] Add default route via Space Emulator
sudo ip route add default via 172.16.1.2 dev eth1

# [Mars Router] Ensure firewall allows packet forwarding
sudo iptables -F FORWARD
sudo iptables -P FORWARD ACCEPT
```

### 2.2 Persistent Netplan Configuration (Survives Reboot)
File: `/etc/netplan/01-mars-router.yaml`
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        - 192.168.10.1/24
    eth1:
      addresses:
        - 172.16.1.1/30
      routes:
        - to: default
          via: 172.16.1.2
```
Apply with:
```bash
# [Mars Router]
sudo netplan apply
```

### Verification on Linux `[Mars Router]`
```bash
# [Mars Router] Verify interface assignments
ip -br addr show

# [Mars Router] Verify routing table
ip route show

# [Mars Router] Verify reachability to Space Emulator
ping -c 3 172.16.1.2
```

**Expected Success Criteria**:
- `eth0` shows `192.168.10.1/24` UP.
- `eth1` shows `172.16.1.1/30` UP.
- `default via 172.16.1.2 dev eth1` is present.
- `ping -c 3 172.16.1.2` has `0% packet loss` with RTT $< 2\text{ ms}$.

---

## 3. Mars Host Configuration

**Target Device**: `[Mars Host]`  
Interface: `eth0` (connected to Mars LAN switch / Mars Router `eth0`)

### 3.1 Live Shell Commands
```bash
# [Mars Host] Configure IP and Default Gateway
sudo ip addr flush dev eth0
sudo ip addr add 192.168.10.10/24 dev eth0
sudo ip link set dev eth0 up
sudo ip route add default via 192.168.10.1 dev eth0

# [Mars Host] Test gateway reachability
ping -c 3 192.168.10.1
```

### 3.2 Persistent Netplan Configuration
File: `/etc/netplan/01-mars-host.yaml`
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        - 192.168.10.10/24
      routes:
        - to: default
          via: 192.168.10.1
```
Apply with:
```bash
# [Mars Host]
sudo netplan apply
```

**Expected Success Criteria**:
- Mars Host can ping its gateway `192.168.10.1` with `0% packet loss`.
