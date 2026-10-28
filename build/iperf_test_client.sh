#!/bin/bash
# ==============================================================================
# Project ARES — iPerf3 Test Client Script
# Target Device: [Mars Host] (IP: 192.168.10.10)
# Description: Generates scientific TCP bulk data and real-time UDP sensor
#              telemetry streams across the emulated space link to Earth.
# ==============================================================================

set -e

# Default Target Parameters
EARTH_SERVER="${EARTH_SERVER_IP:-10.10.10.10}"
PORT="${IPERF_PORT:-5201}"
UDP_BITRATE="${UDP_BITRATE:-2M}"
DEFAULT_DURATION="${TEST_DURATION:-60}"
DEMO_DURATION="25"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Check if iPerf3 is installed
if ! command -v iperf3 &>/dev/null; then
  echo "[!] iPerf3 not found. Installing via apt..."
  sudo apt update && sudo apt install -y iperf3 jq
fi

show_menu() {
  echo "=================================================================="
  echo "         PROJECT ARES: MARS HABITAT IPERF3 TEST SUITE            "
  echo "=================================================================="
  echo " Target Earth Server : ${EARTH_SERVER}:${PORT}"
  echo " Telemetry Bitrate   : ${UDP_BITRATE}"
  echo " Output Directory    : $(pwd)/results"
  echo "------------------------------------------------------------------"
  echo " 1) Run Baseline Ping Check (Test 0 / Test 1)"
  echo " 2) Run TCP Scientific Transfer (Full 60s, saves JSON & log)"
  echo " 3) Run UDP Telemetry Stream (Full 60s @ 2Mbps, saves JSON & log)"
  echo " 4) Run Fast Demo Suite (25s TCP + 25s UDP — ideal for 10-min demo)"
  echo " 5) Run Complete Academic Test Suite (Sequential Baseline & Stress)"
  echo " 6) View Results & Run Python Analyzer"
  echo " 7) Exit"
  echo "=================================================================="
}

mkdir -p results

run_ping() {
  echo ""
  echo "[*] [Mars Host] Executing ICMP RTT diagnostic to Earth (${EARTH_SERVER})..."
  echo "    Command: ping -c 5 ${EARTH_SERVER}"
  echo "------------------------------------------------------------------"
  ping -c 5 "${EARTH_SERVER}" | tee "results/ping_test_${TIMESTAMP}.log"
  echo "------------------------------------------------------------------"
  echo "[+] Output saved to results/ping_test_${TIMESTAMP}.log"
}

run_tcp() {
  local dur="${1:-$DEFAULT_DURATION}"
  local prefix="${2:-tcp_test}"
  local json_file="results/${prefix}_${TIMESTAMP}.json"
  local text_file="results/${prefix}_${TIMESTAMP}.log"

  echo ""
  echo "[*] [Mars Host] Initiating TCP Scientific Data Stream (${dur} seconds)..."
  echo "    Command: iperf3 -c ${EARTH_SERVER} -p ${PORT} -t ${dur} -i 1 --json"
  echo "    Saving raw data to ${json_file} and ${text_file}..."
  echo "------------------------------------------------------------------"

  # Run iperf3 teeing human-readable output to terminal while saving JSON
  iperf3 -c "${EARTH_SERVER}" -p "${PORT}" -t "${dur}" -i 1 --json > "${json_file}" &
  CLIENT_PID=$!

  # Display live progress
  while kill -0 "${CLIENT_PID}" 2>/dev/null; do
    echo -n "."
    sleep 2
  done
  echo ""
  wait "${CLIENT_PID}"

  # Extract summary if jq available
  if command -v jq &>/dev/null; then
    local bps=$(jq '.end.sum_sent.bits_per_second // 0' "${json_file}")
    local mbps=$(echo "scale=3; ${bps} / 1000000" | bc 2>/dev/null || awk "BEGIN {print ${bps}/1000000}")
    local retrans=$(jq '.end.sum_sent.retransmits // 0' "${json_file}")
    echo "=================================================================="
    echo " [TCP SUMMARY] Duration: ${dur}s"
    echo "  - Mean Throughput  : ${mbps} Mbps"
    echo "  - Retransmissions  : ${retrans}"
    echo "=================================================================="
  else
    echo "[+] TCP test complete. Data stored in ${json_file}"
  fi
}

