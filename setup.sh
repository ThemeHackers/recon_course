#!/usr/bin/env bash
set -euo pipefail

info() { printf '\e[1;34m[*]\e[0m %s\n' "$*"; }
warn() { printf '\e[1;33m[!]\e[0m %s\n' "$*"; }
err() { printf '\e[1;31m[-]\e[0m %s\n' "$*"; exit 1; }

OS="$(uname -s)"
if [ "$OS" != "Linux" ]; then
    err "This script supports Linux only. Detected OS: $OS"
fi

if [ "$EUID" -ne 0 ]; then
    warn "Not running as root — some commands will use sudo. You'll be asked for your password."
fi

WORKDIR="$HOME/recon_course"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

info "Updating package list..."
sudo apt update

info "Installing dependencies..."
sudo apt install -y libpcap-dev massdns git wget unzip curl parallel

info "Removing possible conflicting packages (if installed)..."
sudo apt-get remove -y python3-httpx || true
sudo apt-get purge -y python3-httpx || true

info "AutoRemove..."

sudo apt autoremove

DLW() {
    url="$1"
    out="$2"
    if command -v wget >/dev/null 2>&1; then
        wget -q --show-progress -O "$out" "$url"
    else
        curl -fsSL -o "$out" "$url"
    fi
}

info "Checking Go installation..."
if ! command -v go >/dev/null 2>&1; then
    info "Go not found. Installing Go to /usr/local..."
    GO_VERSION="1.23.2"
    ARCH="$(uname -m)"
    if [ "$ARCH" = "x86_64" ]; then
        GO_ARCH="amd64"
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        GO_ARCH="arm64"
    else
        err "Unsupported architecture: $ARCH"
    fi

    TARFILE="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    DLW "https://go.dev/dl/${TARFILE}" "$TARFILE"

    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "$TARFILE"
    rm -f "$TARFILE"

    if ! grep -q "/usr/local/go/bin" <<< "${PATH:-}"; then
        echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> "$HOME/.bashrc"
        export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    fi

    mkdir -p "$HOME/go"{/bin,/pkg,/src}
else
    info "Go is already installed: $(go version)"
fi

info "Installing/ensuring pdtm..."
GOPATH="$(go env GOPATH 2>/dev/null || true)"
if [ -z "$GOPATH" ]; then
    GOPATH="$HOME/go"
fi
mkdir -p "$GOPATH/bin"

if ! command -v pdtm >/dev/null 2>&1; then
    info "Installing pdtm via 'go install'..."
    (export PATH=$PATH:/usr/local/go/bin:"$GOPATH/bin"; go install github.com/projectdiscovery/pdtm/cmd/pdtm@latest)
    if ! grep -q "$GOPATH/bin" <<< "${PATH:-}"; then
        echo "export PATH=\$PATH:$GOPATH/bin" >> "$HOME/.bashrc"
        export PATH=$PATH:"$GOPATH/bin"
    fi
else
    info "pdtm already installed: $(pdtm -v 2>/dev/null || echo 'version unknown')"
fi

if command -v pdtm >/dev/null 2>&1; then
    info "Updating pdtm tools (non-interactive)..."
    pdtm -v -ia -igp || warn "pdtm update returned non-zero (continuing)"
fi

info "Downloading resolvers.txt..."
DLW "https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt" "resolvers.txt"

info "Cloning SecLists (if needed)..."
if [ ! -d "SecLists" ]; then
    git clone --depth 1 https://github.com/danielmiessler/SecLists.git SecLists
else
    info "SecLists already cloned; pulling latest..."
    (cd SecLists && git pull --ff-only) || warn "Could not update SecLists automatically"
fi

info "Downloading Subdominator (if not present)..."
if [ ! -f "Subdominator" ]; then
    DLW "https://github.com/Stratus-Security/Subdominator/releases/latest/download/Subdominator" "Subdominator"
    chmod +x Subdominator || true
else
    info "Subdominator already present"
fi

cat > "$WORKDIR/README.txt" <<EOF
Recon resources stored here:
- resolvers.txt
- SecLists/
- Subdominator (executable)
Note: You may need to restart your shell or run: source ~/.bashrc
EOF

info "Done! All recon resources are stored in $WORKDIR"
