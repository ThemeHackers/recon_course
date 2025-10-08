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
warn() { echo -e "${YELLOW}[$(timestamp) !] $1${RESET}"; }

# =============================
# Dependency Check
# =============================
check_deps() {
    info "Checking for required tools..."
    local missing_deps=0
    for tool in subfinder httpx naabu katana cdncheck; do
        if ! command -v "$tool" &> /dev/null; then
            error "$tool could not be found. Please install it."
            missing_deps=1
        fi
    done
    if [ "$missing_deps" -eq 1 ]; then
        error "Aborting due to missing dependencies."
        exit 1
    fi
    success "All required tools are installed."
}

# =============================
# Main Script
# =============================
if [ -z "$1" ]; then
    warn "Usage: $0 <domain>"
    exit 1
fi

DOMAIN=$1
OUTDIR="RECON-$DOMAIN"
mkdir -p "$OUTDIR"

# Check dependencies before starting
check_deps

# Welcome banner
echo -e "\n${CYAN}==============================================${RESET}"
echo -e "${CYAN}🔎 Efficient Recon for ${DOMAIN}${RESET}"
echo -e "${CYAN}==============================================${RESET}"
echo -e "${GREEN}All results will be saved in: ${OUTDIR}${RESET}"
echo -e "${GREEN}Starting the recon process...${RESET}\n"
sleep 1

info "Starting recon for $DOMAIN"

# ================================================================
# Step 1: Subdomain enumeration with Subfinder
# ================================================================
info "[1/5] Enumerating subdomains with Subfinder..."
subfinder -d "$DOMAIN" -o "$OUTDIR/subdomains.txt"
if [ ! -s "$OUTDIR/subdomains.txt" ]; then
    error "Subfinder found no subdomains. Exiting."
    exit 1
fi
success "Found $(wc -l < "$OUTDIR/subdomains.txt") subdomains. Saved to subdomains.txt"

# ================================================================
# Step 2: Find alive hosts with httpx
# ================================================================
info "[2/5] Probing for alive web hosts with httpx..."
httpx -l "$OUTDIR/subdomains.txt" -sc -cl -o "$OUTDIR/alive_hosts.txt"
if [ ! -s "$OUTDIR/alive_hosts.txt" ]; then
    error "httpx found no alive web hosts. Exiting."
    exit 1
fi
success "Found $(wc -l < "$OUTDIR/alive_hosts.txt") alive web hosts. Saved to alive_hosts.txt"

# ================================================================
# Step 3: Run parallel scans on alive hosts
# ================================================================
info "[3/5] Starting parallel scans (Port Scan, Crawling, CDN/WAF Check)..."

# Task A: Port scan with Naabu -> Pipe to httpx for detailed info
info "  -> (Task A) Scanning ports and gathering HTTP info..."
naabu -l "$OUTDIR/alive_hosts.txt" -top-ports 100 -ep 22 -silent | httpx -title -tech-detect -sc -cl -fr -o "$OUTDIR/http_info.txt" &

# Task B: Crawl endpoints with Katana
info "  -> (Task B) Crawling for endpoints with Katana..."
katana -l "$OUTDIR/alive_hosts.txt" -jc -jsl -o "$OUTDIR/katana_endpoints.txt" &

# Task C: Check for CDN/WAF with cdncheck
info "  -> (Task C) Checking CDN/WAF with cdncheck..."
cdncheck -i "$OUTDIR/alive_hosts.txt" -cdn -waf -resp -o "$OUTDIR/cdn_info.txt" &

# Wait for all background jobs to finish
wait
success "Parallel scans completed."

# ================================================================
# Step 4: Validate endpoints found by Katana
# ================================================================
info "[4/5] Validating endpoints discovered by Katana..."
if [ -s "$OUTDIR/katana_endpoints.txt" ]; then
    httpx -l "$OUTDIR/katana_endpoints.txt" -sc -cl -title -o "$OUTDIR/katana_alive_endpoints.txt"
    success "Validated Katana endpoints saved to katana_alive_endpoints.txt"
else
    warn "Katana found no endpoints to validate."
fi

# ================================================================
# Step 5: Final Summary
# ================================================================
info "[5/5] Recon finished for $DOMAIN."
success "All results are saved in the '$OUTDIR' directory."
echo -e "${CYAN}==============================================${RESET}"
ls -l "$OUTDIR"
echo -e "${CYAN}==============================================${RESET}"
