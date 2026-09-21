#!/usr/bin/env bash
# ==============================================================================
# RETRO OS - LAYER 3: TOOLS & CONTAINERS
# ==============================================================================
set -Eeuo pipefail

CYAN='\033[96m'
GREEN='\033[92m'
RED='\033[91m'
NC='\033[0m'

echo -e "${CYAN}[*] Installing Security Framework & Podman Distrobox...${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Execute with sudo: sudo bash 03_modules_setup.sh${NC}"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends \
    podman distrobox btop ripgrep micro nmap wireguard tor obfs4proxy ufw curl git xclip

# UFW Firewall Active Default
ufw default deny incoming 2>/dev/null || true
ufw default allow outgoing 2>/dev/null || true
ufw --force enable 2>/dev/null || true

echo -e "${GREEN}[✓] Layer 3 Modules Configured Successfully.${NC}"
