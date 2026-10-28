#!/usr/bin/env python3
"""
FINAL_PACKAGER.py — Cross-Platform University Submission Packager
================================================================
Automates the assembly of the FINAL_SUBMISSION/ directory and produces
Project_ARES_Final.zip on both Linux and Windows.
"""

import os
import sys
import shutil
import glob
import zipfile

ROOT_DIR = os.path.abspath(os.path.dirname(__file__))
SUBMISSION_DIR = os.path.join(ROOT_DIR, "FINAL_SUBMISSION")
ARCHIVE_NAME = os.path.join(ROOT_DIR, "Project_ARES_Final.zip")

def safe_copy(src, dest):
    """Safely copies a file if it exists."""
    if os.path.exists(src):
        os.makedirs(dest if os.path.isdir(dest) else os.path.dirname(dest), exist_ok=True)
        shutil.copy2(src, dest)

def safe_copy_glob(pattern, dest_dir):
    """Copies all files matching a glob pattern."""
    os.makedirs(dest_dir, exist_ok=True)
    for filepath in glob.glob(pattern):
        if os.path.isfile(filepath):
            shutil.copy2(filepath, dest_dir)

def main():
    print("=" * 70)
    print("    PROJECT ARES: ACADEMIC SUBMISSION PACKAGER (CROSS-PLATFORM)   ")
    print("=" * 70)

    # 1. Ensure report is generated
    final_report = os.path.join(ROOT_DIR, "FINAL_REPORT.md")
    if not os.path.exists(final_report):
        print("[*] FINAL_REPORT.md not found. Running INJECT_EVIDENCE.py...")
        os.system(f'"{sys.executable}" "{os.path.join(ROOT_DIR, "INJECT_EVIDENCE.py")}"')

    # 2. Reset staging folder
    if os.path.exists(SUBMISSION_DIR):
        shutil.rmtree(SUBMISSION_DIR)
    if os.path.exists(ARCHIVE_NAME):
        os.remove(ARCHIVE_NAME)

    folders = [
        os.path.join(SUBMISSION_DIR, "1_Project_Report", "images"),
        os.path.join(SUBMISSION_DIR, "2_Presentation"),
        os.path.join(SUBMISSION_DIR, "3_Evidence"),
        os.path.join(SUBMISSION_DIR, "4_Source_Code", "build"),
        os.path.join(SUBMISSION_DIR, "5_Raw_Data"),
    ]
    for f in folders:
        os.makedirs(f, exist_ok=True)

    # 3. 1_Project_Report
    print("[+] Staging 1_Project_Report...")
    for doc in ["FINAL_REPORT.md", "REPORT_DRAFT.md", "REPORT_TEMPLATE.md", "PROJECT_BRIEF.md", "NETWORK_DESIGN.md"]:
        safe_copy(os.path.join(ROOT_DIR, doc), os.path.join(SUBMISSION_DIR, "1_Project_Report"))
    
    # Copy images
    images_src = os.path.join(ROOT_DIR, "images")
    if os.path.exists(images_src):
        for img in os.listdir(images_src):
            safe_copy(os.path.join(images_src, img), os.path.join(SUBMISSION_DIR, "1_Project_Report", "images"))
    safe_copy(os.path.join(ROOT_DIR, "tcp_vs_udp_throughput.png"), os.path.join(SUBMISSION_DIR, "1_Project_Report", "images"))

    # 4. 2_Presentation
    print("[+] Staging 2_Presentation...")
    for doc in ["SLIDES_CONTENT.md", "SLIDES_OUTLINE.md", "DEMO_SCRIPT_3_PRESENTERS.md", "LAPTOP_SETUP.md", "VIVA_CHEATSHEET.md"]:
        safe_copy(os.path.join(ROOT_DIR, doc), os.path.join(SUBMISSION_DIR, "2_Presentation"))

    # 5. 3_Evidence
    print("[+] Staging 3_Evidence...")
    for doc in ["EVIDENCE_PACK.md", "VALIDATION_CHECKLIST.md"]:
        safe_copy(os.path.join(ROOT_DIR, doc), os.path.join(SUBMISSION_DIR, "3_Evidence"))
    safe_copy(os.path.join(ROOT_DIR, "tcp_vs_udp_throughput.png"), os.path.join(SUBMISSION_DIR, "3_Evidence"))
    
    evidence_dir = os.path.join(ROOT_DIR, "results", "evidence")
    if os.path.exists(evidence_dir):
        for item in os.listdir(evidence_dir):
            safe_copy(os.path.join(evidence_dir, item), os.path.join(SUBMISSION_DIR, "3_Evidence"))
    
    results_dir = os.path.join(ROOT_DIR, "results")
    if os.path.exists(results_dir):
        safe_copy_glob(os.path.join(results_dir, "*.pcap"), os.path.join(SUBMISSION_DIR, "3_Evidence"))
        safe_copy_glob(os.path.join(results_dir, "*.log"), os.path.join(SUBMISSION_DIR, "3_Evidence"))
        safe_copy_glob(os.path.join(results_dir, "*.txt"), os.path.join(SUBMISSION_DIR, "3_Evidence"))
        safe_copy_glob(os.path.join(results_dir, "*.png"), os.path.join(SUBMISSION_DIR, "3_Evidence"))

    # 6. 4_Source_Code
    print("[+] Staging 4_Source_Code...")
    build_dir = os.path.join(ROOT_DIR, "build")
    if os.path.exists(build_dir):
        for item in os.listdir(build_dir):
            safe_copy(os.path.join(build_dir, item), os.path.join(SUBMISSION_DIR, "4_Source_Code", "build"))
    for script in ["RUNBOOK_SOLO.md", "BUILD_AUDIT.md", "TROUBLESHOOTING.md", "ASSUMPTIONS.md", "INJECT_EVIDENCE.py"]:
        safe_copy(os.path.join(ROOT_DIR, script), os.path.join(SUBMISSION_DIR, "4_Source_Code"))

    # 7. 5_Raw_Data
    print("[+] Staging 5_Raw_Data...")
    if os.path.exists(results_dir):
        safe_copy_glob(os.path.join(results_dir, "*.json"), os.path.join(SUBMISSION_DIR, "5_Raw_Data"))
        safe_copy_glob(os.path.join(results_dir, "*.csv"), os.path.join(SUBMISSION_DIR, "5_Raw_Data"))
    safe_copy(os.path.join(build_dir, "results_table_template.csv"), os.path.join(SUBMISSION_DIR, "5_Raw_Data"))

    # 8. Create ZIP archive
    print("[+] Compressing submission package into Project_ARES_Final.zip...")
    with zipfile.ZipFile(ARCHIVE_NAME, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, _, files in os.walk(SUBMISSION_DIR):
            for file in files:
                abs_path = os.path.join(root, file)
                rel_path = os.path.relpath(abs_path, ROOT_DIR)
                zipf.write(abs_path, rel_path)

    size_mb = os.path.getsize(ARCHIVE_NAME) / (1024.0 * 1024.0)
    print("=" * 70)
    print(f"[SUCCESS] Packaging Complete! Archive: {ARCHIVE_NAME} ({size_mb:.2f} MB)")
    print(f" Staging Directory : {SUBMISSION_DIR}")
    print("=" * 70)

if __name__ == "__main__":
    main()
