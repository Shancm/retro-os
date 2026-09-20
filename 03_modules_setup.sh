#!/usr/bin/env bash
# ==============================================================================
# RETRO OS - LAYER 3: WEAPONS BAY & SECURITY ARSENAL
# ==============================================================================
set -Eeuo pipefail

CYAN='\033[96m'
GREEN='\033[92m'
NC='\033[0m'

echo -e "${CYAN}[*] Installing Modern Rust Tooling & Distrobox Kali Sandbox...${NC}"

apt-get update -y
apt-get install -y --no-install-recommends \
    podman distrobox btop ripgrep micro nmap wireguard tor obfs4proxy ufw || true

# Configure UFW Default Stealth
ufw default deny incoming 2>/dev/null || true
ufw default allow outgoing 2>/dev/null || true
ufw enable 2>/dev/null || true

echo -e "${GREEN}[✓] Layer 3 Modules & Isolated Containers Configured.${NC}"
