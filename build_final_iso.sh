#!/usr/bin/env bash
# ==============================================================================
# RETRO OS - Production Live ISO Builder (Fully Automated)
# ==============================================================================
set -Eeuo pipefail

echo -e "\033[96m[*] Initializing Retro OS Production Builder...\033[0m"

if [ "$EUID" -ne 0 ]; then
    echo -e "\033[91m[!] Execute with sudo: sudo bash build_final_iso.sh\033[0m"
    exit 1
fi

apt-get update -y
apt-get install -y live-build debootstrap squashfs-tools xorriso btrfs-progs

BUILD_DIR="/tmp/retro-iso-dist"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

lb config \
    --distribution noble \
    --architectures amd64 \
    --archive-areas "main restricted universe multiverse" \
    --bootloader grub-efi \
    --linux-packages "linux-image-generic" \
    --firmware-binary true \
    --security true

mkdir -p config/package-lists
cat << 'EOF' > config/package-lists/retro.list.chroot
linux-image-generic
linux-firmware
ubuntu-drivers-common
wireless-tools
wpasupplicant
network-manager
network-manager-gnome
kde-plasma-desktop
plasma-workspace-wayland
sddm
kwin-wayland
btrfs-progs
snapper
zram-tools
earlyoom
kitty
yakuake
fonts-jetbrains-mono
papirus-icon-theme
btop
ripgrep
micro
nmap
podman
distrobox
calamares
qml-module-qtquick2
aircrack-ng
ethtool
pciutils
usbutils
xdotool
xclip
imagemagick
curl
git
jq
ufw
tor
obfs4proxy
wireguard
EOF

# 1. സ്ക്രിപ്റ്റുകൾ ചറൂട്ടിലേക്ക് കോപ്പി ചെയ്യുന്നു
mkdir -p config/includes.chroot/opt/retro-os
cp -r "$OLDPWD"/* config/includes.chroot/opt/retro-os/ || true

# 2. retro CLI ബൈനറി സിസ്റ്റത്തിലേക്ക് കോപ്പി ചെയ്യുന്നു
mkdir -p config/includes.chroot/usr/local/bin
if [ -f "$OLDPWD/retro" ]; then
    cp "$OLDPWD/retro" config/includes.chroot/usr/local/bin/retro
    chmod +x config/includes.chroot/usr/local/bin/retro
fi

# 3. ISO നിർമ്മാണ വേളയിൽ സിസ്റ്റം സെറ്റപ്പ് സ്ക്രിപ്റ്റുകൾ റൺ ചെയ്യാനുള്ള Hook
mkdir -p config/hooks/live
cat << 'EOF' > config/hooks/live/01-setup-retro.chroot
#!/bin/bash
set -e
cd /opt/retro-os
bash 01_engine_setup.sh
bash 02_interface_setup.sh
bash 03_modules_setup.sh
bash setup_calamares.sh
chmod +x /usr/local/bin/retro
EOF
chmod +x config/hooks/live/01-setup-retro.chroot

echo -e "\033[92m[*] Packaging Fast Hybrid ISO with ZSTD...\033[0m"
lb build

mv live-image-amd64.hybrid.iso "$OLDPWD/RetroOS-1.0-Production-x86_64.iso"
echo -e "\033[92m[✓] SUCCESS: RetroOS-1.0-Production-x86_64.iso generated successfully!\033[0m"
