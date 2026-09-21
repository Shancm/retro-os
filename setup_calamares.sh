#!/usr/bin/env bash
# ==============================================================================
# RETRO OS - Calamares GUI Installer Configuration
# ==============================================================================
set -Eeuo pipefail

echo -e "\033[96m[*] Configuring Calamares GUI Installer & Retro OS Theme...\033[0m"

sudo apt-get update -y
sudo apt-get install -y calamares calamares-settings-ubuntu qml-module-qtquick2

sudo mkdir -p /etc/calamares/branding/retro-os

sudo tee /etc/calamares/branding/retro-os/branding.desc > /dev/null << 'EOF'
---
componentName: retro-os
welcomeStyleCalamares: false
welcomeExpandingLogo: true
windowExpanding: normal
windowSize: 800px,520px

strings:
    productName:         "Retro OS"
    shortProductName:    "Retro"
    version:             "1.0-Tactical"
    shortVersion:        "1.0"
    versionedName:       "Retro OS Tactical Edition"
    shortVersionedName:  "Retro OS 1.0"
    bootloaderEntryName: "Retro OS"

images:
    productLogo:         "/usr/share/retro/wallpapers/retro-dragon.png"
    productIcon:         "/usr/share/retro/wallpapers/retro-dragon.png"
    productWelcome:      "/usr/share/retro/wallpapers/retro-dragon.png"

style:
   SidebarBackground:    "#0c0d12"
   SidebarText:          "#f8f8f2"
   SidebarTextSelect:    "#00e5ff"
   SidebarTextHighlight: "#ff0055"
EOF

sudo tee /etc/calamares/settings.conf > /dev/null << 'EOF'
---
modules-search: [ local ]

sequence:
    - show:
        - welcome
        - locale
        - keyboard
        - partition
        - users
        - summary
    - exec:
        - partition
        - mount
        - unpackfs
        - machineid
        - fstab
        - locale
        - keyboard
        - localecfg
        - users
        - networkcfg
        - packages
        - grubcfg
        - bootloader
        - umount
    - show:
        - finished

branding: retro-os
prompt-install: true
dont-chroot: false
EOF

echo -e "\033[92m[✓] Calamares Installer Configured Successfully.\033[0m"
