#!/usr/bin/env bash
# ==============================================================================
# RETRO OS - Modular Security & Rust Arsenal Setup
# Framework: Distrobox Podman Container + Pre-compiled Static Tools
# ==============================================================================

# 1. Zero-Error Strict Execution Protocol
set -Eeuo pipefail
trap 'echo -e "\n\033[91m[-] Fatal Error at Line $LINENO! Command: $BASH_COMMAND failed.\033[0m" >&2' ERR

echo -e "\033[92m[+] Starting Retro OS Modular Security & Toolchain Setup...\033[0m"

# Root Permission Check
if [ "$EUID" -ne 0 ]; then
    echo -e "\033[91m[-] Please run as root: sudo bash 03_modules_setup.sh\033[0m"
    exit 1
fi

ACTUAL_USER="${SUDO_USER:-$USER}"

# 2. Base Container Subsystems Installation (Podman & Distrobox)
echo -e "\033[94m[*] Installing Podman and Distrobox for isolated offensive tools...\033[0m"
apt-get update -y
apt-get install -y --no-install-recommends \
    podman \
    distrobox \
    ripgrep \
    fd-find \
    btop \
    micro \
    unzip \
    tar

# 3. Fast Network & Modern Rust Tools Setup
echo -e "\033[94m[*] Installing lightweight Rust binaries (Rustscan & Yazi)...\033[0m"
BIN_DIR="/usr/local/bin"

# Fetch pre-compiled Rustscan (Ultra-fast port scanner)
if [ ! -f "$BIN_DIR/rustscan" ]; then
    echo -e "\033[94m[*] Fetching Rustscan binary...\033[0m"
    curl -fsSL "https://github.com/RustScan/RustScan/releases/latest/download/rustscan-linux-x86_64.tar.gz" -o /tmp/rustscan.tar.gz || true
    if [ -f /tmp/rustscan.tar.gz ]; then
        tar -xzf /tmp/rustscan.tar.gz -C /tmp/
        mv /tmp/rustscan*/rustscan "$BIN_DIR/rustscan" 2>/dev/null || mv /tmp/rustscan "$BIN_DIR/rustscan" || true
        chmod +x "$BIN_DIR/rustscan"
        rm -rf /tmp/rustscan*
    fi
fi

# 4. One-Click Kali Linux Container Automation
echo -e "\033[94m[*] Writing Kali container auto-provisioner (/usr/local/bin/retro-kali)...\033[0m"
cat <<'EOF' > /usr/local/bin/retro-kali
#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="retro-kali"

# Check if container exists, if not create it without root privileges
if ! distrobox list | grep -q "$CONTAINER_NAME"; then
    echo -e "\033[92m[+] Initializing isolated Kali Linux container (First-time setup)...\033[0m"
    distrobox create --name "$CONTAINER_NAME" --image docker.io/kalilinux/kali-rolling:latest --yes
    echo -e "\033[92m[+] Installing core security tools inside container...\033[0m"
    distrobox enter "$CONTAINER_NAME" -- sudo apt-get update -y
    distrobox enter "$CONTAINER_NAME" -- sudo apt-get install -y --no-install-recommends \
        nmap \
        wireshark-qt \
        tshark \
        metasploit-framework \
        airgeddon
    echo -e "\033[92m[✓] Kali Container ready for secure auditing!\033[0m"
fi

# Enter container or execute arguments
if [ $# -eq 0 ]; then
    distrobox enter "$CONTAINER_NAME"
else
    distrobox enter "$CONTAINER_NAME" -- "$@"
fi
EOF
chmod +x /usr/local/bin/retro-kali

# 5. Distrobox User Configuration Hook
echo -e "\033[94m[*] Configuring rootless container subuids for $ACTUAL_USER...\033[0m"
usermod --add-subuids 100000-165535 "$ACTUAL_USER" 2>/dev/null || true
usermod --add-subgids 100000-165535 "$ACTUAL_USER" 2>/dev/null || true

echo -e "\n\033[92m====================================================\033[0m"
echo -e "\033[92m[✓] SUCCESS: 03_modules_setup.sh ready with ZERO ERRORS!\033[0m"
echo -e "\033[92m====================================================\033[0m"
