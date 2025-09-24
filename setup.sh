#!/bin/bash
# setup.sh
# Script to install and prepare environment for recon tasks on Linux only

set -e


OS=$(uname)
if [ "$OS" != "Linux" ]; then
    echo "[!] This script supports Linux only. Detected OS: $OS"
    exit 1
fi

echo "[*] Updating package list..."
sudo apt update -y

echo "[*] Installing dependencies..."
sudo apt install -y libpcap-dev massdns git wget unzip curl parallel
echo "[*] Remove duplicate httpx..."
sudo apt remove python3-httpx
echo "[*] Checking Go installation..."
if ! command -v go &>/dev/null; then
    echo "[*] Go not found. Installing Go..."

    GO_VERSION="1.23.2"
    ARCH=$(uname -m)

    if [ "$ARCH" = "x86_64" ]; then
        GO_ARCH="amd64"
    elif [ "$ARCH" = "aarch64" ]; then
        GO_ARCH="arm64"
    else
        echo "[!] Unsupported architecture: $ARCH"
        exit 1
    fi

    wget https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-${GO_ARCH}.tar.gz
    rm go${GO_VERSION}.linux-${GO_ARCH}.tar.gz

    export PATH=$PATH:/usr/local/go/bin
    echo "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" >> ~/.bashrc
    source ~/.bashrc
else
    echo "[*] Go is already installed."
fi

echo "[*] Installing pdtm..."
if ! command -v pdtm &>/dev/null; then
    go install github.com/projectdiscovery/pdtm/cmd/pdtm@latest
    export PATH=$PATH:$(go env GOPATH)/bin
fi

echo "[*] Updating pdtm tools..."
pdtm -v -ia -igp

echo "[*] Downloading resolvers.txt..."
wget -O resolvers.txt https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt

echo "[*] Cloning SecLists..."
if [ ! -d "SecLists" ]; then
    git clone https://github.com/danielmiessler/SecLists.git
fi

echo "[+] Done! All recon resources are stored in ~/recon_course"
