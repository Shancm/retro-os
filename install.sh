#!/usr/bin/env bash
# ==============================================================================
# RETRO OS - Master Automated Deployment Engine
# Executes Phase 1, Phase 2, and Phase 3 sequentially with Zero Errors.
# ==============================================================================

set -Eeuo pipefail
trap 'echo -e "\n\033[91m[-] Deployment aborted at Line $LINENO! Command: $BASH_COMMAND failed.\033[0m" >&2' ERR

# Terminal Colors
GREEN="\033[92m"
BLUE="\033[94m"
YELLOW="\033[93m"
RED="\033[91m"
CYAN="\033[96m"
BOLD="\033[1m"
RESET="\033[0m"

echo -e "${CYAN}${BOLD}"
echo "===================================================="
echo "          RETRO OS MASTER INSTALLER                 "
echo "    Lightweight, High-Performance Security OS       "
echo "===================================================="
echo -e "${RESET}"

# 1. Root Permission Check
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[-] Error: This master installer must be run as root.${RESET}"
    echo -e "${YELLOW}[*] Usage: sudo bash install.sh${RESET}"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. Permissions Setup
echo -e "${BLUE}[*] Granting execution permissions to all setup scripts...${RESET}"
chmod +x "$SCRIPT_DIR"/01_engine_setup.sh
chmod +x "$SCRIPT_DIR"/02_interface_setup.sh
chmod +x "$SCRIPT_DIR"/03_modules_setup.sh
[ -f "$SCRIPT_DIR/retro" ] && chmod +x "$SCRIPT_DIR/retro"

# 3. Execution Pipeline
echo -e "\n${YELLOW}>>> [1/3] EXECUTING CORE ENGINE SETUP (ZRAM, Snapper, EarlyOOM)...${RESET}"
bash "$SCRIPT_DIR/01_engine_setup.sh"

echo -e "\n${YELLOW}>>> [2/3] EXECUTING INTERFACE SETUP (KDE Plasma, Fluent Theme, Wallpapers)...${RESET}"
bash "$SCRIPT_DIR/02_interface_setup.sh"

echo -e "\n${YELLOW}>>> [3/3] EXECUTING SECURITY & MODULES (Distrobox, Rust Toolchain)...${RESET}"
bash "$SCRIPT_DIR/03_modules_setup.sh"

# 4. Global CLI Linking
if [ -f "$SCRIPT_DIR/retro" ]; then
    echo -e "\n${BLUE}[*] Installing 'retro' master CLI to /usr/local/bin/retro...${RESET}"
    cp "$SCRIPT_DIR/retro" /usr/local/bin/retro
    chmod +x /usr/local/bin/retro
    echo -e "${GREEN}[✓] 'retro' CLI command is now available system-wide!${RESET}"
fi

# 5. Completion & Reboot Prompt
echo -e "\n${GREEN}${BOLD}"
echo "===================================================="
echo "    [✓] RETRO OS DEPLOYMENT COMPLETED (ZERO ERRORS) "
echo "===================================================="
echo -e "${RESET}"
echo -e "${BLUE}[*] All core engine modules, UI themes, and toolchains are deployed.${RESET}"
echo -e "${YELLOW}[!] A system reboot is strongly recommended to apply kernel parameters and start SDDM.${RESET}\n"

read -rp "Do you want to reboot the system now? (y/n): " REBOOT_CHOICE
if [[ "$REBOOT_CHOICE" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}[+] Rebooting into Retro OS...${RESET}"
    reboot
else
    echo -e "${BLUE}[*] Manual reboot required. Run 'sudo reboot' when ready.${RESET}"
fi
