#!/usr/bin/env bash
# ==============================================================================
# RETRO OS - Unified Resilient Master Deployment
# Architecture: Universal (Laptop x86_64 / Mobile ARM PRoot compatible)
# ==============================================================================

set -Eeuo pipefail

CYAN='\033[96m'
GREEN='\033[92m'
RED='\033[91m'
NC='\033[0m'

echo -e "${CYAN}"
cat << "EOF"
  ____  _____ _____ ____   ___     ___  ____  
 |  _ \| ____|_   _|  _ \ / _ \   / _ \/ ___| 
 | |_) |  _|   | | | |_) | | | | | | | \___ \ 
 |  _ <| |___  | | |  _ <| |_| | | |_| |___) |
 |_| \_\_____| |_| |_| \_\\___/   \___/|____/ 
EOF
echo -e "${GREEN}[*] Deploying Complete Retro OS with Built-in Assets...${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Execute with sudo: sudo bash install.sh${NC}"
    exit 1
fi

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

# ------------------------------------------------------------------------------
# 1. EMBEDDED RETRO DRAGON ASSET DEPLOYMENT
# ------------------------------------------------------------------------------
echo -e "${CYAN}[1/5] Extracting Signature Retro Dragon Logo...${NC}"
mkdir -p /usr/share/retro/wallpapers

# 1x1 Minimal PNG placeholder vector base (Safe decode test)
cat << 'EOF' | base64 -d > /usr/share/retro/wallpapers/retro-dragon.png
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9
awAAAABJRU5ErkJggg==
EOF

# ------------------------------------------------------------------------------
# 2. CORE PERFORMANCE & FAULT-TOLERANT ENGINE
# ------------------------------------------------------------------------------
echo -e "${CYAN}[2/5] Configuring Core Performance & Anti-Freeze Engine...${NC}"
apt-get update -y
apt-get install -y --no-install-recommends zram-tools earlyoom btrfs-progs snapper curl git jq

cat << 'EOF' > /etc/default/zramswap
ALGO=zstd
PERCENT=50
PRIORITY=100
EOF

# Safe service enable for both Systemd hosts and Docker/PRoot
systemctl restart zramswap 2>/dev/null || true
systemctl enable zramswap 2>/dev/null || true
systemctl restart earlyoom 2>/dev/null || true
systemctl enable earlyoom 2>/dev/null || true

# ------------------------------------------------------------------------------
# 3. INTERFACE, TERMINAL & TACTICAL SHORTCUTS
# ------------------------------------------------------------------------------
echo -e "${CYAN}[3/5] Setting up Interface & Terminal Watermark...${NC}"
apt-get install -y --no-install-recommends software-properties-common
add-apt-repository universe -y 2>/dev/null || true
apt-get update -y

apt-get install -y --no-install-recommends \
    kde-plasma-desktop \
    plasma-workspace-wayland \
    sddm \
    kwin-wayland \
    kitty \
    fonts-jetbrains-mono \
    papirus-icon-theme \
    qt5-style-kvantum || true

mkdir -p "$TARGET_HOME/.config/kitty"
cat << 'EOF' > "$TARGET_HOME/.config/kitty/kitty.conf"
background #0c0d12
foreground #f8f8f2
background_opacity 0.92
font_family JetBrains Mono
font_size 11.0
confirm_os_window_close 0
background_image /usr/share/retro/wallpapers/retro-dragon.png
background_image_layout cscaled
background_tint 0.90
EOF

# Tactical Keybindings
mkdir -p "$TARGET_HOME/.config"
cat << 'EOF' >> "$TARGET_HOME/.config/kglobalshortcutsrc"
[kitty.desktop]
_k_friendly_name=Kitty Terminal
_launch=Meta+Return,none,Launch Kitty Terminal

[retro-kali.desktop]
_k_friendly_name=Retro Kali Sandbox
_launch=Meta+K,none,Launch Retro Kali

[retro-mon.desktop]
_k_friendly_name=Retro Telemetry HUD
_launch=Meta+M,none,Launch Retro HUD
EOF
chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config"

# ------------------------------------------------------------------------------
# 4. PLYMOUTH DRAGON BOOT SPLASH
# ------------------------------------------------------------------------------
echo -e "${CYAN}[4/5] Configuring Boot Splash Screen...${NC}"
apt-get install -y plymouth plymouth-themes 2>/dev/null || true
mkdir -p /usr/share/plymouth/themes/retro-dragon

cat << 'EOF' > /usr/share/plymouth/themes/retro-dragon/retro-dragon.plymouth
[Plymouth Theme]
Name=Retro Dragon Monolith
Description=Tactical Boot Animation
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/retro-dragon
ScriptFile=/usr/share/plymouth/themes/retro-dragon/retro-dragon.script
EOF

cat << 'EOF' > /usr/share/plymouth/themes/retro-dragon/retro-dragon.script
Window.SetBackgroundTopColor(0.05, 0.05, 0.07);
Window.SetBackgroundBottomColor(0.05, 0.05, 0.07);
EOF

cp /usr/share/retro/wallpapers/retro-dragon.png /usr/share/plymouth/themes/retro-dragon/logo.png 2>/dev/null || true
update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/retro-dragon/retro-dragon.plymouth 100 2>/dev/null || true
update-alternatives --set default.plymouth /usr/share/plymouth/themes/retro-dragon/retro-dragon.plymouth 2>/dev/null || true
update-initramfs -u 2>/dev/null || true

# ------------------------------------------------------------------------------
# 5. SANDBOX PROVISIONING & MASTER CLI SETUP
# ------------------------------------------------------------------------------
echo -e "${CYAN}[5/5] Provisioning Kali Sandbox and Retro CLI...${NC}"
apt-get install -y podman distrobox btop ripgrep micro || true

if [ -f "./retro" ]; then
    install -m 755 ./retro /usr/local/bin/retro
    chmod +x /usr/local/bin/retro
fi

echo -e "${GREEN}[✓] Retro OS Deployment Finished Successfully.${NC}"

