#!/usr/bin/env bash
# ==============================================================================
# RETRO OS - LAYER 2: HYBRID GUI / CLI & BRANDING
# ==============================================================================
set -Eeuo pipefail

CYAN='\033[96m'
GREEN='\033[92m'
RED='\033[91m'
NC='\033[0m'

echo -e "${CYAN}[*] Deploying Retro Hybrid Interface (KDE + Retro Terminal)...${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Execute with sudo: sudo bash 02_interface_setup.sh${NC}"
    exit 1
fi

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

export DEBIAN_FRONTEND=noninteractive
apt-get install -y --no-install-recommends software-properties-common
add-apt-repository universe -y 2>/dev/null || true
apt-get update -y

apt-get install -y --no-install-recommends \
    kde-plasma-desktop plasma-workspace-wayland sddm kwin-wayland \
    kitty yakuake fonts-jetbrains-mono papirus-icon-theme \
    xdotool plymouth plymouth-themes jq || true

# 1. Directories
mkdir -p /usr/share/retro/wallpapers
mkdir -p /usr/share/retro/themes
mkdir -p /etc/skel/.config/retro-terminal
mkdir -p "$TARGET_HOME/.config/retro-terminal"
mkdir -p /etc/skel/.config/autostart
mkdir -p "$TARGET_HOME/.config/autostart"

# 2. Retro Terminal Configuration (Kitty backend)
cat << 'EOF' | tee "$TARGET_HOME/.config/retro-terminal/retro-term.conf" > /etc/skel/.config/retro-terminal/retro-term.conf
font_family      JetBrains Mono
font_size        11.0
window_padding_width 12
confirm_os_window_close 0
enable_audio_bell no

background #0c0d12
foreground #d8dee9
background_opacity 0.88
dynamic_background_opacity yes

cursor #00e5ff
cursor_text_color #0c0d12
cursor_shape beam
selection_foreground #0c0d12
selection_background #00e5ff

color0 #1b1e28
color8 #282c3c
color1 #ff0055
color9 #ff2a6d
color2 #05ffa1
color10 #05ffa1
color3 #ffbe0b
color11 #ffe066
color4 #00e5ff
color12 #05d9e8
color5 #b967ff
color13 #d68cff
color6 #01c5c4
color14 #67e8f9
color7 #e2e8f0
color15 #f8fafc
EOF

# 3. Binary Wrappers
cat << 'EOF' > /usr/local/bin/retro-term
#!/usr/bin/env bash
exec kitty --config "$HOME/.config/retro-terminal/retro-term.conf" --class "retro-term" "$@"
EOF
chmod +x /usr/local/bin/retro-term

# 4. Global Keybindings
mkdir -p "$TARGET_HOME/.config"
mkdir -p /etc/skel/.config

cat << 'EOF' | tee "$TARGET_HOME/.config/kglobalshortcutsrc" > /etc/skel/.config/kglobalshortcutsrc
[retro-terminal.desktop]
_k_friendly_name=Retro Terminal
_launch=Meta+Return,none,Launch Retro Terminal

[retro-kali.desktop]
_k_friendly_name=Retro Kali Sandbox
_launch=Meta+K,none,Launch Retro Kali

[retro-mon.desktop]
_k_friendly_name=Retro Telemetry HUD
_launch=Meta+M,none,Launch Retro HUD

[org.kde.krunner.desktop]
_k_friendly_name=App Launcher
_launch=Meta+Space,none,KRunner

[retro-panic.desktop]
_k_friendly_name=Retro Panic Button
_launch=Ctrl+Alt+Delete,none,Retro Panic
EOF

# 5. Mode Switcher (Office / Cyber)
cat << 'EOF' > /usr/local/bin/retro-mode
#!/usr/bin/env bash
MODE="${1:-}"

if [ "$MODE" = "cyber" ]; then
    echo -e "\033[96m[*] Activating RETRO CYBER MODE...\033[0m"
    kwriteconfig5 --file kdeglobals --group General --key AccentColor "#00e5ff" 2>/dev/null || true
    qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
    echo -e "\033[92m[✓] Cyber Workspace Active.\033[0m"
elif [ "$MODE" = "office" ]; then
    echo -e "\033[93m[*] Activating RETRO OFFICE MODE...\033[0m"
    kwriteconfig5 --file kdeglobals --group General --key AccentColor "#3daee9" 2>/dev/null || true
    qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
    echo -e "\033[92m[✓] Office Workspace Active.\033[0m"
else
    echo "Usage: retro-mode [office|cyber]"
fi
EOF
chmod +x /usr/local/bin/retro-mode

# 6. Applications Menu Entries
mkdir -p /usr/share/applications

cat << 'EOF' > /usr/share/applications/retro-terminal.desktop
[Desktop Entry]
Name=Retro Terminal
Comment=Tactical Terminal
Exec=/usr/local/bin/retro-term
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
EOF

cat << 'EOF' > /usr/share/applications/retro-kali.desktop
[Desktop Entry]
Name=Retro Kali Bay
Comment=Isolated Kali Pentesting Tools
Exec=/usr/local/bin/retro-term -e retro kali
Icon=security-high
Terminal=false
Type=Application
Categories=Development;Security;
EOF

cat << 'EOF' > /usr/share/applications/retro-mon.desktop
[Desktop Entry]
Name=Retro Telemetry HUD
Comment=Retro OS Hardware Monitor
Exec=/usr/local/bin/retro-term -e retro mon
Icon=utilities-system-monitor
Terminal=false
Type=Application
Categories=System;Monitor;
EOF

cat << 'EOF' > /usr/share/applications/retro-panic.desktop
[Desktop Entry]
Name=Retro Panic Trigger
Exec=retro panic
Terminal=false
Type=Application
NoDisplay=true
EOF

# Yakuake Autostart (F12 Quake Terminal)
cat << 'EOF' | tee "$TARGET_HOME/.config/autostart/yakuake.desktop" > /etc/skel/.config/autostart/yakuake.desktop
[Desktop Entry]
Name=Yakuake
Exec=yakuake
Terminal=false
Type=Application
StartupNotify=false
EOF

chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config" 2>/dev/null || true

echo -e "${GREEN}[✓] Layer 2 Interface Configured Successfully.${NC}"