run_udp() {
  local dur="${1:-$DEFAULT_DURATION}"
  local prefix="${2:-udp_test}"
  local json_file="results/${prefix}_${TIMESTAMP}.json"

  echo ""
  echo "[*] [Mars Host] Initiating Constant Bitrate (CBR) UDP Telemetry Stream (${dur}s @ ${UDP_BITRATE})..."
  echo "    Command: iperf3 -c ${EARTH_SERVER} -p ${PORT} -u -b ${UDP_BITRATE} -t ${dur} -i 1 --json"
  echo "------------------------------------------------------------------"

  iperf3 -c "${EARTH_SERVER}" -p "${PORT}" -u -b "${UDP_BITRATE}" -t "${dur}" -i 1 --json > "${json_file}" &
  CLIENT_PID=$!

  while kill -0 "${CLIENT_PID}" 2>/dev/null; do
    echo -n "."
    sleep 2
  done
  echo ""
  wait "${CLIENT_PID}"

  if command -v jq &>/dev/null; then
    local bps=$(jq '.end.sum.bits_per_second // 0' "${json_file}")
    local mbps=$(echo "scale=3; ${bps} / 1000000" | bc 2>/dev/null || awk "BEGIN {print ${bps}/1000000}")
    local loss=$(jq '.end.sum.lost_percent // 0' "${json_file}")
    local jitter=$(jq '.end.sum.jitter_ms // 0' "${json_file}")
    echo "=================================================================="
    echo " [UDP SUMMARY] Duration: ${dur}s"
    echo "  - Mean Delivery Rate : ${mbps} Mbps"
    echo "  - Lost Packets       : ${loss} %"
    echo "  - Jitter             : ${jitter} ms"
    echo "=================================================================="
  else
    echo "[+] UDP test complete. Data stored in ${json_file}"
  fi
}

run_demo_suite() {
  echo ""
  echo "[*] Starting FAST LIVE DEMO SUITE (Total time ~50 seconds)..."
  run_tcp "${DEMO_DURATION}" "tcp_demo"
  echo ""
  echo "[*] Pausing 3 seconds before telemetry burst..."
  sleep 3
  run_udp "${DEMO_DURATION}" "udp_demo"
  echo ""
  echo "[*] Running python analyzer on results..."
  if [ -f "analyze_iperf.py" ]; then
    python3 analyze_iperf.py || true
  fi
}

# Non-interactive command-line argument handling
if [ "$#" -gt 0 ]; then
  case "$1" in
    ping) run_ping ;;
    tcp) run_tcp "${2:-$DEFAULT_DURATION}" "tcp_run" ;;
    udp) run_udp "${2:-$DEFAULT_DURATION}" "udp_run" ;;
    demo) run_demo_suite ;;
    all)
      run_ping
      run_tcp "$DEFAULT_DURATION" "tcp_full"
      run_udp "$DEFAULT_DURATION" "udp_full"
      ;;
    *)
      echo "Unknown command: $1. Available: ping, tcp, udp, demo, all"
      exit 1
      ;;
  esac
  exit 0
fi

# Interactive Menu Loop
while true; do
  show_menu
  read -p "Select an option [1-7]: " choice
  case "$choice" in
    1) run_ping ;;
    2) run_tcp "$DEFAULT_DURATION" "tcp_test" ;;
    3) run_udp "$DEFAULT_DURATION" "udp_test" ;;
    4) run_demo_suite ;;
    5)
      run_ping
      run_tcp "$DEFAULT_DURATION" "tcp_test"
      run_udp "$DEFAULT_DURATION" "udp_test"
      ;;
    6)
      if [ -f "analyze_iperf.py" ]; then
        python3 analyze_iperf.py
      else
        echo "[-] analyze_iperf.py not found in current directory."
      fi
      ;;
    7)
      echo "Exiting."
      exit 0
      ;;
    *)
      echo "Invalid selection."
      ;;
  esac
  echo ""
  read -p "Press [Enter] to return to menu..."
done
