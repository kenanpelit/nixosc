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
- **Desktop Sessions:**
  - **Niri:** Scrollable-tiling compositor, powered by [niri-flake](https://github.com/sodiboo/niri-flake) for build-time config validation and binary caching.
  - **Hyprland:** Dynamic tiling compositor with extensive customization.
  - **GNOME / COSMIC / Sway:** Available as additional sessions.
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
│       └── scripts/      # Helper scripts (niri-set/hypr-set, etc.)
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

Or use the standard commands directly:

```bash
# System only
sudo nixos-rebuild switch --flake .#hay

# Home only
home-manager switch --flake .#kenan@hay
```

### 3. Update

To update flake inputs (including Niri unstable):

```bash
./install.sh update
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
- **Navigation:**
  - `Super + Arrows` or `h/j/k/l` -> Move focus
  - `Super + Shift + Arrows` -> Move window
- **DMS Features:**
  - `Super + C` -> Control Center
  - `Super + N` -> Notifications

### Niri

- `Super + S` -> Overview
- `Alt + Tab` -> Switch windows (DMS query)
- `Super + Up/Down` or `Super + K/J` -> Workspace up/down
- `Alt + 1..9` -> Move column to workspace

### Hyprland

- `Super + Tab` -> Overview (DMS Hypr module)
- `Super + F` -> Toggle float (via `hypr-set`)

## 🛠 Advanced Features

### Modular WM Configuration
Niri and Hyprland configurations are split into granular Nix files for better maintainability:
- `binds.nix`: Keybindings
- `rules.nix`: Window & Layer rules
- `settings.nix`: Core compositor settings
- `variables.nix`: Environment variables & theming constants

### Session Bootstrap Scripts
To keep compositor sessions consistent and avoid “one-off” tweaks, common tasks are centralized in scripts under `modules/home/scripts/bin/`:

- `niri-set`: session start/init, window arranging, lock, diagnostics (`niri-set doctor`)
- `hypr-set`: session init + env sync helpers
- `wm-workspace`: routes workspace actions across compositors (used by Fusuma)

## 🔋 Power Management (v17 stack)

This repo includes a custom **power management stack** for laptops (especially Intel HWP / `intel_pstate=active`) that aims to stay **consistent** across boot/suspend/AC changes and avoid “mystery overrides”.

- **Module:** `modules/nixos/power/default.nix`
- **Status CLI:** `osc-system status` (use `sudo osc-system turbostat-quick` to validate real CPU MHz under HWP)
- **Note:** Under Intel HWP, `scaling_cur_freq` can report ~400MHz even when the CPU is busy; prefer `turbostat` for truth.

### What it controls

On physical hosts, the module manages:
- **ACPI Platform Profile** (`/sys/firmware/acpi/platform_profile`)
- **CPU governor** (policy-level `scaling_governor`)
- **Intel EPP** (HWP energy preference; policy-level `energy_performance_preference`)
- **Minimum performance floor** (`/sys/devices/system/cpu/intel_pstate/min_perf_pct`)
- **RAPL power limits** (MSR interface via `/sys/class/powercap/intel-rapl:0`)
- **Thermal guard** that clamps PL1/PL2 when package temp crosses thresholds
- **Drift guard** (`power-policy-guard`) to re-apply settings if firmware/other services revert them shortly after boot/resume

### Services

The main units you’ll see on a running system:
- `platform-profile.service`
- `cpu-governor.service`
- `cpu-epp.service`
- `cpu-min-freq-guard.service`
- `rapl-power-limits.service`
- `rapl-thermo-guard.service`
- `battery-thresholds.service`
- `power-policy-guard.service`

To re-apply everything after changes or debugging:

```bash
sudo osc-system profile-refresh
```

### Avoiding conflicts

This module disables `power-profiles-daemon` to prevent it from overriding platform profile / EPP / governor after boot.
If you use other power tools (e.g. `tlp`, `auto-cpufreq`, `thermald`), double-check that they are not fighting your policy.

### DMS Integration
- **Themes:** Automatically managed by DMS/Matugen or manually pinned via `settings.nix`.
- **Plugins:** Installed via imperative `dms-plugin-sync` service (best-effort).
- **Greeter:** Fully supported via `modules/nixos/dms-greeter`.

### Troubleshooting
- **Niri Config Validation:** If the build fails with a KDL error, check `modules/home/niri/default.nix`. The config is validated at build time!
- **DMS IPC (Hyprland):** If `dms ipc …` can’t find a running Quickshell instance, ensure `QT_QPA_PLATFORM=wayland;xcb` is exported in the session environment (this repo syncs it via `hypr-set` and Hyprland `exec-once`).
- **Keyring/PAM:** If you see `gkr-pam` errors in logs, ensure `seahorse` shows the Login keyring as unlocked. It usually works despite the log noise.
- **Discord:** Use `WebCord` for better Wayland support if standard Discord crashes.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
