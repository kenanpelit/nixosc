# NixOS Configuration Suite (`nixosc`)

<div align="center">
  <img src="./.github/assets/logo/nixos-logo.png" width="100px" />
  <br />
  <strong>Kenan's NixOS Configuration Suite</strong>
  <br />
  <img src="./.github/assets/pallet/pallet-0.png" width="600px" />
  <br />
  <br />
  <a href="https://github.com/kenanpelit/nixosc/actions/workflows/ci.yml">
    <img src="https://img.shields.io/github/actions/workflow/status/kenanpelit/nixosc/ci.yml?branch=main&style=for-the-badge&label=CI&logo=githubactions&logoColor=ffffff&color=458588&labelColor=282828" />
  </a>
  <a href="https://github.com/kenanpelit/nixosc/stargazers">
    <img src="https://img.shields.io/github/stars/kenanpelit/nixosc?style=for-the-badge&logo=starship&logoColor=FABD2F&color=FABD2F&labelColor=282828" />
  </a>
  <a href="https://github.com/kenanpelit/nixosc/">
    <img src="https://img.shields.io/github/repo-size/kenanpelit/nixosc?style=for-the-badge&logo=github&logoColor=B16286&color=B16286&labelColor=282828" />
  </a>
  <a href="https://nixos.org">
    <img src="https://img.shields.io/badge/NixOS-25.11?style=for-the-badge&logo=NixOS&logoColor=458588&color=458588&labelColor=282828" />
  </a>
  <a href="https://github.com/kenanpelit/nixosc/blob/main/LICENSE">
    <img src="https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=MIT&colorA=282828&colorB=98971A&logo=unlicense&logoColor=98971A" />
  </a>
</div>

Opinionated, modular NixOS + Home Manager configuration built with **Snowfall Lib** and managed via a single flake. This repo is designed for my machines, but aims to be readable, reproducible, and easy to extend.

- Quick docs: `HowTo.md`
- Entry point: `flake.nix`
- Hosts: `systems/`
- Modules: `modules/`

## Gallery

<p align="center">
   <img src="./.github/assets/screenshots/1.png" style="margin-bottom: 10px;"/> <br>
   <img src="./.github/assets/screenshots/hyprlock.png" style="margin-bottom: 10px;" /> <br>
   <img src="./.github/assets/screenshots/grub.png" style="margin-bottom: 10px;" /> <br>
</p>

## Overview

- Architecture: Snowfall Lib (auto module discovery) + custom `my.*` options
- System: NixOS 25.11 (flake-pinned)
- User layer: Home Manager (flake)
- Secrets: `sops-nix` (Age)
- Desktop: Hyprland + Niri + GNOME (optional) + DankMaterialShell (DMS)

## Repository Layout

Snowfall layout (modules are auto-imported via `default.nix` discovery):

- `flake.nix`: inputs, outputs, checks, devshell
- `install.sh`: unified install/switch/update helper
- `systems/`: NixOS hosts (`systems/x86_64-linux/<host>/default.nix`)
- `homes/`: Home Manager profiles (`homes/x86_64-linux/<user>@<host>/default.nix`)
- `modules/nixos/`: NixOS modules (services, security, networking, hardware…)
- `modules/home/`: Home Manager modules (apps, theming, scripts, WMs…)
- `overlays/`: nixpkgs overlays (shared)
- `secrets/`: `sops-nix` encrypted material

## Quick Start

> [!CAUTION]
> This configuration is tailored for specific hardware. Review `systems/**/hardware-configuration.nix` before applying to a different machine.

Clone:

```bash
git clone https://github.com/kenanpelit/nixosc ~/.nixosc
cd ~/.nixosc
```

Build & switch (recommended):

```bash
./install.sh install hay   # physical machine
./install.sh install vhay  # VM profile
```

Or directly:

```bash
nixos-rebuild switch --flake .#hay
home-manager switch --flake .#kenan@hay
```

Update inputs:

```bash
./install.sh update
```

## Hosts

- `hay`: laptop/workstation (`systems/x86_64-linux/hay/`)
- `vhay`: VM profile (`systems/x86_64-linux/vhay/`)

## Greeter (greetd + DMS Greeter)

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

## Customization

Add a package:

- System-wide: `modules/nixos/packages/default.nix`
- User-specific: `modules/home/packages/default.nix`

Create a new module (Snowfall auto-imports `default.nix`):

- System module: `modules/nixos/my-service/default.nix`
- Home module: `modules/home/my-app/default.nix`

Manage secrets:

```bash
sops secrets/wireless-secrets.enc.yaml
```

## Development

Formatting and checks:

```bash
nix fmt
nix flake check -L --show-trace
treefmt --fail-on-change --clear-cache --check .
```

The flake exposes CI-friendly checks (statix/deadnix/treefmt + build targets) and a devshell in `flake.nix`.

## Keybindings (high level)

- Niri: see `modules/home/niri/` (binds/rules/settings)
- Hyprland: see `modules/home/hyprland/config.nix`
- DMS: ships Spotlight/panel shortcuts; `Mod+Space` is typically Spotlight

## Troubleshooting

### DMS warnings about Niri config writes

DMS may log lines like:
- `NiriService: Failed to write layout config`
- `NiriService: Failed to write alttab config`

This repo intentionally manages `~/.config/niri/dms/*.kdl` via Home Manager (read-only symlinks), so DMS' auto-generator can't overwrite them.

### Stasis (idle manager) config is writable by design

This repo ships a Home-Manager module for [Stasis](https://github.com/saltnpepper97/stasis).

Enable it in your HM profile:

```nix
my.user.stasis.enable = true;
```

Notes:
- Config path: `~/.config/stasis/stasis.rune`
- The file is created via `home.activation` (not `xdg.configFile`) so it stays writable.
- Convenience wrapper: `stasisctl ...` (always uses the configured `stasis.rune` path)

Useful commands:
```bash
systemctl --user status stasis
stasisctl info --json
stasisctl reload
stasisctl profile work    # or: none / presentation
stasisctl dump 80
```

## License

MIT. See `LICENSE`.
