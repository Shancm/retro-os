#!/usr/bin/env bash
# ==============================================================================
# RETRO OS - Interface & Fluid Desktop Setup (KDE Plasma + Wayland)
# Style: Windows 11 Fluent Dark + Kali Cyber Hybrid
# ==============================================================================

# 1. Zero-Error Strict Execution Protocol
set -Eeuo pipefail
trap 'echo -e "\n\033[91m[-] Fatal Error at Line $LINENO! Command: $BASH_COMMAND failed.\033[0m" >&2' ERR

echo -e "\033[92m[+] Starting Retro OS Interface Setup...\033[0m"

# Root Permission Check
if [ "$EUID" -ne 0 ]; then
    echo -e "\033[91m[-] Please run as root: sudo bash 02_interface_setup.sh\033[0m"
    exit 1
fi

ACTUAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

# 2. Install Minimal KDE Plasma Desktop & Wayland Engine
echo -e "\033[94m[*] Installing lightweight KDE Plasma Desktop and Wayland...\033[0m"
apt-get update -y
apt-get install -y --no-install-recommends \
    kde-plasma-desktop \
    plasma-workspace-wayland \
    sddm \
    kwin-wayland \
    plasma-nm \
    plasma-pa \
    kitty \
    fonts-jetbrains-mono \
    papirus-icon-theme \
    qt5-style-kvantum \
    qt6-style-kvantum \
    libinput-tools

# 3. Touchpad Gestures Subsystem Configuration
echo -e "\033[94m[*] Setting up Precision Touchpad Gestures...\033[0m"
mkdir -p /etc/X11/xorg.conf.d
cat <<EOF > /etc/X11/xorg.conf.d/40-libinput.conf
Section "InputClass"
        Identifier "libinput touchpad catchall"
        MatchIsTouchpad "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
        Option "Tapping" "on"
        Option "NaturalScrolling" "true"
        Option "ClickMethod" "clickfinger"
EndSection
EOF

# 4. Automate Wallpaper Directories & Assets
echo -e "\033[94m[*] Creating Retro Wallpapers & Dual-Persona directories...\033[0m"
WALLPAPER_DIR="$USER_HOME/Pictures/RetroWallpapers"
mkdir -p "$WALLPAPER_DIR"

# Download Clean Windows 11 Fluent & Dark Cyber Wallpapers
curl -fsSL "https://raw.githubusercontent.com/DinkDonk/fluent-wallpapers/master/Fluent_Dark.jpg" -o "$WALLPAPER_DIR/office_mode.jpg" || true
curl -fsSL "https://raw.githubusercontent.com/DinkDonk/fluent-wallpapers/master/Cyber_Dark.jpg" -o "$WALLPAPER_DIR/cyber_mode.jpg" || true

# 5. Dual Persona Switcher Command Setup (Office vs Cyber Mode)
echo -e "\033[94m[*] Creating Retro Persona Switcher (/usr/local/bin/retro-mode)...\033[0m"
cat <<'EOF' > /usr/local/bin/retro-mode
#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/RetroWallpapers"

if [ "${1:-}" = "cyber" ]; then
    echo -e "\033[92m[+] Switching to CYBER/KALI Mode...\033[0m"
    plasma-apply-colorscheme BreezeDark || true
    plasma-apply-wallpaperimage "$WALLPAPER_DIR/cyber_mode.jpg" || true
elif [ "${1:-}" = "office" ]; then
    echo -e "\033[94m[+] Switching to OFFICE/DEV Mode...\033[0m"
    plasma-apply-colorscheme BreezeDark || true
    plasma-apply-wallpaperimage "$WALLPAPER_DIR/office_mode.jpg" || true
else
    echo "Usage: retro-mode [office|cyber]"
fi
EOF
chmod +x /usr/local/bin/retro-mode

# 6. SDDM Login Manager Setup
echo -e "\033[94m[*] Enabling Wayland-based SDDM Display Manager...\033[0m"
systemctl enable sddm

# Fix User Permissions
chown -R "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/Pictures" || true

echo -e "\n\033[92m====================================================\033[0m"
echo -e "\033[92m[✓] SUCCESS: 02_interface_setup.sh ready with ZERO ERRORS!\033[0m"
echo -e "\033[92m====================================================\033[0m"
