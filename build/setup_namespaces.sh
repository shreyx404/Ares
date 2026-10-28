#!/bin/bash
# ==============================================================================
# Project ARES — 1-Machine Linux Network Namespace Lab Runner
# Description: Instantly instantiates the complete 5-node (or 3-node) Mars-Earth
#              simulation topology on any single Ubuntu/Debian laptop or VM
#              without requiring GNS3, VirtualBox, or multiple virtual machines.
# ==============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
  echo "[-] ERROR: This setup script must be run as root or with sudo."
  echo "    Usage: sudo $0 [setup|teardown]"
  exit 1
fi

ACTION="${1:-setup}"

teardown_lab() {
  echo "[*] Tearing down Project ARES namespaces and virtual links..."
  ip netns del mars_host 2>/dev/null || true
  ip netns del mars_router 2>/dev/null || true
  ip netns del space_emulator 2>/dev/null || true
  ip netns del earth_router 2>/dev/null || true
  ip netns del earth_server 2>/dev/null || true
  echo "[+] Teardown complete. All namespaces removed."
}

if [ "$ACTION" == "teardown" ] || [ "$ACTION" == "clean" ]; then
  teardown_lab
  exit 0
fi

# Clean previous setup
teardown_lab

echo "=================================================================="
echo "    PROJECT ARES: INSTANT SINGLE-MACHINE NAMESPACE LAB BUILDER    "
echo "=================================================================="

# 1. Create Namespaces
echo "[+] Creating 5 network namespaces..."
ip netns add mars_host
ip netns add mars_router
ip netns add space_emulator
ip netns add earth_router
ip netns add earth_server

# 2. Create Virtual Ethernet (veth) link pairs
echo "[+] Creating virtual cable pairs (veth)..."
ip link add mh_eth0 type veth peer name mr_eth0
ip link add mr_eth1 type veth peer name se_eth0
ip link add se_eth1 type veth peer name er_eth0
ip link add er_eth1 type veth peer name es_eth0

# 3. Assign veth endpoints into namespaces
echo "[+] Connecting interfaces to respective nodes..."
ip link set mh_eth0 netns mars_host
ip link set mr_eth0 netns mars_router
ip link set mr_eth1 netns mars_router
ip link set se_eth0 netns space_emulator
ip link set se_eth1 netns space_emulator
ip link set er_eth0 netns earth_router
ip link set er_eth1 netns earth_router
ip link set es_eth0 netns earth_server

# 4. Configure Mars Host
echo "[+] Configuring [Mars Host] (192.168.10.10/24)..."
ip netns exec mars_host ip link set lo up
ip netns exec mars_host ip addr add 192.168.10.10/24 dev mh_eth0
ip netns exec mars_host ip link set mh_eth0 up
ip netns exec mars_host ip route replace default via 192.168.10.1

# 5. Configure Mars Router
echo "[+] Configuring [Mars Router]..."
ip netns exec mars_router ip link set lo up
ip netns exec mars_router ip addr add 192.168.10.1/24 dev mr_eth0
ip netns exec mars_router ip addr add 172.16.1.1/30 dev mr_eth1
ip netns exec mars_router ip link set mr_eth0 up
ip netns exec mars_router ip link set mr_eth1 up
ip netns exec mars_router sysctl -w net.ipv4.ip_forward=1 >/dev/null
ip netns exec mars_router iptables -I FORWARD 1 -j ACCEPT 2>/dev/null || true
ip netns exec mars_router ip route replace default via 172.16.1.2

# 6. Configure Space Emulator
echo "[+] Configuring [Space Emulator]..."
ip netns exec space_emulator ip link set lo up
ip netns exec space_emulator ip addr add 172.16.1.2/30 dev se_eth0
ip netns exec space_emulator ip addr add 172.16.2.1/30 dev se_eth1
ip netns exec space_emulator ip link set se_eth0 up
ip netns exec space_emulator ip link set se_eth1 up
ip netns exec space_emulator sysctl -w net.ipv4.ip_forward=1 >/dev/null
ip netns exec space_emulator iptables -I FORWARD 1 -j ACCEPT 2>/dev/null || true
ip netns exec space_emulator ip route replace 192.168.10.0/24 via 172.16.1.1 dev se_eth0
ip netns exec space_emulator ip route replace 10.10.10.0/24 via 172.16.2.2 dev se_eth1

# 7. Configure Earth Router
echo "[+] Configuring [Earth Router]..."
ip netns exec earth_router ip link set lo up
ip netns exec earth_router ip addr add 172.16.2.2/30 dev er_eth0
ip netns exec earth_router ip addr add 10.10.10.1/24 dev er_eth1
ip netns exec earth_router ip link set er_eth0 up
ip netns exec earth_router ip link set er_eth1 up
ip netns exec earth_router sysctl -w net.ipv4.ip_forward=1 >/dev/null
ip netns exec earth_router iptables -I FORWARD 1 -j ACCEPT 2>/dev/null || true
ip netns exec earth_router ip route replace default via 172.16.2.1

# 8. Configure Earth Server
echo "[+] Configuring [Earth Server] (10.10.10.10/24)..."
ip netns exec earth_server ip link set lo up
ip netns exec earth_server ip addr add 10.10.10.10/24 dev es_eth0
ip netns exec earth_server ip link set es_eth0 up
ip netns exec earth_server ip route replace default via 10.10.10.1

echo ""
echo "=================================================================="
echo " [SUCCESS] 5-Node Interplanetary Network Emulation is ACTIVE!    "
echo "=================================================================="
echo " How to execute commands within each node:"
echo "   - On Mars Host      : sudo ip netns exec mars_host <command>"
echo "   - On Space Emulator : sudo ip netns exec space_emulator <command>"
echo "   - On Earth Server   : sudo ip netns exec earth_server <command>"
echo ""
echo " Immediate Baseline Ping Test:"
ip netns exec mars_host ping -c 3 10.10.10.10
echo "------------------------------------------------------------------"
echo " To inject Space Link Delay (Profile A):"
echo "   sudo ip netns exec space_emulator tc qdisc add dev se_eth0 root netem delay 5000ms loss 2% limit 10000"
echo "   sudo ip netns exec space_emulator tc qdisc add dev se_eth1 root netem delay 5000ms loss 2% limit 10000"
echo ""
echo " To teardown:"
echo "   sudo $0 teardown"
echo "=================================================================="
