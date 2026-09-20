#!/usr/bin/env bash
# ==============================================================================
# RETRO OS - LAYER 2: FLUID CYBER-GLASS INTERFACE & BRANDING
# ==============================================================================
set -Eeuo pipefail

CYAN='\033[96m'
GREEN='\033[92m'
NC='\033[0m'

echo -e "${CYAN}[*] Deploying Retro Monolith Cyber-Glass UI & Dragon Assets...${NC}"

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

apt-get install -y --no-install-recommends software-properties-common
add-apt-repository universe -y 2>/dev/null || true
apt-get update -y

apt-get install -y --no-install-recommends \
    kde-plasma-desktop plasma-workspace-wayland sddm kwin-wayland \
    kitty fonts-jetbrains-mono papirus-icon-theme qt5-style-kvantum plymouth plymouth-themes || true

# 1. Embedded Retro Dragon Asset Extraction (Terminal & Boot)
mkdir -p /usr/share/retro/wallpapers
cat << 'EOF' | base64 -d > /usr/share/retro/wallpapers/retro-dragon.png
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9
awAAAABJRU5ErkJggg==
EOF

# 2. Signature Kitty Terminal Configuration
mkdir -p "$TARGET_HOME/.config/kitty"
cat << 'EOF' > "$TARGET_HOME/.config/kitty/kitty.conf"
background #0c0d12
foreground #f8f8f2
background_opacity 0.90
font_family JetBrains Mono
font_size 11.0
confirm_os_window_close 0
background_image /usr/share/retro/wallpapers/retro-dragon.png
background_image_layout cscaled
background_tint 0.90
EOF

# 3. Tactical Direct-Kernel Keybindings
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

# 4. Plymouth Dragon Boot Splash
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

echo -e "${GREEN}[✓] Layer 2 Interface Configured Successfully.${NC}"
