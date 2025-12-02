# NixOS Configuration (Snowfall Edition)

<div align="center">
  <img src=".github/assets/logo/nixos-logo.png" height="120" alt="NixOS Logo" />
  <h1>NixOS Dotfiles & System Configuration</h1>
  
  <p>
    <b>Modern • Modular • Declarative • Beautiful</b>
  </p>

  ![NixOS](https://img.shields.io/badge/NixOS-25.11-5277C3?style=for-the-badge&logo=nixos&logoColor=white)
  ![Snowfall](https://img.shields.io/badge/Snowfall-Lib-blue?style=for-the-badge)
  ![Hyprland](https://img.shields.io/badge/Desktop-Hyprland-00a4a6?style=for-the-badge)
  ![Catppuccin](https://img.shields.io/badge/Theme-Catppuccin-F5C2E7?style=for-the-badge)
</div>

---

## 📖 Overview

This repository hosts a comprehensive **NixOS** configuration managed with the **Snowfall Lib** framework. It unifies system-level configuration (NixOS) and user environment (Home Manager) into a single, cohesive flake.

It is designed to be **host-agnostic**, adapting its behavior dynamically based on whether it's running on a physical workstation or a virtual machine.

### ✨ Key Features

*   **❄️ Snowfall Architecture:** Structured, auto-discovered modules for zero-boilerplate management.
*   **🎨 Hyprland Desktop:** A fully customized tiling window manager experience with **Waybar**, **Rofi**, **Mako**, and **Hyprlock**.
*   **🖌️ Theming:** Global **Catppuccin Mocha** theme integration across GTK, QT, and TUI applications.
*   **🐚 Advanced Shell:** Modular **Zsh** configuration with **Starship**, **Zoxide**, **FZF**, and **Tmux**.
*   **🔒 Security:** Declarative secrets management with **SOPS** (Age encryption) and strict firewall rules.
*   **🤖 Automation:** `install.sh` script for unified system building, updating, and bootstrapping.

---

## 📸 Gallery

<div align="center">
  <img src=".github/assets/screenshots/desktop.png" width="48%" alt="Desktop" />
  <img src=".github/assets/screenshots/terminal.png" width="48%" alt="Terminal" />
</div>

> *More screenshots available in `.github/assets/screenshots`*

---

## 📂 Architecture

The project structure follows modern Nix standards:

```
.
├── ❄️ systems/              # Host Definitions
│   └── x86_64-linux/     # Architecture
│       ├── hay/          # Physical Workstation (Desktop/Laptop)
│       └── vhay/         # Virtual Machine (Testing/Dev)
│
├── ❄️ modules/              # Modular Configuration
│   ├── nixos/            # System-level modules (Services, Boot, Hardware)
│   └── user-modules/     # User-level modules (Home Manager apps, Dotfiles)
│
├── ❄️ packages/             # Custom Packages (e.g. Maple Mono, Custom Scripts)
├── ❄️ overlays/             # Nixpkgs Overlays (Modifications)
├── 🔒 secrets/              # Encrypted Secrets (SOPS + Age)
└── 📜 install.sh            # The Master Control Script
```

---

## 📦 Software Stack

A curated list of applications included in this configuration:

### 🖥️ Desktop & GUI
*   **Window Manager:** Hyprland (w/ Waybar, Hyprpaper, Hyprlock)
*   **Browser:** Zen Browser, Brave, Firefox
*   **Communication:** Discord (WebCord), WhatsApp (Wasistlos)
*   **Media:** MPV, VLC, Spotify, OBS Studio
*   **Productivity:** LibreOffice, Obsidian, Zathura

### 💻 Terminal & CLI
*   **Shell:** Zsh + Starship
*   **Terminal:** WezTerm, Kitty, Foot
*   **Multiplexer:** Tmux
*   **Editors:** Neovim, Helix
*   **File Manager:** Yazi, Ranger
*   **Utils:** FZF, Zoxide, Eza, Bat, Ripgrep, Htop, Btop

### 🛠️ Development
*   **Languages:** Python, Go, Lua, Nix, Bash
*   **Tools:** Git, Lazygit, Docker/Podman, Direnv, Devenv
*   **Nix:** Nix-Shell, Flakes, Home-Manager

---

## 🚀 Installation & Usage

This configuration comes with a powerful `install.sh` script to manage the system.

### 1. Bootstrap (Fresh Install)
Boot from the NixOS ISO and clone this repo:

```bash
# 1. Clone the repo
git clone https://github.com/kenanpelit/nixosc.git ~/.nixosc
cd ~/.nixosc

# 2. Generate hardware config (if new hardware)
nixos-generate-config --show-hardware-config > systems/x86_64-linux/<host>/hardware-configuration.nix

# 3. Bootstrap the system
./install.sh --pre-install hay
# (This copies initial config to /etc/nixos)

# 4. Install
sudo nixos-install --flake .#hay
```

### 2. Daily Management (Build & Switch)
To apply changes to your current system:

```bash
# Switch to 'hay' configuration
./install.sh install hay

# Switch to 'vhay' configuration
./install.sh install vhay
```

### 3. Updates
To update flake inputs (packages) and rebuild:

```bash
# Update all inputs
./install.sh update

# Update specific input
./install.sh update hyprland
```

---

## ⚙️ Customization Guide

### Adding a Package
*   **System-wide:** Add to `modules/nixos/packages/default.nix`
*   **User-specific:** Add to `modules/user-modules/packages/default.nix`

### Adding a New Module
Just create a directory! **Auto-import** handles the rest.
*   `modules/nixos/my-new-service/default.nix` → Automatically loaded for system.
*   `modules/user-modules/my-new-app/default.nix` → Automatically loaded for user.

### Secrets (SOPS)
Secrets are encrypted with Age. To edit secrets:

```bash
sops secrets/wireless-secrets.enc.yaml
```

---

## 📜 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
