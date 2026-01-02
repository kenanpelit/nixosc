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

A comprehensive, declarative, and modular NixOS configuration built on **Snowfall Lib**. It manages both system (NixOS) and user (Home Manager) layers from a single flake, featuring a highly customized Wayland desktop environment focusing on **Niri** and **Hyprland**.

- **Architecture:** Snowfall Lib (auto module discovery)
- **Desktop Sessions:**
  - **Niri:** Scrollable-tiling compositor (Rust/Smithay) - *Primary Session*.
  - **Hyprland:** Dynamic tiling compositor (C++/Aquamarine).
- **Shell / Panel:** [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) (DMS) integration for panels, widgets, and lock screen.
- **Theme:** Catppuccin (Mocha) end-to-end integration.

## ✨ Recent Enhancements (v4.1)

### 🧘 Zen Mode
Distraction-free mode for deep work. Toggles UI elements to maximize screen real estate.
- **Toggle:** `Mod + Z`
- **Behavior:** Hides the top bar, disables notifications (DnD), removes window gaps and borders.
- **Supported:** Niri & Hyprland.

### 📌 Smart Pin (Picture-in-Picture)
Intelligent window pinning that behaves like a native PIP mode.
- **Toggle:** `Mod + P`
- **Behavior:** Resizes the active window to **640x360**, floats it, and snaps it perfectly to the **Top-Right** corner (with smart margins). Restores to original state on toggle.
- **Logic:** Uses screen-relative calculation to ensure perfect positioning regardless of initial window state.

### 🎬 macOS + Hyprland Fusion Animations
A custom animation profile for Niri that blends the fluidity of macOS with the snappiness of Hyprland.
- **Open:** Windows slide up (`10%`) and scale in with a `quintic` ease curve.
- **Close:** Windows slide down and fade out elegantly.
- **Move:** Zero-overshoot, magnetic snapping (`damping-ratio: 0.98`) for a professional feel.

### 👁️ Dynamic Opacity
On-the-fly transparency control for the active window.
- **Control:** `Mod + Shift + Scroll` (Touchpad two-finger scroll) or `Mod + Ctrl + Shift + J/K`.
- **Use Case:** Read content from a window behind the active one without switching focus ("X-Ray" vision).

## 🗃️ Repository Structure

The repository follows the Snowfall Lib layout, where modules are automatically discovered and imported.

```bash
.
├── flake.nix             # Core configuration & inputs
├── install.sh            # Unified installation & management tool
├── systems/              # ❄️ Host configurations (hardware-specific)
│   ├── hay/              # Workstation (Laptop)
│   └── vhay/             # Virtual Machine profile
├── modules/              # 🍱 Modular configs
│   ├── nixos/            # System-level modules (services, hardware, greeters)
│   └── home/             # User-level modules (apps, WMs, shell config)
│       ├── niri/         # Modular Niri config (binds, rules, settings)
│       ├── hyprland/     # Modular Hyprland config
│       ├── dms/          # DankMaterialShell configuration
│       └── scripts/      # Helper scripts (niri-set/hypr-set, etc.)
├── homes/                # Home-Manager profiles per host/user
└── secrets/              # 🔐 SOPS-encrypted secrets
```

## ⌨️ Keybindings

This repo aims for **shared muscle memory** across Niri and Hyprland.

### Shared (Niri / Hyprland)

- **Modifier:** `Super` (Windows Key)
- **General:**
  - `Super + Enter` -> Terminal (Kitty)
  - `Super + Space` -> DMS Spotlight (Launcher)
  - `Alt + Space` -> Rofi (fallback launcher)
  - `Alt + L` -> Lock
  - `Super + Q` -> Close Window
- **New Features:**
  - `Super + Z` -> **Zen Mode** Toggle
  - `Super + P` -> **Pin Mode** (Smart PIP)
  - `Super + Shift + Scroll` -> Adjust Opacity
- **Navigation:**
  - `Super + Arrows` or `h/j/k/l` -> Move focus
  - `Super + Shift + Arrows` -> Move window
  - `Super + 0` -> Center Column (Niri) / Focus Center (Hyprland)

### Niri Specific

- `Super + S` -> Overview
- `Super + Shift + R` -> Set Column Width to 75% (Reading Mode)
- `Alt + Tab` -> Switch windows (DMS query)
- `Super + Up/Down` or `Super + K/J` -> Workspace up/down
- `Alt + 1..9` -> Move column to workspace

### Hyprland Specific

- `Super + Tab` -> Overview (DMS Hypr module)
- `Super + F` -> Toggle float (via `hypr-set`)

## 🛠 Advanced Features

### Modular WM Configuration
Niri and Hyprland configurations are split into granular Nix files for better maintainability:
- `binds.nix`: Keybindings & Dispatchers
- `rules.nix`: Window & Layer rules (including privacy masking for screencasts)
- `settings.nix`: Core compositor settings (Animations, Decorations)
- `variables.nix`: Environment variables & theming constants

### Session Bootstrap Scripts
To keep compositor sessions consistent and avoid “one-off” tweaks, common tasks are centralized in scripts under `modules/home/scripts/bin/`:

- `niri-set`: The brain of the Niri session. Handles Init, Locking, Zen Mode, Pin Mode, and Diagnostics (`niri-set doctor`).
- `hypr-set`: Equivalent helper for Hyprland. Handles Env sync, Zen/Pin modes, and dynamic opacity.

## 🚀 Installation

> [!CAUTION]
> This configuration is tailored for specific hardware (Dell XPS / Intel). Review `systems/x86_64-linux/hay/hardware-configuration.nix` before applying to a new machine.

```bash
# 1. Clone
git clone https://github.com/kenanpelit/nixosc ~/.nixosc
cd ~/.nixosc

# 2. Install (System + Home)
./install.sh install hay

# 3. Update Inputs
./install.sh update
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.