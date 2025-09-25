#!/bin/bash

# =============================
# Color & log functions
# =============================
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

timestamp() { date +"%Y-%m-%d %H:%M:%S"; }
info() { echo -e "${CYAN}[$(timestamp) i] $1${RESET}"; }
success() { echo -e "${GREEN}[$(timestamp) ✓] $1${RESET}"; }
error() { echo -e "${RED}[$(timestamp) x] $1${RESET}"; }

# =============================
# Check input
# =============================
if [ -z "$1" ]; then
    echo -e "${YELLOW}Usage: $0 <domain>${RESET}"
    exit 1
fi

DOMAIN=$1
OUTDIR="RECON-$DOMAIN"
mkdir -p "$OUTDIR"

# =============================
# Welcome banner
# =============================
echo -e "${CYAN}==============================================${RESET}"
echo -e "${CYAN}🔎 Welcome to the Recon Tool for ${DOMAIN}${RESET}"
echo -e "${CYAN}==============================================${RESET}"
echo -e "${YELLOW}This tool will perform the following steps:${RESET}"
echo -e "${YELLOW}1️ subfinder       ${RESET}- Enumerates all subdomains"
echo -e "${YELLOW}2️ alterx + dnsx   ${RESET}- Checks alive subdomains"
echo -e "${YELLOW}3️ naabu           ${RESET}- Scans top 100 TCP ports"
echo -e "${YELLOW}4️ httpx           ${RESET}- Fetches HTTP info"
echo -e "${YELLOW}5️ katana          ${RESET}- Discovers JS endpoints"
echo -e "${YELLOW}6️ httpx (katana)  ${RESET}- HTTP info from Katana results"
echo -e "${YELLOW}7️ cdncheck        ${RESET}- Checks CDN/WAF protections"
echo -e "${CYAN}==============================================${RESET}"
echo -e "${GREEN}All results will be saved in: ${OUTDIR}${RESET}"
echo -e "${GREEN}Starting the recon process...${RESET}\n"
sleep 2

info "Starting recon for $DOMAIN"

# =============================
# Step 1: Subdomain enumeration
# =============================
info "[Step 1] Enumerating subdomains"
subfinder -d "$DOMAIN" > "$OUTDIR/subdomains.txt"
success "Subdomains saved to $OUTDIR/subdomains.txt"

# =============================
# Step 2: Check alive subdomains
# =============================
info "[Step 2] Checking alive subdomains"
cat "$OUTDIR/subdomains.txt" | alterx | dnsx > "$OUTDIR/sub_alterx_dnsx.txt"
success "Alive subdomains saved to $OUTDIR/sub_alterx_dnsx.txt"

# =============================
# Step 3: Naabu top 100 ports
# =============================
info "[Step 3] Scanning top 100 TCP ports"
cat "$OUTDIR/sub_alterx_dnsx.txt" | naabu -top-ports 100 -ep 22 -o "$OUTDIR/open_ports.txt"
success "Open ports saved to $OUTDIR/open_ports.txt"

# =============================
# Step 4: HTTPX scan
# =============================
info "[Step 4] Running httpx scan"
cat "$OUTDIR/open_ports.txt" | httpx -title -sc -cl -location -fr -o "$OUTDIR/httpx.txt"
success "HTTP info saved to $OUTDIR/httpx.txt"

# =============================
# Step 5: Katana JS endpoints
# =============================
info "[Step 5] Discovering JS endpoints"
cat "$OUTDIR/subdomains.txt" | katana -jsl -jc > "$OUTDIR/katana_jsl_jc.txt"
success "Katana results saved to $OUTDIR/katana_jsl_jc.txt"

# =============================
# Step 6: HTTPX on Katana results
# =============================
info "[Step 6] Running httpx on Katana results"
cat "$OUTDIR/katana_jsl_jc.txt" | httpx -title -sc -cl -location -o "$OUTDIR/httpx_katana_jsl_jc.txt"
success "HTTP info from Katana saved to $OUTDIR/httpx_katana_jsl_jc.txt"

# =============================
# Step 7: CDN/WAF check
# =============================
info "[Step 7] Checking CDN/WAF"
cat "$OUTDIR/subdomains.txt" | cdncheck -cdn -cloud -waf -resp -v > "$OUTDIR/cdncheck.txt"
success "CDN/WAF check saved to $OUTDIR/cdncheck.txt"

success "Recon finished for $DOMAIN. All results are in $OUTDIR"
                                                                     
