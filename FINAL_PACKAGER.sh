#!/bin/bash
# ==============================================================================
# FINAL_PACKAGER.sh — Project ARES University Submission Packager
# Target OS: Ubuntu / Debian / Linux / Git Bash
# Description: Automates the assembly of a clean, professionally structured
#              submission directory (FINAL_SUBMISSION/) and builds the final
#              deliverable archive: Project_ARES_Final.zip.
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

SUBMISSION_DIR="FINAL_SUBMISSION"
ARCHIVE_NAME="Project_ARES_Final.zip"

echo "=================================================================="
echo "    PROJECT ARES: ACADEMIC SUBMISSION PACKAGER & ARCHIVE ENGINE   "
echo "=================================================================="

# Step 0: Ensure FINAL_REPORT.md is compiled
if [ ! -f "FINAL_REPORT.md" ]; then
  echo "[*] FINAL_REPORT.md not found. Running INJECT_EVIDENCE.py now..."
  python3 INJECT_EVIDENCE.py || python INJECT_EVIDENCE.py || true
fi

# Step 1: Wipe any previous packaging staging folder
echo "[+] Initializing clean target staging directory: ${SUBMISSION_DIR}/..."
rm -rf "${SUBMISSION_DIR}"
rm -f "${ARCHIVE_NAME}"

mkdir -p "${SUBMISSION_DIR}/1_Project_Report/images"
mkdir -p "${SUBMISSION_DIR}/2_Presentation"
mkdir -p "${SUBMISSION_DIR}/3_Evidence"
mkdir -p "${SUBMISSION_DIR}/4_Source_Code"
mkdir -p "${SUBMISSION_DIR}/5_Raw_Data"

# Step 2: Populate 1_Project_Report
echo "[+] Staging 1_Project_Report (Academic Paper & Figures)..."
cp -f FINAL_REPORT.md "${SUBMISSION_DIR}/1_Project_Report/" 2>/dev/null || true
cp -f REPORT_DRAFT.md "${SUBMISSION_DIR}/1_Project_Report/" 2>/dev/null || true
cp -f REPORT_TEMPLATE.md "${SUBMISSION_DIR}/1_Project_Report/" 2>/dev/null || true
cp -f PROJECT_BRIEF.md "${SUBMISSION_DIR}/1_Project_Report/" 2>/dev/null || true
cp -f NETWORK_DESIGN.md "${SUBMISSION_DIR}/1_Project_Report/" 2>/dev/null || true

