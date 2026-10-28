#!/bin/bash
# ==============================================================================
# Project ARES — Space Link Netem Injection Script
# Target Device: [Space Emulator]
# Description: Injects interplanetary propagation delay, jitter, and stochastic
#              packet loss using Linux Traffic Control (tc netem).
# ==============================================================================

set -e

# --- Configuration & Environment Variables ---
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
QUEUE_LIMIT="${QUEUE_LIMIT:-10000}"

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "[-] ERROR: This script must be run as root or with sudo."
  echo "    Usage: sudo $0 [profile_a|profile_b|profile_c|custom]"
  exit 1
fi

# Function: Display usage banner
show_banner() {
  echo "=================================================================="
  echo "       PROJECT ARES: INTERPLANETARY SPACE LINK EMULATOR          "
  echo "=================================================================="
  echo " Active Mars Interface  : ${MARS_IF}"
  echo " Active Earth Interface : ${EARTH_IF}"
  echo " Queue Buffer Limit     : ${QUEUE_LIMIT} packets (prevents artificial overflow)"
  echo "------------------------------------------------------------------"
}

# Function: Apply NetEm to an interface
apply_netem() {
  local iface="$1"
  local delay="$2"
  local loss="$3"
  local jitter="$4"

  echo "[+] Applying NetEm on interface ${iface}..."
  
  # Ensure interface exists
  if ! ip link show "${iface}" >/dev/null 2>&1; then
    echo "[-] ERROR: Interface ${iface} does not exist. Check interface naming (e.g., ens3, enp0s3)."
    exit 1
  fi

  # Attempt replace first; if no qdisc exists, fall back to add
  if tc qdisc replace dev "${iface}" root netem delay "${delay}" "${jitter}" loss "${loss}" limit "${QUEUE_LIMIT}" 2>/dev/null; then
    echo "    [OK] Updated qdisc on ${iface}."
  else
    tc qdisc add dev "${iface}" root netem delay "${delay}" "${jitter}" loss "${loss}" limit "${QUEUE_LIMIT}"
    echo "    [OK] Added new qdisc on ${iface}."
  fi
}

# Select Profile
PROFILE="${1:-profile_a}"

case "${PROFILE}" in
  profile_a|safe|demo)
    DELAY="5000ms"
    LOSS="2%"
    JITTER="50ms"
    PROFILE_DESC="Profile A: Standard Demo (5s One-Way / 10s RTT, 2% Loss)"
    ;;
  profile_b|strong|extreme)
    DELAY="15000ms"
    LOSS="5%"
    JITTER="200ms"
    PROFILE_DESC="Profile B: Strong Mars Effect (15s One-Way / 30s RTT, 5% Loss)"
    ;;
  profile_c|deep_space)
    DELAY="60000ms"
    LOSS="10%"
    JITTER="500ms"
    PROFILE_DESC="Profile C: Deep Space Opposition (60s One-Way / 120s RTT, 10% Loss)"
    ;;
  custom)
    read -p "Enter One-Way Delay in ms (e.g. 5000ms): " DELAY
    read -p "Enter Packet Loss in % (e.g. 2%): " LOSS
    read -p "Enter Jitter in ms (e.g. 50ms): " JITTER
    PROFILE_DESC="Custom Profile: ${DELAY} delay, ${LOSS} loss, ${JITTER} jitter"
    ;;
  *)
    echo "[-] Unknown profile: ${PROFILE}"
    echo "    Available profiles: profile_a (default), profile_b, profile_c, custom"
    exit 1
    ;;
esac

show_banner
echo "[*] Selected: ${PROFILE_DESC}"
echo "[*] Note: Delay is applied bidirectionally (Mars->Earth & Earth->Mars)."
echo "    Total Round-Trip Time (RTT) will be approx: $((${DELAY//ms/} * 2 / 1000)) seconds."
echo ""

# Apply impairments to both directional interfaces
apply_netem "${MARS_IF}" "${DELAY}" "${LOSS}" "${JITTER}"
apply_netem "${EARTH_IF}" "${DELAY}" "${LOSS}" "${JITTER}"

echo ""
echo "=================================================================="
echo " [SUCCESS] Space Link Emulation Active!"
echo "=================================================================="
echo " Current tc configuration:"
tc qdisc show dev "${MARS_IF}"
tc qdisc show dev "${EARTH_IF}"
echo "------------------------------------------------------------------"
echo " To verify from [Mars Host], run:"
echo "   ping -c 5 10.10.10.10"
echo " (Expected RTT: ~$((${DELAY//ms/} * 2 / 1000)) seconds with ~${LOSS} loss)"
echo ""
echo " To remove delay, execute on [Space Emulator]:"
echo "   sudo ./remove_netem.sh"
echo "=================================================================="
