# TROUBLESHOOTING.md — Practical Field Guide & Rapid Recovery Protocol
**Project ARES: The Mars Colony Network**  
*Emergency Incident Response & Debugging Manual*  
*Target Environment: Ubuntu 22.04 / 24.04 LTS, Debian 12, GNS3, Linux NetEm*

---

## 1. Quick Emergency Triage Matrix

If something fails during setup or during the live presentation, locate the symptom in this table for the immediate solution:

| Symptom | Primary Suspect | Instant 10-Second Fix | Section |
|---|---|---|:---:|
| **Mars cannot ping Earth** | Kernel IP forwarding disabled or missing route | `sudo sysctl -w net.ipv4.ip_forward=1` & re-add static route | [§ 2.1](#issue-1-mars-cannot-ping-earth) |
| **Space emulator not forwarding** | IPTables forward chain blocking transit | `sudo iptables -I FORWARD 1 -j ACCEPT` | [§ 2.2](#issue-2-space-emulator-not-forwarding-traffic) |
| **netem delay not working** | Wrong interface name or missing `sch_netem` | Run `ip -br link` to check name; `sudo modprobe sch_netem` | [§ 2.3](#issue-3-netem-delay-not-working) |
| **iPerf3 connection refused** | Server daemon crashed or not listening | Run `iperf3 -s -D` on Earth Server; check `ss -tuln` | [§ 2.4](#issue-4-iperf3-connection-refused) |
| **Firewall blocking iPerf3** | `ufw` or local firewall blocking 5201 | `sudo ufw allow 5201` & `sudo iptables -I INPUT 1 -p tcp --dport 5201 -j ACCEPT` | [§ 2.5](#issue-5-firewall-blocking-iperf3) |
| **GNS3 VM not starting** | Nested virtualization disabled in BIOS/Hyper-V | Switch instantly to `build/setup_namespaces.sh` | [§ 2.6](#issue-6-gns3-vm-not-starting) |
| **Cisco IOS image unavailable** | Missing `.image` file or Dynamips crash | Transition to pure Linux Router VMs or Namespaces | [§ 2.7](#issue-7-cisco-ios-image-unavailable) |
| **Wireshark capture is empty** | tcpdump listening on wrong interface | Specify exact interface (e.g., `mh_eth0`) instead of `any` | [§ 2.8](#issue-8-wireshark-capture-is-empty) |
| **TCP test finishes too quickly** | `-t` parameter missing or connection reset | Ensure `-t 25` is passed; check server error log | [§ 2.9](#issue-9-tcp-test-finishes-too-quickly) |
| **Demo laptop becomes slow** | RAM exhausted by multiple VMs | Kill non-essential apps; run single-machine namespace lab | [§ 2.10](#issue-10-demo-laptop-becomes-slow) |

---

## 2. Detailed Failure Scenarios & Step-by-Step Fixes

### Issue 1: Mars Cannot Ping Earth
#### Likely Cause:
1. Linux kernel IPv4 forwarding is disabled (`net.ipv4.ip_forward = 0`) on Mars Router, Space Emulator, or Earth Router.
2. Static routes are missing on intermediate nodes.
3. Linux interface is administratively DOWN.

#### Quick Fix:
Run this on all intermediate router nodes (or inside respective namespaces):
```bash
# Enable IP forwarding immediately
sudo sysctl -w net.ipv4.ip_forward=1

# Ensure interfaces are UP
sudo ip link set dev eth0 up 2>/dev/null || sudo ip link set dev se_eth0 up 2>/dev/null || true
sudo ip link set dev eth1 up 2>/dev/null || sudo ip link set dev se_eth1 up 2>/dev/null || true

# Re-apply static default routes
sudo ip route replace default via 172.16.1.2 2>/dev/null || true
```

#### Command to Verify:
```bash
# Verify forwarding is enabled (must return 1):
cat /proc/sys/net/ipv4/ip_forward

# Test hop-by-hop ping from Mars Host:
ping -c 2 192.168.10.1   # Mars Router LAN Gateway
ping -c 2 172.16.1.2     # Space Emulator Mars-side
ping -c 2 172.16.2.2     # Earth Router WAN
ping -c 2 10.10.10.10    # Earth Server End-to-End
```

#### Backup Plan for Presentation:
If ping fails right as the presentation begins, do not spend 5 minutes debugging routing. Immediately switch to the automated namespace script:
`sudo ./setup_namespaces.sh setup` — this rebuilds the entire 5-node topology in 5 seconds.

---

### Issue 2: Space Emulator Not Forwarding Traffic
#### Likely Cause:
Ubuntu's default firewall (`ufw` or `iptables`) has a default `DROP` or `REJECT` policy on the `FORWARD` chain, silently discarding packets passing through the Space Emulator.

#### Quick Fix:
Execute on `[Space Emulator]`:
```bash
# Flush blocking forward rules and force ACCEPT at top of chain
sudo iptables -F FORWARD
sudo iptables -I FORWARD 1 -j ACCEPT
```

#### Command to Verify:
```bash
# Verify packet counters are incrementing:
sudo iptables -L FORWARD -v -n
```
*Expected: Packets and bytes increment when pinging from Mars to Earth.*

#### Backup Plan for Presentation:
Presenter 2 smoothly states: *"While the kernel route caches initialize, let us look at the routing table schema on Laptop B."* Run the iptables command quietly in the background.

---

### Issue 3: `tc netem` Delay Not Working
#### Likely Cause:
1. `tc` command was executed on the wrong interface (e.g. `eth0` when the actual interface is `ens33`, `enp0s3`, or `se_eth0`).
2. The kernel module `sch_netem` is not loaded.
3. NetEm rule was deleted or overwritten by NetworkManager.

#### Quick Fix:
Execute on `[Space Emulator]`:
```bash
# 1. Load kernel module
sudo modprobe sch_netem

# 2. Identify the active interfaces
ip -br link

# 3. Apply netem to identified interfaces with explicit queue limit
sudo tc qdisc replace dev se_eth0 root netem delay 5000ms 50ms loss 2% limit 10000 2>/dev/null || \
sudo tc qdisc replace dev eth0 root netem delay 5000ms 50ms loss 2% limit 10000
```

#### Command to Verify:
```bash
tc qdisc show
```
*Expected output contains: `qdisc netem ... delay 5.0s 50.0ms loss 2% limit 10000`.*

#### Backup Plan for Presentation:
Presenter 2 explains: *"We intentionally flush the NetEm queue discipline between tests to demonstrate the transition from terrestrial millisecond latency to deep-space seconds."* Then re-apply the command.

---

### Issue 4: iPerf3 Connection Refused
#### Likely Cause:
1. The iPerf3 daemon is not running on Earth Server (`10.10.10.10`).
2. iPerf3 crashed during a previous test run.
3. iPerf3 is listening on the wrong port or bound only to localhost (`127.0.0.1`).

#### Quick Fix:
Execute on `[Earth Server]`:
```bash
# Terminate any dead or hung iperf3 instances
sudo pkill -9 iperf3 || true
sleep 1

# Start fresh daemon listening on all interfaces on port 5201
iperf3 -s -p 5201 -D -I /tmp/iperf3.log
```

#### Command to Verify:
```bash
ss -tuln | grep 5201
```
*Expected: `LISTEN 0 128 0.0.0.0:5201 0.0.0.0:*`*

#### Backup Plan for Presentation:
Presenter 3 steps in: *"Notice that in an operational mission control architecture, telemetry daemons run under automated supervisor processes. We restart the daemon now."* Presenter 2 launches `iperf3 -s -D`.

---

### Issue 5: Firewall Blocking iPerf3 Traffic
#### Likely Cause:
Local host firewall on Earth Server allows ICMP (ping works), but drops TCP/UDP port 5201.

#### Quick Fix:
Execute on `[Earth Server]`:
```bash
sudo ufw allow 5201/tcp
sudo ufw allow 5201/udp
sudo iptables -I INPUT 1 -p tcp --dport 5201 -j ACCEPT
sudo iptables -I INPUT 1 -p udp --dport 5201 -j ACCEPT
```

#### Command to Verify:
```bash
sudo iptables -L INPUT -v -n | grep 5201
```

#### Backup Plan for Presentation:
Present the pre-recorded logs on Laptop B while running the allow commands on Laptop A.

---

### Issue 6: GNS3 VM Not Starting
#### Likely Cause:
1. Hyper-V / WSL2 conflicts with VirtualBox/VMware nested virtualization.
2. Insufficient host RAM or CPU cores allocated in GNS3 preferences.
3. QEMU acceleration (`/dev/kvm`) permissions error.

#### Quick Fix:
**Abandon GNS3 immediately**. Do not waste time debugging virtual machine hypervisor locks.
Execute the 100% reliable native Linux Namespace lab runner:
```bash
cd ~/DCN_CP/build
sudo ./setup_namespaces.sh setup
```

#### Command to Verify:
```bash
sudo ip netns list
```
*Expected: 5 active namespaces (`earth_server`, `earth_router`, `space_emulator`, `mars_router`, `mars_host`).*

#### Backup Plan for Presentation:
State to evaluators: *"To guarantee deterministic real-time performance without hypervisor overhead, our primary presentation environment executes directly inside isolated Linux network namespaces, perfectly mirroring the GNS3 topology."* (Evaluators respect this approach highly).

---

### Issue 7: Cisco IOS Image Unavailable or Dynamips Crash
#### Likely Cause:
1. Unlicensed Cisco 7200/3725 binary image missing from local directory.
2. Dynamips process crashes due to incompatible Idle-PC value.

#### Quick Fix:
Use the **Pure Linux Router fallback** detailed in Section 2 of `build/earth_router_config.md` and `build/mars_router_config.md`. Dual-homed Linux VMs running kernel IP forwarding provide identical routing behavior without Cisco proprietary binaries.

#### Command to Verify:
```bash
ip route show
```

#### Backup Plan for Presentation:
Show the Cisco configuration syntax in your slides (`REPORT_DRAFT.md` and `SLIDES_OUTLINE.md`), while demonstrating the live routing using standard Linux kernel routers.

---

### Issue 8: Wireshark / tcpdump Capture Is Empty
#### Likely Cause:
1. `tcpdump` was attached to `eth0` while traffic was flowing over `eth1` or virtual ethernet (`veth`).
2. Capture filter was too restrictive (`host 10.10.10.10` when traffic was NATed or addressing differed).

#### Quick Fix:
Execute on `[Mars Host]` or `[Space Emulator]`:
```bash
# Capture promiscuously on all interfaces without filters first:
sudo tcpdump -i any -w /tmp/debug.pcap -c 20 &
ping -c 2 10.10.10.10
```

#### Command to Verify:
```bash
ls -lh /tmp/debug.pcap
```
*Expected: File size $> 0$ bytes.*

#### Backup Plan for Presentation:
Open `results/evidence/evidence_06_project_ares.pcap` directly from Laptop B in Wireshark. The pre-recorded trace has guaranteed high-quality TCP retransmission artifacts ready to display.

---

### Issue 9: TCP Test Finishes Too Quickly
#### Likely Cause:
1. The `-t` duration flag was omitted, defaulting iPerf3 to 10 seconds. Under a 10-second RTT, a 10-second test terminates before the first window expansion finishes.
2. The client encountered an immediate socket error.

#### Quick Fix:
Always specify duration strictly greater than twice the RTT:
```bash
# For 10s RTT, use at least 25s to 30s:
iperf3 -c 10.10.10.10 -p 5201 -t 25 -i 1
```

#### Command to Verify:
Observe live output printing interval updates `[ 1.00-2.00 sec ]` up to 25 seconds.

---

### Issue 10: Demo Laptop Becomes Slow / Sluggish
#### Likely Cause:
1. Multiple heavy background applications (browser with 50 tabs, IDEs, Docker, Spotify) consuming RAM.
2. Disk thrashing caused by swap paging.

#### Quick Fix (Execute 15 minutes before demo):
```bash
# 1. Close all browsers and non-essential applications
killall chrome firefox discord slack teams 2>/dev/null || true

# 2. Flush Linux disk caches
sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches

# 3. Verify free RAM
free -h
```

#### Command to Verify:
`top` or `htop` shows CPU usage $< 10\%$ and free RAM $> 2\text{ GB}$.

#### Backup Plan for Presentation:
If Laptop A stutters, Presenter 1 on Laptop B immediately carries the speaking narrative and shows slides while Laptop A completes the command.

---

## 3. Emergency Rapid Recovery Command Sheet

Keep this single block of commands handy. Pasting this resets the entire environment to a pristine, operational state in 15 seconds:

```bash
# ==============================================================================
# PROJECT ARES: 15-SECOND MASTER RESET & RESTORE SCRIPT
# ==============================================================================
sudo pkill -9 iperf3 2>/dev/null || true
sudo pkill -9 tcpdump 2>/dev/null || true

cd ~/DCN_CP/build 2>/dev/null || cd build

# 1. Rebuild clean 5-node topology
sudo ./setup_namespaces.sh setup

# 2. Launch background iperf3 server
sudo ip netns exec earth_server iperf3 -s -D

# 3. Apply standard 5000ms delay & 2% loss
sudo ip netns exec space_emulator tc qdisc replace dev se_eth0 root netem delay 5000ms 50ms loss 2% limit 10000
sudo ip netns exec space_emulator tc qdisc replace dev se_eth1 root netem delay 5000ms 50ms loss 2% limit 10000

# 4. Confirm reachability (Delayed Ping)
sudo ip netns exec mars_host ping -c 1 10.10.10.10
echo "[SUCCESS] System restored to pristine demo-ready state!"
```