# Copy report images
if [ -d "images" ]; then
  cp -rf images/* "${SUBMISSION_DIR}/1_Project_Report/images/" 2>/dev/null || true
fi
if [ -f "tcp_vs_udp_throughput.png" ]; then
  cp -f tcp_vs_udp_throughput.png "${SUBMISSION_DIR}/1_Project_Report/images/" 2>/dev/null || true
fi

# Step 3: Populate 2_Presentation
echo "[+] Staging 2_Presentation (Slide Content, Demo Scripts, & Viva Guide)..."
cp -f SLIDES_CONTENT.md "${SUBMISSION_DIR}/2_Presentation/" 2>/dev/null || true
cp -f SLIDES_OUTLINE.md "${SUBMISSION_DIR}/2_Presentation/" 2>/dev/null || true
cp -f DEMO_SCRIPT_3_PRESENTERS.md "${SUBMISSION_DIR}/2_Presentation/" 2>/dev/null || true
cp -f LAPTOP_SETUP.md "${SUBMISSION_DIR}/2_Presentation/" 2>/dev/null || true
cp -f VIVA_CHEATSHEET.md "${SUBMISSION_DIR}/2_Presentation/" 2>/dev/null || true

# Step 4: Populate 3_Evidence
echo "[+] Staging 3_Evidence (PCAPs, Plots, Test Logs & Checklists)..."
cp -f EVIDENCE_PACK.md "${SUBMISSION_DIR}/3_Evidence/" 2>/dev/null || true
cp -f VALIDATION_CHECKLIST.md "${SUBMISSION_DIR}/3_Evidence/" 2>/dev/null || true
cp -f tcp_vs_udp_throughput.png "${SUBMISSION_DIR}/3_Evidence/" 2>/dev/null || true

if [ -d "results/evidence" ]; then
  cp -rf results/evidence/* "${SUBMISSION_DIR}/3_Evidence/" 2>/dev/null || true
fi

# Copy PCAP, logs, and PNGs from results/
if [ -d "results" ]; then
  cp -f results/*.pcap "${SUBMISSION_DIR}/3_Evidence/" 2>/dev/null || true
  cp -f results/*.log "${SUBMISSION_DIR}/3_Evidence/" 2>/dev/null || true
  cp -f results/*.txt "${SUBMISSION_DIR}/3_Evidence/" 2>/dev/null || true
  cp -f results/*.png "${SUBMISSION_DIR}/3_Evidence/" 2>/dev/null || true
fi

# Step 5: Populate 4_Source_Code
echo "[+] Staging 4_Source_Code (Linux NetEm scripts, analyzers, and runbooks)..."
mkdir -p "${SUBMISSION_DIR}/4_Source_Code/build"
cp -rf build/* "${SUBMISSION_DIR}/4_Source_Code/build/" 2>/dev/null || true
cp -f RUNBOOK_SOLO.md "${SUBMISSION_DIR}/4_Source_Code/" 2>/dev/null || true
cp -f BUILD_AUDIT.md "${SUBMISSION_DIR}/4_Source_Code/" 2>/dev/null || true
cp -f TROUBLESHOOTING.md "${SUBMISSION_DIR}/4_Source_Code/" 2>/dev/null || true
cp -f ASSUMPTIONS.md "${SUBMISSION_DIR}/4_Source_Code/" 2>/dev/null || true
cp -f INJECT_EVIDENCE.py "${SUBMISSION_DIR}/4_Source_Code/" 2>/dev/null || true

# Step 6: Populate 5_Raw_Data
echo "[+] Staging 5_Raw_Data (iPerf3 JSON records and parsed CSV metrics)..."
if [ -d "results" ]; then
  cp -f results/*.json "${SUBMISSION_DIR}/5_Raw_Data/" 2>/dev/null || true
  cp -f results/*.csv "${SUBMISSION_DIR}/5_Raw_Data/" 2>/dev/null || true
fi
cp -f build/results_table_template.csv "${SUBMISSION_DIR}/5_Raw_Data/" 2>/dev/null || true

# Step 7: Clean temporary artifacts
echo "[*] Cleaning temporary files..."
find "${SUBMISSION_DIR}" -type f -name "*~" -delete 2>/dev/null || true
find "${SUBMISSION_DIR}" -type f -name ".DS_Store" -delete 2>/dev/null || true
find "${SUBMISSION_DIR}" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

# Step 8: Build ZIP Archive
echo "[+] Creating final submission archive: ${ARCHIVE_NAME}..."

# Check if zip utility exists; if not, use Python zipfile fallback
if command -v zip &>/dev/null; then
  zip -r "${ARCHIVE_NAME}" "${SUBMISSION_DIR}" >/dev/null
else
  echo "[*] Standard 'zip' binary not found. Utilizing Python zipfile fallback..."
  python3 -c "
import shutil, os
shutil.make_archive('Project_ARES_Final', 'zip', '.', '${SUBMISSION_DIR}')
" || python -c "
import shutil, os
shutil.make_archive('Project_ARES_Final', 'zip', '.', '${SUBMISSION_DIR}')
"
fi

echo ""
echo "=================================================================="
echo " [SUCCESS] University Submission Package Built Successfully!      "
echo "=================================================================="
echo " Directory Staging Structure:"
echo "   ├── ${SUBMISSION_DIR}/1_Project_Report/  (FINAL_REPORT.md & images/)"
echo "   ├── ${SUBMISSION_DIR}/2_Presentation/    (SLIDES_CONTENT.md, DEMO_SCRIPT, & VIVA)"
echo "   ├── ${SUBMISSION_DIR}/3_Evidence/        (PCAPs, PNG graphs, & logs)"
echo "   ├── ${SUBMISSION_DIR}/4_Source_Code/     (build/ scripts & RUNBOOK)"
echo "   └── ${SUBMISSION_DIR}/5_Raw_Data/        (JSON logs & CSV summaries)"
echo "------------------------------------------------------------------"
if [ -f "${ARCHIVE_NAME}" ]; then
  ARCHIVE_SIZE=$(du -h "${ARCHIVE_NAME}" 2>/dev/null | cut -f1 || echo "Ready")
  echo " Submission Archive : ${ARCHIVE_NAME} (${ARCHIVE_SIZE})"
fi
echo "=================================================================="
