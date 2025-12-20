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

A comprehensive, declarative, and modular NixOS configuration built on **Snowfall Lib**. It manages both system (NixOS) and user (Home Manager) layers from a single flake, featuring a highly customized Wayland desktop environment.

- **Architecture:** Snowfall Lib (auto module discovery)
- **Desktop:** 
  - **Niri** (Primary): Scrollable-tiling compositor, powered by [niri-flake](https://github.com/sodiboo/niri-flake) for build-time config validation and binary caching.
  - **Hyprland** (Secondary): Dynamic tiling compositor with extensive customization.
  - **GNOME**: Fallback session.
- **Shell / Panel:** [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) (DMS) integration for panels, widgets, and lock screen.
- **Greeter:** `greetd` + DMS Greeter (`dms-greeter`) support.
- **Theme:** Catppuccin (Mocha) end-to-end integration.
- **Secrets:** SOPS-Nix (Age) for secure credential management.

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
│       └── dms/          # DankMaterialShell configuration
├── homes/                # Home-Manager profiles per host/user
├── overlays/             # 🔧 Nixpkgs overlays
└── secrets/              # 🔐 SOPS-encrypted secrets
```

## 🧩 Key Technologies

| Component                | Implementation Details                                                                             |
| ------------------------ | -------------------------------------------------------------------------------------------------- |
| **Framework**            | [Snowfall Lib](https://github.com/snowfallorg/lib)                                                 |
| **Niri Compositor**      | Uses `niri-flake` (unstable) for latest features, build-time validation, and caching.              |
| **Hyprland**             | Pinned flake input for stability; configs split into `binds.nix`, `rules.nix`, etc.                |
| **Shell/UI**             | **DankMaterialShell** (Quickshell-based). Provides top bar, dock, and OSDs.                        |
| **Launchers**            | DMS Spotlight (primary), Rofi (fallback), Walker.                                                  |
| **Authentication**       | Polkit-GNOME + GNOME Keyring (fully integrated via PAM & DBus).                                    |
| **Browsers**             | Brave (default), Chrome.                                                                           |

## 🚀 Installation

> [!CAUTION]
> This configuration is tailored for specific hardware (Dell XPS / Intel). Review `systems/x86_64-linux/hay/hardware-configuration.nix` before applying to a new machine.

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

To update flake inputs (including Niri unstable):

```bash
./install.sh update
```

## ⌨️ Keybindings

### Niri + DMS (Main Session)

- **Modifier:** `Super` (Windows Key)
- **General:**
  - `Super + Enter` -> Terminal (Kitty)
  - `Super + Q` -> Close Window
  - `Super + F` -> Maximize Column / `Shift+F` Fullscreen
  - `Super + Space` -> DMS Spotlight (Launcher)
  - `Super + Tab` -> **Recent Windows** (Alt-Tab switcher)
- **Navigation:**
  - `Super + Arrows` or `h/j/k/l` -> Move focus
  - `Super + Shift + Arrows` -> Move window
  - `Super + Wheel` -> Scroll workspaces
- **DMS Features:**
  - `Super + C` -> Control Center
  - `Super + N` -> Notifications
  - `Alt + L` -> Lock Screen (DMS Lock)

### Hyprland (Secondary Session)

- **Modifier:** `Super`
- Same core navigation bindings (`h/j/k/l`).
- `Super + F` -> Toggle Float
- `Super + G` -> Toggle Group
- `Super + Tab` -> DMS Hypr Overview

## 🛠 Advanced Features

### Modular WM Configuration
Both Niri and Hyprland configurations are split into granular Nix files for better maintainability:
- `binds.nix`: Keybindings
- `rules.nix`: Window & Layer rules
- `settings.nix`: Core compositor settings
- `variables.nix`: Environment variables & theming constants

### DMS Integration
- **Themes:** Automatically managed by DMS/Matugen or manually pinned via `settings.nix`.
- **Plugins:** Installed via imperative `dms-plugin-sync` service (best-effort).
- **Greeter:** Fully supported via `modules/nixos/dms-greeter`.

### Troubleshooting
- **Niri Config Validation:** If the build fails with a KDL error, check `modules/home/niri/default.nix`. The config is validated at build time!
- **Keyring/PAM:** If you see `gkr-pam` errors in logs, ensure `seahorse` shows the Login keyring as unlocked. It usually works despite the log noise.
- **Discord:** Use `WebCord` for better Wayland support if standard Discord crashes.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.