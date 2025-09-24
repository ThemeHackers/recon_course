#!/bin/bash
# hc_tool.sh
# Interactive script to show help (-h or --help) of selected tools

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

show_menu() {
    clear
    echo "========== Tool Help Menu =========="
    for i in "${!TOOLS[@]}"; do
        printf "%2d) %s\n" $((i+1)) "${TOOLS[i]}"
    done
    echo "  0) Exit"
    echo "==================================="
}

while true; do
    show_menu
    read -p "Select a tool (number): " choice

    if [ "$choice" = "0" ]; then
        echo "Exiting..."
        break
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#TOOLS[@]}" ]; then
        echo "[!] Invalid choice, press Enter to retry..."
        read
        continue
    fi

    TOOL="${TOOLS[$((choice-1))]}"

    if command -v "$TOOL" &>/dev/null; then
        clear
        echo "==== Showing help for $TOOL ===="
        { "$TOOL" -h 2>/dev/null || "$TOOL" --help 2>/dev/null || echo "No help option available."; } | less -R
    else
        echo "[!] $TOOL is not installed."
        read -p "Press Enter to return to menu..."
    fi
done
