#!/usr/bin/env bash
# ==============================================================================
# RETRO OS - Master Hybrid ISO Image Builder
# ==============================================================================
set -Eeuo pipefail

echo -e "\033[96m[*] Initializing Retro OS ISO Production Engine...\033[0m"

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
btop
ripgrep
micro
nmap
podman
distrobox
calamares
EOF

# Copy repository scripts into Target Root
mkdir -p config/includes.chroot/opt/retro-os
cp -r "$OLDPWD"/* config/includes.chroot/opt/retro-os/ || true

# Install System-wide CLI
mkdir -p config/includes.chroot/usr/local/bin
if [ -f "$OLDPWD/retro" ]; then
    cp "$OLDPWD/retro" config/includes.chroot/usr/local/bin/retro
    chmod +x config/includes.chroot/usr/local/bin/retro
fi

echo -e "\033[92m[*] Packaging Retro OS ISO (SquashFS Compression Active)...\033[0m"
lb build

mv live-image-amd64.hybrid.iso "$OLDPWD/RetroOS-Standalone-1.0-x86_64.iso"
echo -e "\033[92m[✓] SUCCESS: RetroOS-Standalone-1.0-x86_64.iso generated successfully!\033[0m"
