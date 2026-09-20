# ⚡ RETRO OS

> A lightweight, fault-tolerant, security-focused operating system architecture designed for medium-spec hardware.

---

## 🌟 Key Features

- **The Bulletproof Engine:** ZRAM with ZSTD compression expands effective RAM capacity (e.g., 8GB behaves like 12GB–14GB), while Btrfs + Snapper provides instant 5-second rollbacks via GRUB[span_1](start_span)[span_1](end_span).
- **Anti-Freeze Protection:** EarlyOOM daemon protects the desktop from freezes by terminating unresponsive memory hogs before exhaustion[span_2](start_span)[span_2](end_span).
- **Windows 11 Fluent UI:** Minimalist acrylic glass design and buttery-smooth touchpad gestures powered by KDE Plasma 6 + Wayland[span_3](start_span)[span_3](end_span).
- **Dual Persona Switcher:** Switch between `retro-mode office` (distraction-free dev mode) and `retro-mode cyber` (dark operational HUD)[span_4](start_span)[span_4](end_span).
- **Isolated Weapons Bay:** Rootless Distrobox Podman container running Kali Linux tools (`nmap`, `metasploit`, `wireshark`, `airgeddon`) without polluting host dependencies[span_5](start_span)[span_5](end_span).
- **Modern Rust Toolchain:** Pre-compiled static toolchain including `rustscan`, `btop++`, `yazi`, and `ripgrep` for zero runtime latency[span_6](start_span)[span_6](end_span).

---

## 📂 Repository Structure

```text
retro-os/
├── 01_engine_setup.sh      # Core performance, ZRAM, EarlyOOM & Btrfs Snapper
├── 02_interface_setup.sh   # KDE Plasma Wayland, Fluent themes & Gestures
├── 03_modules_setup.sh     # Distrobox Kali container & Modern Rust tools
├── install.sh              # Master Automated Zero-Error Installer
├── retro                   # Unified CLI Management Utility
└── README.md               # Architecture documentation

