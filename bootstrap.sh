#!/bin/bash
# bootstrap.sh - Run ONCE inside WSL to install tools and execute the full lab
# Usage from PowerShell: wsl -d Ubuntu-24.04 -- sudo bash /mnt/c/Users/shrey/Downloads/DCN_CP/bootstrap.sh
set -e
echo "[1/3] Installing required packages..."
apt-get update -qq
apt-get install -y iperf3 iproute2 tcpdump python3 python3-matplotlib 2>&1

echo "[2/3] Converting scripts to Unix line endings..."
sed -i 's/\r//' /mnt/c/Users/shrey/Downloads/DCN_CP/build/setup_namespaces.sh
sed -i 's/\r//' /mnt/c/Users/shrey/Downloads/DCN_CP/RUN_FULL_LAB.sh

echo "[3/3] Verifying tools..."
which iperf3 tc tcpdump python3
echo "Bootstrap complete. Running full lab now..."
echo "==============================================="
exec bash /mnt/c/Users/shrey/Downloads/DCN_CP/RUN_FULL_LAB.sh
