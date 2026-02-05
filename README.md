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

A comprehensive, declarative, and modular NixOS configuration built on **Snowfall Lib**. It manages both system (NixOS) and user (Home Manager) layers from a single flake, featuring a highly customized Wayland desktop environment focusing on **Niri**, **Hyprland**, and **DankMaterialShell**.

- **Architecture:** Snowfall Lib (auto module discovery)
- **Desktop Sessions:**
  - **Niri:** Scrollable-tiling compositor (Rust/Smithay) - *Primary Session*.
  - **Hyprland:** Dynamic tiling compositor (C++/Aquamarine).
- **Shell / Panel:** [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) (DMS) integration for panels, widgets, and lock screen.
- **Greeter:** `greetd` + DMS Greeter (`dms-greeter`) support.
- **Theme:** Catppuccin (Mocha) end-to-end integration.
- **Secrets:** SOPS-Nix (Age) for secure credential management.

## ✨ Recent Enhancements (v4.1)

### 🧘 Zen Mode
Distraction-free mode for deep work. Toggles UI elements to maximize screen real estate.
- **Toggle:** `Mod + Z`
- **Behavior:** Hides the DMS bar, disables notifications (DnD), and simplifies layout.
- **Supported:** Niri & Hyprland.

### 📌 Smart Pin (Picture-in-Picture)
Intelligent window pinning that matches MPV rules.
- **Toggle:** `Mod + P`
- **Behavior:** Resizes the active window to **640x360**, floats it, and snaps it perfectly to the **Top-Right** corner (`32, 96` margins).
- **Logic:** Uses screen-relative calculation to ensure perfect positioning regardless of display scaling or initial state.

### 🎬 Premium Motion Profile
A finely-tuned animation set for Niri that prioritizes fluid transitions without sacrificing responsiveness.
- **Open:** Windows slide up (`10%`) and scale in with a precise `ease-out-expo` curve.
- **Close:** Windows slide down and fade out with elegant deceleration.
- **Move:** Zero-overshoot, magnetic snapping (`damping-ratio: 0.98`) for a stable, high-end feel.

### 👁️ Dynamic Opacity
On-the-fly transparency control for the active window.
- **Control:** `Mod + Shift + Scroll` (Touchpad) or `Mod + Ctrl + Shift + J/K`.
- **Use Case:** "X-Ray" vision to read content behind active windows.

## 🧩 Key Technologies

| Component                | Implementation Details                                                                             |
| ------------------------ | -------------------------------------------------------------------------------------------------- |
| **Framework**            | [Snowfall Lib](https://github.com/snowfallorg/lib)                                                 |
| **Niri Compositor**      | Uses `niri-flake` (unstable) with custom "Premium Feel" animations.                               |
| **Hyprland**             | Pinned flake input; configs split into `binds.nix`, `rules.nix`, with Smart Borders enabled.       |
| **Shell/UI**             | **DankMaterialShell** (Quickshell-based). Provides top bar, dock, and Matugen OSDs.                |
| **Power Stack**          | `power-profiles-daemon` (PPD) + battery charge thresholds (`modules/nixos/power`).                |
| **Authentication**       | Polkit-GNOME + GNOME Keyring fully integrated via PAM.                                             |

## 🔋 Power Management

Profile switching uses `power-profiles-daemon` (PPD), so you can switch between `power-saver`, `balanced`, and `performance` instantly.
- **Module:** `modules/nixos/power/default.nix`
- **PPD:** `my.power.stack = "ppd";` (default) or `my.power.stack = "none";`
- **CLI:** `powerprofilesctl get|set|list`, `osc-system status`, `rofi-launcher perf`
- **Battery thresholds:** `my.power.battery.chargeThresholds.enable = true;` (default), `start`/`stop` configurable (defaults 75–80)

## ⌨️ Keybindings

Shared muscle memory across Niri and Hyprland.

- `Super + Enter` -> Terminal (Kitty)
- `Super + Space` -> DMS Spotlight (Launcher)
- `Super + Z` -> **Zen Mode** Toggle
- `Super + P` -> **Pin Mode** (Smart PIP)
- `Super + Shift + Scroll` -> Adjust Opacity
- `Super + Arrows` or `h/j/k/l` -> Move focus
- `Super + Shift + Arrows` -> Move window
- `Super + 0` -> Center Column (Niri) / Focus Center (Hyprland)
- `Super + C` -> DMS Control Center
- `Super + N` -> DMS Notifications

## 🗃️ Repository Structure

```bash
.
├── flake.nix             # Core configuration & inputs
├── install.sh            # Unified installation tool
├── modules/              # Modular configs
│   ├── nixos/            # System-level (Power, Services, Greeters)
│   └── home/             # User-level (Niri, Hyprland, DMS, Apps)
│       └── scripts/      # Helper scripts (niri-set, hypr-set, osc-media)
├── homes/                # Home-Manager profiles
└── secrets/              # SOPS-encrypted secrets
```

## 🚀 Installation

```bash
# 1. Clone
git clone https://github.com/kenanpelit/nixosc ~/.nixosc
cd ~/.nixosc

# 2. Install
./install.sh install hay

# 3. Update
./install.sh update
```

## 📄 License
MIT License.
