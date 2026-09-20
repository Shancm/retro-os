#!/usr/bin/env bash
# ==============================================================================
# RETRO OS - LAYER 1: BULLETPROOF CORE ENGINE
# ==============================================================================
set -Eeuo pipefail

CYAN='\033[96m'
GREEN='\033[92m'
RED='\033[91m'
NC='\033[0m'

echo -e "${CYAN}[*] Configuring Retro OS Core Engine (Performance & Fault-Tolerance)...${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Execute with sudo: sudo bash 01_engine_setup.sh${NC}"
    exit 1
fi

apt-get update -y
apt-get install -y --no-install-recommends \
    zram-tools earlyoom btrfs-progs snapper curl git jq ufw libinput-tools

# 1. ZRAM Swap with ZSTD Compression (8GB -> 14GB Equivalent)
cat << 'EOF' > /etc/default/zramswap
ALGO=zstd
PERCENT=50
PRIORITY=100
EOF

systemctl restart zramswap 2>/dev/null || true
systemctl enable zramswap 2>/dev/null || true

# 2. EarlyOOM Anti-Freeze Configuration
cat << 'EOF' > /etc/default/earlyoom
EARLYOOM_ARGS="-m 5 -s 100 --avoid '^(kwin|plasma-shell|Xwayland|kitty)$' --prefer '^(Web Content|chrome|firefox)$'"
EOF

systemctl restart earlyoom 2>/dev/null || true
systemctl enable earlyoom 2>/dev/null || true

# 3. Kernel Tuning for Low-Latency & Rapid Responsiveness
cat << 'EOF' > /etc/sysctl.d/99-retro-performance.conf
vm.vfs_cache_pressure=50
vm.dirty_background_ratio=5
vm.dirty_ratio=10
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
sysctl --system 2>/dev/null || true

echo -e "${GREEN}[✓] Layer 1 Engine Configured Successfully.${NC}"
