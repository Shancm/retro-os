#!/usr/bin/env bash
# =============================================================================
# Retro OS v1.0 - 03_modules_setup.sh
# Rootless Podman/Distrobox, UFW firewall, Tor, WireGuard, modern CLI tools.
# =============================================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=./config.env
source "${SCRIPT_DIR}/config.env"

require_root

trap 'retro_error "03_modules_setup.sh failed at line ${LINENO} (exit ${?})."' ERR

retro_info "=== [3/3] Modules Setup: Podman / Distrobox / UFW / Tor / WireGuard / CLI ==="

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq

# -----------------------------------------------------------------------------
# 1. Rootless Podman + Distrobox
# -----------------------------------------------------------------------------
retro_info "Installing rootless Podman and Distrobox..."
apt-get install -y -qq \
    podman \
    uidmap \
    slirp4netns \
    fuse-overlayfs \
    dbus-user-session \
    curl >/dev/null

# Distrobox has no apt package on some bases; install via official script,
# falling back to apt if it exists in the repo.
if apt-cache show distrobox >/dev/null 2>&1; then
    apt-get install -y -qq distrobox >/dev/null
else
    curl -fsSL https://raw.githubusercontent.com/89luca89/distrobox/main/install \
        -o /tmp/distrobox-install.sh
    bash /tmp/distrobox-install.sh --prefix /usr/local >/dev/null
    rm -f /tmp/distrobox-install.sh
fi

# Ensure subuid/subgid ranges exist for rootless containers (idempotent)
if [[ "${TARGET_USER}" != "root" ]] && id "${TARGET_USER}" &>/dev/null; then
    grep -q "^${TARGET_USER}:" /etc/subuid 2>/dev/null || \
        usermod --add-subuids 100000-165535 "${TARGET_USER}" 2>/dev/null || true
    grep -q "^${TARGET_USER}:" /etc/subgid 2>/dev/null || \
        usermod --add-subgids 100000-165535 "${TARGET_USER}" 2>/dev/null || true
fi

retro_ok "Podman (rootless) and Distrobox installed."

# -----------------------------------------------------------------------------
# 2. UFW firewall - default deny incoming, allow outgoing
# -----------------------------------------------------------------------------
retro_info "Configuring UFW firewall (default-deny incoming)..."
apt-get install -y -qq ufw >/dev/null

ufw --force reset >/dev/null 2>&1 || true
ufw default deny incoming >/dev/null 2>&1 || retro_warn "ufw default deny incoming failed (chroot, no kernel netfilter - normal)."
ufw default allow outgoing >/dev/null 2>&1 || true
ufw allow ssh >/dev/null 2>&1 || true

if is_command systemctl; then
    systemctl enable ufw.service >/dev/null 2>&1 || true
fi
# Do not force-enable ufw inside a chroot (no netfilter available at build time)
if [[ -d /run/systemd/system ]] && [[ "${RETRO_CHROOT_BUILD:-0}" != "1" ]]; then
    ufw --force enable >/dev/null 2>&1 || retro_warn "ufw enable deferred to first real boot."
else
    retro_warn "Chroot/build environment detected - UFW will enable on first real boot."
fi

retro_ok "UFW firewall configured."

# -----------------------------------------------------------------------------
# 3. Tor ghost daemon + WireGuard
# -----------------------------------------------------------------------------
retro_info "Installing Tor and WireGuard..."
apt-get install -y -qq tor torsocks wireguard wireguard-tools resolvconf >/dev/null

if is_command systemctl; then
    systemctl disable tor.service >/dev/null 2>&1 || true
    systemctl stop tor.service >/dev/null 2>&1 || true
fi
retro_info "Tor installed but disabled by default (toggle via 'retro ghost')."

retro_ok "Tor and WireGuard installed."

# -----------------------------------------------------------------------------
# 4. Modern CLI tools
# -----------------------------------------------------------------------------
retro_info "Installing modern CLI toolkit (btop, ripgrep, micro, nmap, etc)..."
apt-get install -y -qq \
    btop \
    ripgrep \
    micro \
    nmap \
    fzf \
    fd-find \
    bat \
    htop \
    tmux \
    jq \
    net-tools \
    rsync \
    unzip \
    >/dev/null

retro_ok "Modern CLI toolkit installed."

apt-get autoremove -y -qq >/dev/null 2>&1 || true
apt-get clean -qq >/dev/null 2>&1 || true

retro_ok "=== Modules setup complete. ==="
