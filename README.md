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

A comprehensive NixOS configuration built on **Snowfall Lib**, managing both system (NixOS) and user (Home Manager) layers from a single flake.

- **Architecture:** Snowfall Lib (auto module discovery)
- **Desktop:** Hyprland + Niri + GNOME (optional) + **DankMaterialShell (DMS)**; Waybar/Hyprpanel disabled by default
- **Greeter:** greetd + DMS Greeter (`dms-greeter`) on supported hosts
- **Launchers:** DMS Spotlight + Walker (Elephant) + Rofi; Ulauncher is also configured
- **Theme:** Catppuccin (Mocha by default) end-to-end
- **Shell:** Zsh + Starship + Tmux + Kitty/Wezterm
- **Secrets:** SOPS-Nix (Age)

## 🗃️ Repository Structure

Snowfall layout (all modules auto-imported via `default.nix`):

- [flake.nix](flake.nix) - Core configuration entry point
- [install.sh](install.sh) - Unified installation & management tool
- [systems](systems) - ❄️ Host configurations
  - [hay](systems/x86_64-linux/hay/) - Laptop/Workstation
  - [vhay](systems/x86_64-linux/vhay/) - VM profile
- [modules](modules) - 🍱 Modular configs
  - [nixos](modules/nixos/) - System-level (hardware, services, security, networking…)
  - [home](modules/home/) - User-level (apps, theming, shells, Hyprland, DMS, scripts)
- [homes](homes) - Home-Manager profiles per host/user
- [overlays](overlays/) - 🔧 Nixpkgs overlays
- [secrets](secrets/) - 🔐 SOPS-encrypted material
- [wallpapers](wallpapers/) - Theme assets used by DMS/Hyprland

## 🧩 Components & Technologies

### Core Systems

| Component                | Technology                                                                                         |
| ------------------------ | -------------------------------------------------------------------------------------------------- |
| **Base System**          | [NixOS 25.11](https://nixos.org/)                                                                  |
| **Framework**            | [Snowfall Lib](https://github.com/snowfallorg/lib)                                                 |
| **User Environment**     | [Home-Manager](https://github.com/nix-community/home-manager)                                      |
| **Secrets Management**   | [SOPS-nix](https://github.com/Mic92/sops-nix) (Age)                                                |

### Desktop Environment

| Component                    | Implementation                                                                                                        |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **Compositors / Sessions**   | Hyprland (optimized), Niri, GNOME                                                                                    |
| **Shell / Panel**            | [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) (DMS)                                           |
| **Greeter**                  | `greetd` + DMS Greeter (`dms-greeter`)                                                                                |
| **Launcher**                 | DMS Spotlight + [Walker](https://github.com/abenz1267/walker) + [Rofi](https://github.com/lbonn/rofi) (+ Ulauncher)   |
| **Notifications & Widgets**  | DMS built-ins                                                                                                         |
| **Lock / Power**             | DMS lock/powermenu (DMS uses wl-session-lock; Niri uses `niri-lock` wrapper for consistent UI)                        |
| **Wallpaper**                | DMS wallpaper engine (Hyprpaper present; Waypaper/Wpaperd removed)                                                    |
| **Browsers**                 | Brave primary; Chrome profiles optional; Zen/Vivaldi removed                                                          |

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

## 🪪 Greeter (greetd + DMS Greeter)

This repo can run the login screen using DMS Greeter (`dms-greeter`) under `greetd`.

Host example: `systems/x86_64-linux/hay/default.nix`

```nix
my.greeter.dms = {
  enable = true;
  compositor = "hyprland"; # hyprland | niri | sway
  layout = "tr";
  variant = "f";
};
```

Notes:
- Logs: `/var/log/dms-greeter/dms-greeter.log`
- The module sets a writable greeter `HOME` (`/var/lib/dms-greeter`) to avoid cache/shader warnings.

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

## ⌨️ Keybindings (Niri / Hyprland + DMS)

### Niri + DMS

- `Mod` is the main modifier (typically `SUPER` in a normal session).
- `Alt + L` — DMS lock (via `niri-lock`)
- `Mod + Space` — DMS Spotlight
- Reload config (no restart): `niri msg action load-config-file`
- Full config generator: `modules/home/niri/default.nix`

### Hyprland + DMS

- `$mainMod` = `SUPER` key
- DMS ships Spotlight/panel shortcuts (`$mainMod+Space`, powermenu, control-center, etc.).
- Hyprland core (summary):
  - `$mainMod + Enter` — Kitty
  - `$mainMod + Q` — Close window
  - `$mainMod + F` — Toggle float; `$mainMod+Shift+F` — Fullscreen
  - `$mainMod + h/j/k/l` or arrows — Move focus; `Shift` moves window; `Ctrl` resizes
  - `$mainMod + 1-9` — Workspace; `Shift+1-9` — move window; `Ctrl+1-9` — monitor-aware move
  - `$mainMod + Tab` — DMS Hypr overview
- Full list: `modules/home/hyprland/config.nix`

## 🛠 Troubleshooting

### DMS warnings about Niri config writes

DMS may log lines like:
- `NiriService: Failed to write layout config`
- `NiriService: Failed to write alttab config`

This repo intentionally manages `~/.config/niri/dms/*.kdl` via Home Manager (read-only symlinks), so DMS' auto-generator can't overwrite them.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
