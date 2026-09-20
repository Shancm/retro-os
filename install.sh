#!/usr/bin/env bash
set -Eeuo pipefail

echo -e "\033[96m[*] INITIATING COMPLETE RETRO OS STABILIZATION DEPLOYMENT...\033[0m"

sudo bash 01_engine_setup.sh
sudo bash 02_interface_setup.sh
sudo bash 03_modules_setup.sh

if [ -f "./retro" ]; then
    sudo install -m 755 ./retro /usr/local/bin/retro
    sudo chmod +x /usr/local/bin/retro
fi

echo -e "\033[92m[✓] RETRO OS DEPLOYED SUCCESSFULLY. READY FOR PRODUCTION.\033[0m"
