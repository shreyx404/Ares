# EXECUTION_PLAN.md — 7-Day Project ARES Plan

## Day 1 — Environment Setup and Project Skeleton

Goal: Prepare tools and confirm the project structure.

Tasks:

1. Create all project Markdown files.
2. Install required tools:
   - GNS3 or virtualization tool.
   - Wireshark.
   - iPerf3.
   - tcpdump.
   - Python.
3. Decide implementation route:
   - GNS3 with Cisco IOS.
   - GNS3 with Linux nodes.
   - Pure Linux VM fallback.
4. Create topology diagram.
5. Confirm IP addressing plan.

Done Criteria:

- All tools are installed.
- Topology diagram exists.
- IP table exists.
- Team roles are assigned.

## Day 2 — Basic Network Build

Goal: Make Mars and Earth reachable without delay.

Tasks:

1. Create Mars host.
2. Create Earth host.
3. Create routers or Linux forwarding node.
4. Assign IP addresses.
5. Configure static routes.
6. Test ping from Mars to Earth.
7. Save configuration commands.

Done Criteria:

- Mars host can ping Earth host.
- Routing table is correct.
- Basic topology is stable.

## Day 3 — Space Link Emulation

Goal: Add artificial delay and packet loss.

Tasks:

1. Configure Space Emulator.
2. Enable IP forwarding.
3. Apply `tc netem` delay Profile A.
4. Test ping and confirm increased RTT.
5. Save delay script.
6. Create delay removal script.

Done Criteria:

- Ping RTT increases from milliseconds to seconds.
- Delay can be enabled and disabled easily.
- Packet loss is visible if configured.

## Day 4 — Protocol Testing

Goal: Generate TCP and UDP evidence.

Tasks:

1. Start iPerf3 server on Earth.
2. Run TCP test from Mars.
3. Run UDP test from Mars.
4. Capture traffic using Wireshark or tcpdump.
5. Save logs and PCAP files.
6. Record observations.

Done Criteria:

- TCP test log exists.
- UDP test log exists.
- PCAP file exists.
- Delay is visible in captures or ping output.

## Day 5 — Analysis and Graphs

Goal: Convert raw data into report-ready evidence.

Tasks:

1. Export iPerf3 results.
2. Create CSV tables.
3. Generate TCP vs UDP throughput graph.
4. Identify TCP retransmissions or delayed ACKs in Wireshark.
5. Create result comparison table.
6. Save screenshots.

Done Criteria:

- At least one graph exists.
- At least one result table exists.
- At least one Wireshark screenshot exists.

## Day 6 — Report Writing

Goal: Produce the final academic report.

Tasks:

1. Write abstract.
2. Write introduction.
3. Include topology and IP plan.
4. Include configuration commands.
5. Include test results.
6. Explain TCP failure and UDP behavior.
7. Explain bandwidth-delay product.
8. Write conclusion.

Done Criteria:

- Full report draft exists.
- Report follows `REPORT_TEMPLATE.md`.
- All major evidence is included.

## Day 7 — Demo Preparation and Backup

Goal: Prepare final presentation.

Tasks:

1. Rehearse live demo.
2. Prepare backup screenshots.
3. Prepare backup PCAP files.
4. Prepare short explanation for each result.
5. Export final project files.
6. Create submission package.

Done Criteria:

- Demo works in under 10 minutes.
- Backup evidence exists.
- Final report is complete.