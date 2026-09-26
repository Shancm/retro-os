#!/usr/bin/env bash
# =============================================================================
# Retro OS v1.0 - 01_engine_setup.sh
# Kernel/system engine layer: ZRAM, EarlyOOM, sysctl tuning, Btrfs/Snapper.
# =============================================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=./config.env
source "${SCRIPT_DIR}/config.env"

require_root

trap 'retro_error "01_engine_setup.sh failed at line ${LINENO} (exit ${?})."' ERR

retro_info "=== [1/3] Engine Setup: ZRAM / EarlyOOM / sysctl / Btrfs-Snapper ==="

# -----------------------------------------------------------------------------
# 1. Package prerequisites
# -----------------------------------------------------------------------------
retro_info "Installing engine dependencies..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq \
    zram-tools \
    earlyoom \
    linux-tools-common \
    util-linux \
    procps >/dev/null

retro_ok "Base engine packages installed."

# -----------------------------------------------------------------------------
# 2. ZRAM with ZSTD compression, sized to 50% of RAM (idempotent)
# -----------------------------------------------------------------------------
retro_info "Configuring ZRAM (zstd, 50% RAM)..."

ZRAM_CONF="/etc/default/zramswap"
if [[ -f "${ZRAM_CONF}" ]]; then
    cp -a "${ZRAM_CONF}" "${ZRAM_CONF}.bak.$(date +%s)" 2>/dev/null || true
fi

cat > "${ZRAM_CONF}" << 'ZCONF'
# Managed by Retro OS - 01_engine_setup.sh
ALGO=zstd
PERCENT=50
PRIORITY=100
ZCONF

if is_command systemctl; then
    systemctl enable --now zramswap.service >/dev/null 2>&1 || \
        retro_warn "zramswap.service could not be started (may be normal inside a chroot build)."
else
    retro_warn "systemctl not available (chroot build environment) - zramswap will activate on first real boot."
fi

retro_ok "ZRAM configured."

# -----------------------------------------------------------------------------
# 3. EarlyOOM anti-freeze daemon (idempotent config)
# -----------------------------------------------------------------------------
retro_info "Configuring EarlyOOM anti-freeze daemon..."

EARLYOOM_CONF="/etc/default/earlyoom"
cat > "${EARLYOOM_CONF}" << 'EOOM'
# Managed by Retro OS - 01_engine_setup.sh
# Kill the biggest offending process before the system fully freezes.
EARLYOOM_ARGS="-r 60 -m 8 -s 8 --avoid '(^|/)(sshd|systemd|Xorg|kwin_wayland|plasmashell)$' -g"
EOOM

if is_command systemctl; then
    systemctl enable --now earlyoom.service >/dev/null 2>&1 || \
        retro_warn "earlyoom.service could not be started now; it will start on next boot."
fi

retro_ok "EarlyOOM configured."

# -----------------------------------------------------------------------------
# 4. Low-latency sysctl performance tweaks (idempotent - single managed block)
# -----------------------------------------------------------------------------
retro_info "Applying low-latency sysctl tweaks..."

SYSCTL_FILE="/etc/sysctl.d/99-retro-os-performance.conf"
cat > "${SYSCTL_FILE}" << 'SYSCTL'
# Managed by Retro OS - 01_engine_setup.sh
# Low-latency / desktop-responsiveness tuning

# Reduce swappiness since ZRAM absorbs most swap pressure cheaply
vm.swappiness=100
vm.page-cluster=0
vm.vfs_cache_pressure=50

# Reduce write-back latency spikes
vm.dirty_ratio=10
vm.dirty_background_ratio=5

# Scheduler responsiveness (autogroup helps desktop interactivity)
kernel.sched_autogroup_enabled=1

# Network snappiness for tactical/field use
net.ipv4.tcp_fastopen=3
net.core.default_qdisc=fq
SYSCTL

if is_command sysctl; then
    sysctl --system >/dev/null 2>&1 || retro_warn "sysctl --system failed to apply live (normal in chroot); will apply on boot."
fi

retro_ok "sysctl tuning written to ${SYSCTL_FILE}."

# -----------------------------------------------------------------------------
# 5. Btrfs + Snapper rollback support (GUARDED - only runs on genuine Btrfs)
# -----------------------------------------------------------------------------
retro_info "Checking root filesystem type before enabling Snapper..."

if is_btrfs_root; then
    retro_ok "Root filesystem is Btrfs - configuring Snapper rollback support."

    apt-get install -y -qq snapper btrfs-progs grub-btrfs inotify-tools >/dev/null

    if [[ ! -e /etc/snapper/configs/root ]]; then
        # snapper create-config fails if a snapper subvolume layout doesn't
        # already exist; guard so a re-run never crashes.
        if snapper -c root create-config / 2>/dev/null; then
            retro_ok "Snapper 'root' config created."
        else
            retro_warn "Snapper create-config skipped (already configured or unsupported layout)."
        fi
    else
        retro_info "Snapper 'root' config already exists - skipping."
    fi

    if [[ -f /etc/snapper/configs/root ]]; then
        sed -i \
            -e 's/^TIMELINE_CREATE=.*/TIMELINE_CREATE="yes"/' \
            -e 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/' \
            -e 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/' \
            -e 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="2"/' \
            -e 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="0"/' \
            /etc/snapper/configs/root 2>/dev/null || true
    fi

    if is_command systemctl; then
        systemctl enable --now snapper-timeline.timer snapper-cleanup.timer >/dev/null 2>&1 || \
            retro_warn "Snapper timers could not be started now; will activate on next boot."
    fi

    if is_command update-grub && dpkg -l | grep -q grub-btrfs; then
        update-grub >/dev/null 2>&1 || retro_warn "update-grub failed (normal in a chroot build)."
    fi

    retro_ok "Btrfs/Snapper rollback support configured."
else
    retro_warn "Root filesystem is NOT Btrfs - skipping Snapper setup entirely (no crash, by design)."
fi

retro_ok "=== Engine setup complete. ==="
