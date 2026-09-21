#!/usr/bin/env bash
# ==============================================================================
# RETRO OS - LAYER 1: CORE ENGINE & OPTIMIZATIONS
# ==============================================================================
set -Eeuo pipefail

CYAN='\033[96m'
GREEN='\033[92m'
RED='\033[91m'
NC='\033[0m'

echo -e "${CYAN}[*] Configuring Retro OS Core Engine (ZRAM, Btrfs, Performance)...${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Execute with sudo: sudo bash 01_engine_setup.sh${NC}"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends \
    zram-tools earlyoom btrfs-progs snapper curl git jq ufw libinput-tools

# 1. ZRAM Swap (ZSTD Compression)
cat << 'EOF' > /etc/default/zramswap
ALGO=zstd
PERCENT=50
PRIORITY=100
EOF

systemctl restart zramswap 2>/dev/null || true
systemctl enable zramswap 2>/dev/null || true

# 2. EarlyOOM Daemon
cat << 'EOF' > /etc/default/earlyoom
EARLYOOM_ARGS="-m 5 -s 100 --avoid '^(kwin|plasma-shell|Xwayland|kitty)$' --prefer '^(Web Content|chrome|firefox)$'"
EOF

systemctl restart earlyoom 2>/dev/null || true
systemctl enable earlyoom 2>/dev/null || true

# 3. Enable BBR & Sysctl Optimizations
modprobe tcp_bbr 2>/dev/null || true
if ! grep -q "tcp_bbr" /etc/modules 2>/dev/null; then
    echo "tcp_bbr" >> /etc/modules
fi

cat << 'EOF' > /etc/sysctl.d/99-retro-performance.conf
vm.vfs_cache_pressure=50
vm.dirty_background_ratio=5
vm.dirty_ratio=10
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
sysctl --system 2>/dev/null || true

# 4. Snapper Btrfs Setup
if command -v snapper &> /dev/null; then
    if ! snapper list-configs 2>/dev/null | grep -q "root"; then
        snapper -c root create-config / 2>/dev/null || true
    fi
fi

echo -e "${GREEN}[✓] Layer 1 Engine Configured Successfully.${NC}"

