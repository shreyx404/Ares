#!/bin/bash
# ==============================================================================
# Project ARES — Packet Capture Script
# Target Device: [Mars Host] or [Space Emulator]
# Description: Captures deep space traffic using tcpdump to generate Wireshark-
#              compatible PCAP evidence of delayed ACKs and retransmissions.
# ==============================================================================

set -e

IFACE="${CAPTURE_IF:-any}"
DURATION="${CAPTURE_DURATION:-60}"
TARGET_IP="${EARTH_SERVER_IP:-10.10.10.10}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_PCAP="results/ares_capture_${TIMESTAMP}.pcap"

mkdir -p results

# Check for root / sudo
if [ "$EUID" -ne 0 ]; then
  echo "[-] ERROR: Packet capture requires root privileges."
  echo "    Usage: sudo $0 [duration_in_seconds] [interface]"
  exit 1
fi

# Override duration and interface if passed
if [ -n "$1" ]; then
  DURATION="$1"
fi
if [ -n "$2" ]; then
  IFACE="$2"
fi

# Check tcpdump installation
if ! command -v tcpdump &>/dev/null; then
  echo "[!] tcpdump not found. Installing..."
  apt update && apt install -y tcpdump
fi

echo "=================================================================="
echo "          PROJECT ARES: INTERPLANETARY PACKET CAPTURE             "
echo "=================================================================="
echo " Capture Interface   : ${IFACE}"
echo " Filter Expression   : host ${TARGET_IP} or icmp"
echo " Duration            : ${DURATION} seconds (or press Ctrl+C to stop)"
echo " Output File         : ${OUTPUT_PCAP}"
echo "=================================================================="

echo "[+] Starting packet capture now..."
echo "[*] Trigger your ping or iPerf3 tests in another terminal window."
echo ""

# Run tcpdump with portable timeout or background
if command -v timeout &>/dev/null; then
  timeout --preserve-status "${DURATION}s" tcpdump -i "${IFACE}" -nn "host ${TARGET_IP} or icmp" -w "${OUTPUT_PCAP}" 2>&1 | tee "results/capture_${TIMESTAMP}.log" || true
else
  tcpdump -i "${IFACE}" -nn "host ${TARGET_IP} or icmp" -w "${OUTPUT_PCAP}" 2>&1 | tee "results/capture_${TIMESTAMP}.log" &
  TCPDUMP_PID=$!
  sleep "${DURATION}"
  kill "${TCPDUMP_PID}" 2>/dev/null || true
fi

echo ""
echo "=================================================================="
echo " [SUCCESS] Capture Complete! Saved to: ${OUTPUT_PCAP}"
echo " File Size: $(du -h "${OUTPUT_PCAP}" | cut -f1)"
echo "------------------------------------------------------------------"
echo " HOW TO ANALYZE THIS PCAP IN WIRESHARK:"
echo " 1. Copy the file to your host machine:"
echo "    scp user@vm_ip:$(pwd)/${OUTPUT_PCAP} ."
echo " 2. Open in Wireshark and apply these diagnostic display filters:"
echo "    - Find TCP Retransmissions : tcp.analysis.retransmission"
echo "    - Identify Delayed ACKs    : tcp.analysis.ack_rtt > 1.0"
echo "    - Track Fast Retransmits   : tcp.analysis.fast_retransmission"
echo "    - Isolate UDP Telemetry    : udp.port == 5201"
echo "    - Isolate Ping Latency     : icmp"
echo " 3. View Visual Plots:"
echo "    - Go to: Statistics -> TCP Stream Graphs -> Round Trip Time"
echo "    - Go to: Statistics -> I/O Graphs (Add Y-Axis: tcp.analysis.retransmission)"
echo "=================================================================="
