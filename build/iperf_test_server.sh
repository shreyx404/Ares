#!/bin/bash
# ==============================================================================
# Project ARES — iPerf3 Server Daemon Script
# Target Device: [Earth Server] (IP: 10.10.10.10)
# Description: Starts and manages the iPerf3 listening daemon to receive
#              interplanetary telemetry (UDP) and scientific data (TCP).
# ==============================================================================

set -e

PORT="${IPERF_PORT:-5201}"
LOG_FILE="iperf3_server.log"

echo "=================================================================="
echo "       PROJECT ARES: EARTH MISSION CONTROL IPERF3 SERVER          "
echo "=================================================================="

# Check if iPerf3 is installed
if ! command -v iperf3 &>/dev/null; then
  echo "[!] iPerf3 not found. Attempting installation via apt..."
  sudo apt update && sudo apt install -y iperf3
fi

# Parse Command Arguments
ACTION="${1:-foreground}"

case "$ACTION" in
  start|daemon|-d|--daemon)
    # Stop existing instance if running
    if pgrep iperf3 >/dev/null; then
      echo "[*] Stopping previous iperf3 instance..."
      pkill -f "iperf3 -s" || true
      sleep 1
    fi
    echo "[+] Starting iperf3 server in BACKGROUND daemon mode on port ${PORT}..."
    iperf3 -s -p "${PORT}" -D -I "${LOG_FILE}"
    echo "[SUCCESS] iPerf3 server running in background (PID: $(pgrep -f "iperf3 -s"))."
    echo "          Logging output to: ${LOG_FILE}"
    ;;
  
  stop)
    echo "[*] Stopping iperf3 server..."
    if pkill -f "iperf3 -s"; then
      echo "[SUCCESS] iPerf3 server stopped."
    else
      echo "[*] No active iperf3 server process found."
    fi
    exit 0
    ;;

  status)
    echo "[*] Checking iperf3 server status..."
    if pgrep -f "iperf3 -s" >/dev/null; then
      echo "[UP] iPerf3 server is active (PID: $(pgrep -f "iperf3 -s"))."
      ss -tuln | grep ":${PORT}" || true
    else
      echo "[DOWN] iPerf3 server is not currently running."
    fi
    exit 0
    ;;

  foreground|run|*)
    echo "[+] Opening local firewall for port ${PORT}..."
    sudo ufw allow "${PORT}/tcp" >/dev/null 2>&1 || true
    sudo ufw allow "${PORT}/udp" >/dev/null 2>&1 || true

    echo "[+] Starting iPerf3 server in FOREGROUND on 0.0.0.0:${PORT}..."
    echo "[*] Press Ctrl+C at any time to terminate the server."
    echo "------------------------------------------------------------------"
    iperf3 -s -p "${PORT}"
    ;;
esac

echo "------------------------------------------------------------------"
echo " To run tests from [Mars Host], execute:"
echo "   ./iperf_test_client.sh"
echo "=================================================================="
