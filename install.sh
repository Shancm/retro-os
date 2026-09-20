#!/usr/bin/env bash
# ==============================================================================
# RETRO OS - Master Automated Deployment Engine
# Executes Phase 1, Phase 2, and Phase 3 sequentially with Zero Errors.
# ==============================================================================

set -Eeuo pipefail
trap 'echo -e "\n\033[91m[-] Deployment aborted at Line $LINENO! Command: $BASH_COMMAND failed.\033[0m" >&2' ERR

# Terminal Styling
GREEN="\033[92m"
BLUE="\033[94m"
YELLOW="\033[93m"
RED="\033[91m"
RESET="\033[0m"

echo -e "${GREEN}"
echo "===================================================="
echo "          RETRO OS MASTER INSTALLER                 "
echo "    Lightweight, High-Performance Security OS       "
echo "===================================================="
echo -e "${RESET}"

# 1. Root Check
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[-] Error: This master installer must be run as root.${RESET}"
    echo -e "${YELLOW}[*] Usage: sudo bash install.sh${RESET}"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. Permission Fix for all scripts
echo -e "${BLUE}[*] Setting executable permissions on setup scripts...${RESET}"
chmod +x "$SCRIPT_DIR"/01_engine_setup.sh
chmod +x "$SCRIPT_DIR"/02_interface_setup.sh
chmod +x "$SCRIPT_DIR"/03_modules_setup.sh

# 3. Execution Pipeline
echo -e "\n${YELLOW}>>> [1/3] EXECUTING CORE ENGINE SETUP (ZRAM, Snapper, Performance)...${RESET}"
bash "$SCRIPT_DIR/01_engine_setup.sh"

echo -e "\n${YELLOW}>>> [2/3] EXECUTING INTERFACE SETUP (KDE Plasma, Fluent Theme, Wallpapers)...${RESET}"
bash "$SCRIPT_DIR/02_interface_setup.sh"

echo -e "\n${YELLOW}>>> [3/3] EXECUTING SECURITY & MODULES (Distrobox, Rust Toolchain)...${RESET}"
bash "$SCRIPT_DIR/03_modules_setup.sh"

# 4. Final Success Confirmation
echo -e "\n${GREEN}"
echo "===================================================="
echo "    [✓] RETRO OS FULL INSTALLATION COMPLETED!       "
echo "===================================================="
echo -e "${RESET}"
echo -e "${BLUE}[*] All components deployed with ZERO ERRORS.${RESET}"
echo -e "${YELLOW}[!] A system reboot is strongly recommended to apply the new Wayland Compositor and Kernel parameters.${RESET}"
echo ""

read -rp "Do you want to reboot the system now? (y/n): " REBOOT_CHOICE
if [[ "$REBOOT_CHOICE" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}[+] Rebooting into Retro OS...${RESET}"
    reboot
else
    echo -e "${BLUE}[*] Installation finished. Please reboot manually when ready using 'sudo reboot'.${RESET}"
fi
