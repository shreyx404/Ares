# Earth Router Configuration — Project ARES

This guide provides complete, copy-paste-ready configuration commands for the **Earth Router** and **Earth Server**. Both Cisco IOS (GNS3) and Pure Linux (Ubuntu/Debian) implementations are provided.

---

## 1. Cisco IOS Configuration (GNS3 / Cisco 7200 / 3725)

**Target Device**: `[Earth Router]`  
**Console Access**: Connect via GNS3 serial console or Telnet.

```cisco
! Enter Privileged EXEC and Global Configuration Mode
enable
configure terminal

! Set Hostname
hostname Earth-Router

! Configure Earth LAN Interface (Facing Earth Mission Control Server)
interface FastEthernet0/0
 description Earth Mission Control Internal LAN
 ip address 10.10.10.1 255.255.255.0
 no shutdown
 exit

! Configure Space Link Interface (Facing Space Emulator)
interface FastEthernet0/1
 description Interplanetary Link Downlink from Space Emulator
 ip address 172.16.2.2 255.255.255.252
 no shutdown
 exit

! Configure Static Default Route toward Space Emulator
ip route 0.0.0.0 0.0.0.0 172.16.2.1

! Save Running Configuration to NVRAM
end
write memory
```

### Verification on Cisco IOS `[Earth Router]`
```cisco
show ip interface brief
show ip route
ping 172.16.2.1
```

**Expected Success Criteria**:
- `FastEthernet0/0` status: `up`, protocol: `up`, IP `10.10.10.1`.
- `FastEthernet0/1` status: `up`, protocol: `up`, IP `172.16.2.2`.
- Route `S* 0.0.0.0/0 [1/0] via 172.16.2.1` appears in routing table.
- Ping to `172.16.2.1` returns `Success rate is 100 percent (5/5)`.

---

## 2. Pure Linux Fallback Configuration (Ubuntu / Debian VM)

If Cisco IOS images are not available, use a dual-homed Ubuntu 22.04/24.04 VM as the Earth Router.

**Target Device**: `[Earth Router]`  
Assume interfaces:
- `eth0` = Connected to Space Emulator (`172.16.2.0/30`)
- `eth1` = Connected to Earth LAN (`10.10.10.0/24`)

### 2.1 Live Shell Commands (Immediate Execution)
```bash
# [Earth Router] Enable IPv4 Kernel Forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.d/99-ipforward.conf

# [Earth Router] Flush any existing IP addresses
sudo ip addr flush dev eth0
sudo ip addr flush dev eth1

# [Earth Router] Assign IP addresses
sudo ip addr add 172.16.2.2/30 dev eth0
sudo ip addr add 10.10.10.1/24 dev eth1

# [Earth Router] Bring interfaces up
sudo ip link set dev eth0 up
sudo ip link set dev eth1 up

# [Earth Router] Add default route via Space Emulator
sudo ip route add default via 172.16.2.1 dev eth0

# [Earth Router] Ensure firewall allows packet forwarding
sudo iptables -F FORWARD
sudo iptables -P FORWARD ACCEPT
```

### 2.2 Persistent Netplan Configuration (Survives Reboot)
File: `/etc/netplan/01-earth-router.yaml`
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        - 172.16.2.2/30
      routes:
        - to: default
          via: 172.16.2.1
    eth1:
      addresses:
        - 10.10.10.1/24
```
Apply with:
```bash
# [Earth Router]
sudo netplan apply
```

### Verification on Linux `[Earth Router]`
```bash
# [Earth Router] Verify interface assignments
ip -br addr show

# [Earth Router] Verify routing table
ip route show

# [Earth Router] Verify reachability to Space Emulator
ping -c 3 172.16.2.1
```

**Expected Success Criteria**:
- `eth0` shows `172.16.2.2/30` UP.
- `eth1` shows `10.10.10.1/24` UP.
- `default via 172.16.2.1 dev eth0` is present.
- `ping -c 3 172.16.2.1` has `0% packet loss` with RTT $< 2\text{ ms}$.

---

## 3. Earth Server Configuration

**Target Device**: `[Earth Server]`  
Interface: `eth0` (connected to Earth LAN switch / Earth Router `eth1`)

### 3.1 Live Shell Commands
```bash
# [Earth Server] Configure IP and Default Gateway
sudo ip addr flush dev eth0
sudo ip addr add 10.10.10.10/24 dev eth0
sudo ip link set dev eth0 up
sudo ip route add default via 10.10.10.1 dev eth0

# [Earth Server] Test gateway reachability
ping -c 3 10.10.10.1
```

### 3.2 Persistent Netplan Configuration
File: `/etc/netplan/01-earth-server.yaml`
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        - 10.10.10.10/24
      routes:
        - to: default
          via: 10.10.10.1
```
Apply with:
```bash
# [Earth Server]
sudo netplan apply
```

**Expected Success Criteria**:
- Earth Server can ping its gateway `10.10.10.1` with `0% packet loss`.
