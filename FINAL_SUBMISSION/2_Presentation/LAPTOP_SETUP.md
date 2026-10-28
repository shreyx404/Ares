# LAPTOP_SETUP.md — Dual-Laptop Presentation Preparation Guide
**Project ARES: The Mars Colony Network**  
*Configuration Specification for Live Evaluation*  
*Hardware Requirement: 2 Laptops (Laptop A & Laptop B)*

---

## 1. Laptop Roles & Strategic Redundancy Architecture

To ensure 100% demo resilience, the presentation workload is separated between two dedicated laptops:

```text
+------------------------------------+        +------------------------------------+
|             LAPTOP A               |        |             LAPTOP B               |
|       (Primary Demo Engine)        |        |   (Presentation & Backup Station)  |
|                                    |        |                                    |
| - Runs Linux Network Simulation    |        | - Displays Slides & Diagrams       |
| - 3 Pre-positioned Terminal Windows|        | - Displays Wireshark & Plots       |
| - NetEm Delay Scripts Loaded       |        | - Hosts Pre-Recorded Video/Screens |
| - iPerf3 Client & Server Active    |        | - Full Standby Replica of Sim      |
+------------------------------------+        +------------------------------------+
                  |                                      |
                  +------------------+-------------------+
                                     |
                                     v
                       [ HDMI / Projector Splitter ]
```

---

## 2. Laptop A Configuration (Primary Demo Laptop)

Laptop A is operated by **Presenter 2 (Demo Operator)**. Its sole job is to run the live simulation cleanly and visibly.

### 2.1 Display & Terminal Staging
- **Display Resolution**: Set to `1920x1080` (or `1366x768`) to match classroom projectors.
- **Terminal Font**: Monospace font (e.g., *Ubuntu Mono*, *Fira Code*, *Consolas*) set to **18pt Bold** with high contrast (Green-on-Black or White-on-Black).
- **Window Layout**: Split screen with **3 pre-arranged terminals**:
  - **Left Terminal (Mars Host)**:
    ```bash
    cd ~/DCN_CP/build
    sudo ip netns exec mars_host bash
    # Prompt: root@mars-host:~#
    ```
  - **Top-Right Terminal (Space Emulator)**:
    ```bash
    cd ~/DCN_CP/build
    sudo ip netns exec space_emulator bash
    # Prompt: root@space-emulator:~#
    ```
  - **Bottom-Right Terminal (Earth Server)**:
    ```bash
    cd ~/DCN_CP/build
    sudo ip netns exec earth_server bash
    # Prompt: root@earth-server:~#
    ```

### 2.2 Pre-Loaded Shell History
Before the presentation starts, run each command once in its respective terminal window so that Presenter 2 can simply press the **Up Arrow ($\uparrow$)** during the demo:
1. In Mars Host:
   - `ping -c 3 10.10.10.10`
   - `ping -c 2 10.10.10.10`
   - `iperf3 -c 10.10.10.10 -p 5201 -t 20 -i 1`
   - `iperf3 -c 10.10.10.10 -p 5201 -u -b 2M -t 20 -i 1`
2. In Space Emulator:
   - `tc qdisc replace dev se_eth0 root netem delay 5000ms 50ms loss 2% limit 10000`
   - `tc qdisc replace dev se_eth1 root netem delay 5000ms 50ms loss 2% limit 10000`
   - `tc qdisc show dev se_eth0`
   - `tc qdisc del dev se_eth0 root`
3. In Earth Server:
   - `ss -tuln | grep 5201`
   - `iperf3 -s -p 5201`

### 2.3 System Settings & Power
- **Power**: Connect to AC wall power.
- **Sleep & Screen Timeout**: Set "Turn off screen" and "Suspend" to **Never** while on battery and AC.
- **Notifications**: Turn on **Do Not Disturb** (disable desktop popups from Discord, WhatsApp, Email).

---

## 3. Laptop B Configuration (Presentation & Backup Laptop)

Laptop B is operated by **Presenter 1 (Project Narrator)** and used by **Presenter 3 (Analyst)** for deep-dive charts.

### 3.1 Pre-Loaded Software & Files
1. **Slide Deck**: Open full screen in PDF reader or PowerPoint (e.g. `Project_ARES_Slides.pdf` or PPTX).
2. **Wireshark**:
   - Pre-loaded with `results/project_ares_capture.pcap`.
   - Pre-configured with display filters saved in favorites:
     - `tcp.analysis.retransmission`
     - `tcp.analysis.ack_rtt > 1.0`
     - `icmp`
3. **High-Resolution Graphs**:
   - `tcp_vs_udp_throughput.png` open in image viewer at 100% zoom.
4. **Final Report PDF**:
   - `Project_ARES_Final_Report.pdf` open in another tab for evaluator reference.

### 3.2 Standby Redundancy Replica
Laptop B must also have the entire project repository cloned:
```bash
git clone <repo-url> ~/DCN_CP
cd ~/DCN_CP/build
sudo apt install -y iproute2 net-tools iperf3 tcpdump python3-matplotlib
```
*If Laptop A suffers hardware failure, Laptop B can plug into the projector and execute `sudo ./setup_namespaces.sh setup` immediately.*

---

## 4. Pre-Presentation Checklist (Countdown Protocol)

### T-Minus 30 Minutes (Staging Area)
- [ ] Connect both laptops to AC power chargers.
- [ ] Test HDMI cable / adapter connection to projector or external monitor.
- [ ] Set audio to Mute on both laptops.
- [ ] Disable Wi-Fi sleep mode; disable screen savers.

### T-Minus 15 Minutes (Verification Run)
- [ ] **Laptop A**: Run `sudo ./setup_namespaces.sh setup`.
- [ ] **Laptop A**: Verify zero-delay ping: `sudo ip netns exec mars_host ping -c 2 10.10.10.10` (< 1 ms).
- [ ] **Laptop A**: Start background iPerf3 server on Earth: `sudo ip netns exec earth_server iperf3 -s -D`.
- [ ] **Laptop A**: Test NetEm delay application and remove it to return to baseline.
- [ ] **Laptop B**: Open slides to Slide 1.
- [ ] **Laptop B**: Confirm Wireshark PCAP file opens and displays packets properly.

### T-Minus 2 Minutes (Final Standby)
- [ ] Laptop A has 3 terminal windows arranged side-by-side with 18pt font.
- [ ] Laptop B projector output verified.
- [ ] Presenters take their positions (Presenter 1 at Laptop B, Presenter 2 at Laptop A, Presenter 3 centered between both).
- [ ] Take a deep breath. You are 100% prepared.
