# NixOS Configuration Suite (nixosc)

<div align="center">
   <img src="./.github/assets/logo/nixos-logo.png" width="100px" />
   <br>
      Kenan's NixOS Configuration Suite
   <br>
      <img src="./.github/assets/pallet/pallet-0.png" width="600px" /> <br>

   <div>
      <p></p>
      <div>
         <a href="https://github.com/kenanpelit/nixosc/stargazers">
            <img src="https://img.shields.io/github/stars/kenanpelit/nixosc?color=FABD2F&labelColor=282828&style=for-the-badge&logo=starship&logoColor=FABD2F">
         </a>
         <a href="https://github.com/kenanpelit/nixosc/">
            <img src="https://img.shields.io/github/repo-size/kenanpelit/nixosc?color=B16286&labelColor=282828&style=for-the-badge&logo=github&logoColor=B16286">
         </a>
         <a href="https://nixos.org">
            <img src="https://img.shields.io/badge/NixOS-25.11-blue.svg?style=for-the-badge&labelColor=282828&logo=NixOS&logoColor=458588&color=458588">
         </a>
         <a href="https://github.com/kenanpelit/nixosc/blob/main/LICENSE">
            <img src="https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=MIT&colorA=282828&colorB=98971A&logo=unlicense&logoColor=98971A&"/>
         </a>
      </div>
      <br>
   </div>
</div>

## 🖼️ Gallery

<p align="center">
   <img src="./.github/assets/screenshots/1.png" style="margin-bottom: 10px;"/> <br>
   <img src="./.github/assets/screenshots/hyprlock.png" style="margin-bottom: 10px;" /> <br>
   <img src="./.github/assets/screenshots/grub.png" style="margin-bottom: 10px;" /> <br>
</p>

## 📋 Project Overview

**NixOS Configuration Suite (nixosc)** - Snowfall Edition

A comprehensive NixOS system configuration management suite built on the **Snowfall Lib** framework. It provides a unified, modular approach to managing both system-level configuration (NixOS) and user environments (Home Manager).

- **Architecture:** Snowfall Lib (automatic module discovery)
- **Desktop:** Hyprland (Wayland) with **DankMaterialShell (DMS)** shell; Waybar disabled
- **Launchers:** DMS launcher + Walker + Rofi (fallback)
- **Theme:** Catppuccin Mocha everywhere
- **Shell:** Zsh + Starship + Tmux
- **Secrets:** SOPS-Nix with Age encryption

## 🗃️ Repository Structure

The project follows modern Snowfall Lib standards:

- [flake.nix](flake.nix) - Core configuration entry point
- [install.sh](install.sh) - Unified installation & management tool
- [systems](systems) - ❄️ Host configurations
  - [hay](systems/x86_64-linux/hay/) - 💻 Laptop/Workstation
  - [vhay](systems/x86_64-linux/vhay/) - 🗄️ Virtual Machine
- [modules](modules) - 🍱 Modular configurations
  - [nixos](modules/nixos/) - ⚙️ System-level modules (hardware, services)
  - [home](modules/home/) - 🏠 User-level modules (Home Manager apps/services)
- [packages](packages/) - 📦 Custom packages (e.g. Maple Mono) and scripts
- [overlays](overlays/) - 🔧 Nixpkgs overlays
- [secrets](secrets/) - 🔐 SOPS-encrypted secrets
- [assets](assets/) - 📦 Binary assets and configs

## 🧩 Components & Technologies

### Core Systems

| Component                | Technology                                                                                         |
| ------------------------ | -------------------------------------------------------------------------------------------------- |
| **Base System**          | [NixOS 25.11](https://nixos.org/)                                                                  |
| **Framework**            | [Snowfall Lib](https://github.com/snowfallorg/lib)                                                 |
| **User Environment**     | [Home-Manager](https://github.com/nix-community/home-manager)                                      |
| **Secrets Management**   | [SOPS-nix](https://github.com/Mic92/sops-nix) with Age                                             |

### Desktop Environment

| Component                    | Implementation                                                                                                        |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **Window Manager**           | [Hyprland](https://github.com/hyprwm/hyprland)                                                                        |
| **Shell / Panel**            | [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) (DMS)                                           |
| **Launcher**                 | DMS launcher + [Walker](https://github.com/abenz1267/walker) + [Rofi](https://github.com/lbonn/rofi) (fallback)       |
| **Notifications & Widgets**  | DMS built-ins                                                                                                         |
| **Lock Screen**              | [Hyprlock](https://github.com/hyprwm/hyprlock)                                                                        |
| **Wallpaper**                | Managed by DMS (hyprpaper disabled)                                                                                   |

## 🚀 Installation

> [!CAUTION]
> This configuration is tailored for specific hardware. Review `hardware-configuration.nix` before applying.

### 1. Clone & Setup

```bash
git clone https://github.com/kenanpelit/nixosc ~/.nixosc
cd ~/.nixosc
```

### 2. Install / Switch

Use the helper script to build and switch configurations:

```bash
# For Physical Machine (hay)
./install.sh install hay

# For Virtual Machine (vhay)
./install.sh install vhay
```

### 3. Update

To update flake inputs:

```bash
./install.sh update
```

## ⚙️ Customization Guide

### Adding a Package
*   **System-wide:** Edit `modules/nixos/packages/default.nix`.
*   **User-specific:** Edit `modules/home/packages/default.nix`.

### Creating a New Module
Just create a directory! **Snowfall Lib** automatically imports `default.nix` files.
*   System module: `modules/nixos/my-service/default.nix`
*   User module: `modules/home/my-app/default.nix`

### Managing Secrets
Secrets are encrypted with Age and managed by SOPS.
To edit secrets:
```bash
sops secrets/wireless-secrets.enc.yaml
```

## ⌨️ Keybindings (Hyprland)

- `$mainMod` = `SUPER` key
- DMS ships its own launcher/bindings; base Hyprland binds include:
  - `$mainMod + Enter` — Open terminal
  - `$mainMod + B` — Open browser
  - `$mainMod + D` — Open launcher (Rofi fallback; DMS launcher bound in-shell)
  - `$mainMod + Q` — Close window
  - `$mainMod + F` — Fullscreen
  - `$mainMod + Space` — Toggle floating
  - `$mainMod + 1-9` / `Shift` — Switch/move window to workspace

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
