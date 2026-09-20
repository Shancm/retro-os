#!/usr/bin/env bash
# ==============================================================================
# RETRO OS - Core Engine Setup Script (The Bulletproof Base)
# Target Base: Debian 12 Minimal / Ubuntu 24.04 LTS
# ==============================================================================

# 1. Zero-Error Strict Execution Protocol
set -Eeuo pipefail
trap 'echo -e "\n\033[91m[-] Fatal Error at Line $LINENO! Command: $BASH_COMMAND failed.\033[0m" >&2' ERR

echo -e "\033[92m[+] Starting Retro OS Core Engine Initialization...\033[0m"

# Root Permission Check
if [ "$EUID" -ne 0 ]; then
    echo -e "\033[91m[-] Please run as root: sudo bash 01_engine_setup.sh\033[0m"
    exit 1
fi

# 2. Base Index Update & Essential Packages Installation
echo -e "\033[94m[*] Updating base package indexes...\033[0m"
apt-get update -y
apt-get install -y --no-install-recommends \
    zram-tools \
    earlyoom \
    btrfs-progs \
    snapper \
    curl \
    wget \
    git \
    build-essential

# 3. ZRAM Setup with ZSTD Compression (RAM Multiplier)
echo -e "\033[94m[*] Configuring ZRAM Swap with ZSTD compression...\033[0m"
cat <<EOF > /etc/default/zramswap
# Allocates 60% RAM to ZRAM to expand effective capacity
PERCENT=60
# High-speed modern compression algorithm
ALGO=zstd
PRIORITY=100
EOF

systemctl restart zramswap
systemctl enable zramswap

# 4. Anti-Freeze Protection (EarlyOOM Setup)
echo -e "\033[94m[*] Setting up EarlyOOM anti-hang daemon...\033[0m"
# Kills unresponsive memory-hogging processes when RAM exceeds 95% and Swap exceeds 90%
cat <<EOF > /etc/default/earlyoom
EARLYOOM_ARGS="-m 5 -s 10 -r 60 --avoid '(kde|wayland|Xorg|sshd)'"
EOF

systemctl restart earlyoom
systemctl enable earlyoom

# 5. Linux Kernel Swappiness & Cache Tuning
echo -e "\033[94m[*] Applying sysctl performance optimizations...\033[0m"
cat <<EOF > /etc/sysctl.d/99-retro-performance.conf
# Aggressively prioritize ZRAM over disk paging
vm.swappiness = 100
# Maintain responsive filesystem cache
vm.vfs_cache_pressure = 50
# Minimize disk I/O latency
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
EOF

sysctl --system

# 6. Snapper Instant Rollback Setup (Only if root filesystem is Btrfs)
if findmnt -n -o FSTYPE / | grep -q "btrfs"; then
    echo -e "\033[94m[*] Configuring Snapper for instant Btrfs rollbacks...\033[0m"
    if [ ! -f /etc/snapper/configs/root ]; then
        snapper -c root create-config /
    fi
    # Limit number of stored snapshots to conserve disk space
    sed -i 's/NUMBER_LIMIT="50"/NUMBER_LIMIT="5"/' /etc/snapper/configs/root
    sed -i 's/NUMBER_LIMIT_IMPORTANT="10"/NUMBER_LIMIT_IMPORTANT="3"/' /etc/snapper/configs/root
    systemctl enable --now snapper-cleanup.timer
    echo -e "\033[92m[✓] Snapper auto-cleanup configured.\033[0m"
else
    echo -e "\033[93m[!] Root filesystem is not Btrfs. Skipping Snapper config safely.\033[0m"
fi

echo -e "\n\033[92m====================================================\033[0m"
echo -e "\033[92m[✓] SUCCESS: 01_engine_setup.sh ready with ZERO ERRORS!\033[0m"
echo -e "\033[92m====================================================\033[0m"

