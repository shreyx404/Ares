#!/bin/bash
# ==============================================================================
# Project ARES — Remove Space Link Netem Script
# Target Device: [Space Emulator]
# Description: Restores normal low-latency terrestrial transmission by removing
#              all artificial tc netem rules from the space interfaces.
# ==============================================================================

set -e

# Auto-detect namespace interfaces if present
if ip link show se_eth0 >/dev/null 2>&1; then
  DEFAULT_MARS_IF="se_eth0"
  DEFAULT_EARTH_IF="se_eth1"
else
  DEFAULT_MARS_IF="eth0"
  DEFAULT_EARTH_IF="eth1"
fi

MARS_IF="${MARS_IF:-$DEFAULT_MARS_IF}"
EARTH_IF="${EARTH_IF:-$DEFAULT_EARTH_IF}"

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "[-] ERROR: This script must be run as root or with sudo."
  echo "    Usage: sudo $0"
  exit 1
fi

echo "=================================================================="
echo "       PROJECT ARES: REMOVING SPACE LINK DELAY & LOSS             "
echo "=================================================================="

# Function: Remove NetEm qdisc cleanly
remove_qdisc() {
  local iface="$1"
  echo "[+] Removing tc qdisc from ${iface}..."
  if tc qdisc del dev "${iface}" root 2>/dev/null; then
    echo "    [OK] Reset ${iface} to default queue discipline."
  else
    echo "    [*] No active netem qdisc found on ${iface} (already clean)."
  fi
}

remove_qdisc "${MARS_IF}"
remove_qdisc "${EARTH_IF}"

echo ""
echo "=================================================================="
echo " [SUCCESS] Space Link Emulation Disabled! Normal link restored."
echo "=================================================================="
echo " Current tc configuration:"
tc qdisc show dev "${MARS_IF}"
tc qdisc show dev "${EARTH_IF}"
echo "------------------------------------------------------------------"
echo " To verify from [Mars Host], run:"
echo "   ping -c 5 10.10.10.10"
echo " (Expected RTT: < 10 ms with 0% packet loss)"
echo "=================================================================="
