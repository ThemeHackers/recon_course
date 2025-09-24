#!/bin/bash
# hc_tool.sh
# Script to check available commands / help for each installed recon tool

set -e

TOOLS=(
  aix
  alterx
  asnmap
  cdncheck
  chaos-client
  cloudlist
  dnsx
  httpx
  interactsh-client
  interactsh-server
  katana
  mapcidr
  naabu
  notify
  nuclei
  pdtm
  proxify
  shuffledns
  simplehttpserver
  subfinder
  tldfinder
  tlsx
  tunnelx
  uncover
  urlfinder
  vulnx
)

OUTPUT_DIR="./tool_help"
mkdir -p "$OUTPUT_DIR"

for tool in "${TOOLS[@]}"; do
    echo "[*] Checking $tool..."
    
    # ตรวจสอบว่าเครื่องมือมีอยู่ใน PATH หรือไม่
    if command -v "$tool" &>/dev/null; then
        # รัน help (-h) และ --help แล้วเก็บในไฟล์
        {
            echo "==== HELP: $tool ===="
            "$tool" -h 2>&1 || echo "No -h option"
            echo ""
            "$tool" --help 2>&1 || echo "No --help option"
        } > "$OUTPUT_DIR/$tool.txt"
        echo "[+] Saved help for $tool -> $OUTPUT_DIR/$tool.txt"
    else
        echo "[!] $tool not installed, skipping..."
    fi
done

echo "[*] Done! All help files are in $OUTPUT_DIR/"
