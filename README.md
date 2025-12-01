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

**NixOS Configuration Suite (nixosc)** - Version 4.2.0

A comprehensive NixOS system configuration management suite that provides:

- Modular configuration structure (9 core modules + 78+ home modules)
- Hybrid workspace session management with smart window rules
- VPN-aware application launching and network optimization
- Automated backup and restoration tools
- Custom admin tooling generation with 20+ utility scripts
- Dual home-manager integration (NixOS module + standalone)
- Hardware-specific optimizations with thermal management
- Smart borders with dynamic window count detection
- Unified flake-input updater for streamlined updates

## 🗃️ Repository Structure

- [flake.nix](flake.nix) - Core configuration with 30+ inputs and dual home-manager outputs
- [flake.lock](flake.lock) - Locked dependency versions (updated Nov 19, 2025)
- [install.sh](install.sh) - Modular installation tool (v3.0.0, 1757 lines)
- [nixos-merge.sh](nixos-merge.sh) - Branch merge utility with exclusion support
- [hosts](hosts) - 🌳 Per-host configurations
  - [hay](hosts/hay/) - 💻 Laptop configuration (GRUB, Hyprland, GNOME, COSMIC)
  - [vhay](hosts/vhay/) - 🗄️ VM configuration (Development optimized)
- [modules](modules) - 🍱 Modularized NixOS configurations
  - [core](modules/core/) - ⚙️ Flat, one-dir-per-topic core modules
    - account, system (hardware/power/logind), nix, packages, display (dm/sessions/portals/audio/fonts), networking (vpn/tcp/dns), security (firewall/polkit/apparmor/audit/hblock/fail2ban), services (desktop/flatpak/gaming/containers/virtualization), sops, boot, kernel, locale, sysctl
  - [home](modules/home/) - 🏠 78+ application-specific Home-Manager modules
    - Desktop, Terminal, Development, Browsers, Media, Communication, Files, Security, Theming, etc.
  - [scripts](modules/home/scripts/) - 🔧 20+ utility scripts and binaries
- [assets](assets/) - 📦 Configuration assets (MPV scripts, encrypted configs)
- [secrets](secrets/) - 🔐 SOPS-encrypted secrets (age encryption)
- [wallpapers](wallpapers/) - 🌄 Wallpapers collection (nixos/ + others/)
- [.github](.github/) - 🐙 GitHub workflows and assets

## 🧩 Components & Technologies

### Core Systems

| Component                | Technology                                                                                         |
| ------------------------ | -------------------------------------------------------------------------------------------------- |
| **Base System**          | [NixOS 25.11](https://nixos.org/) (State Version 25.11, nixpkgs `nixos-25.11`)                    |
| **User Environment**     | [Home-Manager](https://github.com/nix-community/home-manager) (Dual mode: integrated + standalone) |
| **Secrets Management**   | [SOPS-nix](https://github.com/Mic92/sops-nix) with age encryption                                  |
| **Package Repositories** | [NUR](https://github.com/nix-community/NUR)                                                        |
| **Code Formatting**      | [Alejandra](https://github.com/kamadorueda/alejandra) + treefmt                                    |

### Desktop Environment

| Component                    | Implementation                                                                                                        |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **Window Manager**           | [Hyprland](https://github.com/hyprwm/hyprland) v1127 (commit 379ee99c)                                               |
| **Bar**                      | [Waybar](https://github.com/Alexays/Waybar) with custom modules                                                       |
| **Application Launcher**     | [rofi](https://github.com/lbonn/rofi) + [Walker](https://github.com/abenz1267/walker) v2.11.1                         |
| **Notification Daemon**      | [Mako](https://github.com/emersion/mako) + [SwayOSD](https://github.com/ErikReider/SwayOSD)                           |
| **Alt Desktop Environments** | [COSMIC](https://github.com/pop-os/cosmic) + [Sway](https://github.com/swaywm/sway) + [GNOME](https://www.gnome.org/) |

### Terminal & Shell

| Component              | Technology                                                                                                                         |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **Terminal Emulators** | [Kitty](https://github.com/kovidgoyal/kitty) + [Wezterm](https://wezfurlong.org/wezterm/) + [Foot](https://codeberg.org/dnkl/foot) |
| **Shell**              | [zsh](https://ohmyz.sh/) + [oh-my-zsh](https://ohmyz.sh/) + [p10k](https://github.com/romkatv/powerlevel10k)                       |
| **Text Editor**        | [Neovim](https://github.com/neovim/neovim)                                                                                         |
| **System Monitor**     | [Btop](https://github.com/aristocratos/btop)                                                                                       |
| **File Managers**      | [nemo](https://github.com/linuxmint/nemo/) + [yazi](https://github.com/sxyazi/yazi)                                                |

### Security & System

| Component              | Implementation                                                                                                  |
| ---------------------- | --------------------------------------------------------------------------------------------------------------- |
| **Lockscreen**         | [Hyprlock](https://github.com/hyprwm/hyprlock) + [Swaylock-effects](https://github.com/mortie/swaylock-effects) |
| **Network Management** | [NetworkManager](https://networkmanager.dev/) (`nmcli`/`nmtui`/`nm-applet`) + iwd-based WiFi helpers            |
| **Boot Loader**        | GRUB with custom [distro-grub-themes](https://github.com/AdisonCavani/distro-grub-themes)                       |

### Multimedia & Utilities

| Component              | Technology                                                                                              |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Image Viewer**       | [qview](https://interversehq.com/qview/)                                                                |
| **Media Player**       | [mpv](https://github.com/mpv-player/mpv)                                                                |
| **Music Player**       | [audacious](https://audacious-media-player.org/) + [spicetify](https://github.com/gerg-l/spicetify-nix) |
| **Screenshot Tools**   | [grimblast](https://github.com/hyprwm/contrib)                                                          |
| **Screen Recording**   | [wf-recorder](https://github.com/ammen99/wf-recorder)                                                   |
| **Clipboard Managers** | [wl-clip-persist](https://github.com/Linus789/wl-clip-persist) + [CopyQ](https://hluk.github.io/CopyQ/) |
| **Color Picker**       | [hyprpicker](https://github.com/hyprwm/hyprpicker)                                                      |

### Theming

| Component  | Implementation                                                                                                       |
| ---------- | -------------------------------------------------------------------------------------------------------------------- |
| **Theme**  | [Catppuccin Mocha](https://github.com/catppuccin/catppuccin)                                                         |
| **Cursor** | [catppuccin-mocha-lavender-cursors](https://github.com/catppuccin/cursors)                                           |
| **Icons**  | [Candy Beauty](https://github.com/arcolinux/a-candy-beauty-icon-theme-dev) + BeautyLine                              |
| **Fonts**  | [Monaspace](https://github.com/githubnext/monaspace) + [Nerd Fonts symbols](https://github.com/ryanoasis/nerd-fonts) (Maple Mono kept as fallback) |

### Advanced Features

| Feature                     | Implementation                                                                                                    |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **Hyprland Python Plugins** | [PyPrland](https://github.com/hyprland-community/pyprland)                                                        |
| **Browser Customization**   | [zen-browser](https://github.com/0xc000022070/zen-browser-flake)                                                  |
| **Flatpak Integration**     | [nix-flatpak](https://github.com/gmodena/nix-flatpak)                                                             |
| **Package Search**          | [nix-search-tv](https://github.com/3timeslazy/nix-search-tv)                                                      |
| **Hyprland Extensions**     | Multiple [plugins](https://github.com/hyprwm/hyprland-plugins) and [utilities](https://github.com/hyprwm/contrib) |
| **Smart Window Management** | Dynamic borders with window count detection                                                                       |
| **Network Optimization**    | CAKE qdisc for traffic shaping + TCP tuning                                                                       |
| **Unified Updates**         | osc-fiup.sh - Single script for all flake inputs                                                                  |
| **Thermal Management**      | Scheduled transitions (06:00 and 18:00)                                                                           |
| **Workspace Intelligence**  | Modern expression-based window rules                                                                              |

## 🚀 Installation

> [!CAUTION]
> This configuration may affect your system's behavior. While tested on specific setups, there's no guarantee it will work perfectly on yours.
> **Use at your own risk - I am not responsible for any issues that may arise.**

### Prerequisites

- A fresh NixOS installation (tested with Gnome ISO, "No desktop" option)
- Git
- Basic understanding of NixOS and flakes

### Installation Steps

#### 1. **Fresh NixOS Installation**

First, install NixOS using the [official graphical ISO](https://nixos.org/download.html#nixos-iso).

> [!NOTE]
> Testing has been done using the Gnome graphical installer with the "No desktop" option selected.

#### 2. **Get the Configuration**

After the base NixOS installation, open a terminal and run:

```bash
nix-shell -p git pv vim
git clone https://github.com/kenanpelit/nixosc ~/.nixosc
cd ~/.nixosc
```

> [!IMPORTANT]  
> Before proceeding with the installation, customize your localization settings in:
>
> ```
> # For laptop:
> hosts/hay/templates/initial-configuration.nix
>
> # For VM:
> hosts/vhay/templates/initial-configuration.nix
> ```
>
> Current defaults:
>
> - ⏰ Time Zone: "Europe/Istanbul"
> - 🌐 System Language: "en_US.UTF-8"
> - 🌍 Regional Settings: Turkish (tr_TR.UTF-8)
> - ⌨️ Keyboard Layout: Turkish-F
>
> **References:**
>
> - Timezones: [tz database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
> - Keyboard layouts: `localectl list-x11-keymap-layouts`

#### 3. **Initial System Setup**

Choose one of these methods:

##### A) Automatic Setup (Recommended)

```bash
# For laptop installation:
./install.sh -a hay --pre-install

# For VM installation:
./install.sh -a vhay --pre-install
```

The script will:

- Set up initial configuration
- Perform basic system configuration
- Request a reboot when done

After rebooting, complete the installation:

```bash
# For laptop:
./install.sh -a hay

# For VM:
./install.sh -a vhay
```

##### B) Manual Setup

1. Copy the appropriate configuration:

```bash
# For laptop:
sudo cp hosts/hay/templates/initial-configuration.nix /etc/nixos/configuration.nix

# For VM:
sudo cp hosts/vhay/templates/initial-configuration.nix /etc/nixos/configuration.nix
```

2. Build the initial system:

```bash
sudo nixos-rebuild switch --profile-name start
```

3. Reboot and run the main installation:

```bash
./install.sh
```

#### 4. **Post-Installation**

1. Update Git configuration in `./modules/home/git/default.nix`:

```nix
programs.git = {
   userName = "Your Name";
   userEmail = "your.email@example.com";
};
```

2. Reboot your system
3. Log in - you'll be greeted by hyprlock

#### 5. **Manual Configuration**

Some components need manual configuration:

- Discord theme (in Discord settings under VENCORD > Themes)
- Browser configuration

## 🔧 Flake Inputs & Configuration

### Input Categories (30+ Sources)

**Core System**:

- nixpkgs (`nixos-25.11` channel)
- home-manager (`release-25.11` branch)
- nur (Nix User Repository)

**Hyprland Ecosystem** (15+ inputs):

- hyprland
- hyprlang, hyprutils, hyprland-protocols
- xdph (XDG Desktop Portal), hyprwayland-scanner
- hyprcursor, hyprgraphics, hyprland-qtutils
- hyprland-plugins, hypr-contrib, hyprpicker, hyprmag
- pyprland (Python plugins)

**Applications & Tools**:

- walker - Wayland launcher
- elephant
- spicetify-nix - Spotify customization
- zen-browser - Zen browser flake
- nix-flatpak - Flatpak integration
- nix-search-tv - Package search

**Security & Theming**:

- sops-nix - Secrets management
- catppuccin - Theme framework
- distro-grub-themes - GRUB themes

**Development**:

- poetry2nix - Python package manager
- alejandra - Nix formatter

### Binary Cache Configuration

```nix
nixConfig = {
  extra-substituters = [
    "https://hyprland-community.cachix.org"
    "https://cosmic.cachix.org/"
  ];
  extra-trusted-public-keys = [
    "hyprland-community.cachix.org-1:5dTHY+TjAJjnQs23X+vwMQG4va7j+zmvkTKoYuSUnmE="
    "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
  ];
};
```

### Output Configurations

- `nixosConfigurations.hay` - Laptop system (Hyprland/GNOME/COSMIC)
- `nixosConfigurations.vhay` - VM system (Development optimized)
- `homeConfigurations."kenan@hay"` - Standalone home-manager for laptop
- `homeConfigurations."kenan@vhay"` - Standalone home-manager for VM
- `packages` - Exported packages (pyprland, custom tools)
- `devShells` - Development environments

## 🔧 Utility Scripts

The configuration includes 20+ utility scripts in `modules/home/scripts/bin/`:

<details>
<summary>View All Scripts</summary>

**Desktop Environment Launchers**:

- `hyprland_tty.sh` - Launch Hyprland on TTY
- `cosmic_tty.sh` - Launch Cosmic desktop on TTY
- `gnome_tty.sh` - Launch Gnome desktop on TTY

**System Management**:

- `osc-fiup.sh` - **Unified flake-input updater** (replaces old hypr-specific updater)
- `osc-cleaup-grub.sh` - GRUB cleanup utility
- `osc-rsync.sh` - Rsync backup utility
- `osc-wifi-home.sh` - WiFi home configuration

**UI Controls**:

- `toggle-mic.sh` - Microphone toggle
- `toggle_waybar.sh` - Waybar visibility toggle
- `bluetooth_toggle.sh` - Bluetooth control
- `screenshot.sh` - Screenshot capture tool

**Media & File Management**:

- `semsumo.sh` - Custom utility

**Performance Monitoring**:

- `rofi-performance.sh` - Performance monitoring interface

**Additional Tools**:

- Profile launchers and application-specific scripts
- Custom session managers
- Integration tools for various applications

</details>

## ⌨️ Shell Aliases

<details>
<summary>Utils</summary>

- `c` → `clear`
- `cd` → `z`
- `tt` → `gtrash put`
- `vim` → `nvim`
- `cat` → `bat`
- `nano` → `micro`
- `code` → `codium`
- `py` → `python`
- `icat` → `kitten icat`
- `dsize` → `du -hs`
- `pdf` → `tdf`
- `open` → `xdg-open`
- `space` → `ncdu`
- `man` → `BAT_THEME='default' batman`
- `l` → `eza --icons -a --group-directories-first -1`
- `ll` → `eza --icons -a --group-directories-first -1 --no-user --long`
- `tree` → `eza --icons --tree --group-directories-first`

</details>

<details>
<summary>NixOS</summary>

- `cdnix` → `cd ~/nixosc && codium ~/nixosc`
- `ns` → `nom-shell --run zsh`
- `nix-test` → `nh os test`
- `nix-switch` → `nh os switch`
- `nix-update` → `nh os switch --update`
- `nix-clean` → `nh clean all --keep 5`
- `nix-search` → `nh search`

</details>

<details>
<summary>Git</summary>

- `g` → `lazygit`
- `gf` → `onefetch --number-of-file-churns 0 --no-color-palette`
- `ga` → `git add`
- `gaa` → `git add --all`
- `gs` → `git status`
- `gb` → `git branch`
- `gm` → `git merge`
- `gd` → `git diff`
- `gpl` → `git pull`
- `gplo` → `git pull origin`
- `gps` → `git push`
- `gpso` → `git push origin`
- `gpst` → `git push --follow-tags`
- `gcl` → `git clone`
- `gc` → `git commit`
- `gcm` → `git commit -m`
- `gcma` → `git add --all && git commit -m`
- `gtag` → `git tag -ma`
- `gch` → `git checkout`
- `gchb` → `git checkout -b`
- `glog` → `git log --oneline --decorate --graph`
- `glol` → `git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'`
- `glola` → `git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --all`
- `glols` → `git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --stat`

</details>

## ⌨️ Keybindings

Press `$mainMod F1` to view all keybindings and `$mainMod w` for the wallpaper picker.
Default `$mainMod` is the `SUPER` key.

<details>
<summary>View All Keybindings</summary>

##### General

- `$mainMod, F1` - Show keybinds list
- `$mainMod, Return` - Launch terminal (wezterm)
- `ALT, Return` - Launch floating terminal
- `$mainMod SHIFT, Return` - Launch fullscreen terminal
- `$mainMod, B` - Launch browser
- `$mainMod, Q` - Close active window
- `$mainMod, Space` - Toggle floating
- `$mainMod, D` - Launch application launcher (rofi)
- `$mainMod, Escape` - Lock screen
- `ALT, Escape` - Alternative lock screen
- `$mainMod SHIFT, Escape` - Power menu

##### Workspace Management

- `$mainMod, 1-9` - Switch to workspace 1-9
- `$mainMod SHIFT, 1-9` - Move window to workspace 1-9
- `$mainMod CTRL, c` - Move to empty workspace

##### Window Management

- `$mainMod, left/right/up/down` - Focus window
- `$mainMod SHIFT, left/right/up/down` - Move window
- `$mainMod CTRL, left/right/up/down` - Resize window
- `$mainMod ALT, left/right/up/down` - Move window precisely

##### Media Controls

- `XF86AudioRaiseVolume` - Volume up
- `XF86AudioLowerVolume` - Volume down
- `XF86AudioMute` - Toggle mute
- `XF86AudioPlay` - Play/pause
- `XF86AudioNext` - Next track
- `XF86AudioPrev` - Previous track

##### Screenshots

- `$mainMod, Print` - Save area screenshot
- `Print` - Copy area screenshot

[Full keybinding configuration](modules/home/hyprland/conf/hyprland.conf)

</details>

## 🧠 Extended Hyprland Features

The configuration includes numerous Hyprland extensions and plugins:

- **Core Ecosystem Components**:
  - hyprlang - Language parsing for Hyprland configuration
  - hyprcursor - Custom cursor library
  - xdph - XDG Desktop Portal implementation
  - hyprland-protocols - Wayland protocol definitions

- **Plugins & Utilities**:
  - PyPrland - Python plugin system for scripting Hyprland
  - hypr-contrib - Additional community utilities
  - hyprpicker - Color picker utility
  - hyprmag - Screen magnification tool

- **Graphics & Integration**:
  - hyprgraphics - Graphics library
  - hyprland-qtutils - Qt integration
  - hyprwayland-scanner - Protocol scanner

## 🖥️ Alternative Environments

This configuration includes support for alternative desktop environments:

- **COSMIC Desktop** (System76's desktop environment)
  - Integrated via nixos-cosmic module
  - Configured with proper binary cache

## 🛠️ Customization

### Module Architecture

The configuration uses a **6-layer dependency system** with Single Authority Principle:

1. **Foundation Layer** - Basic system requirements
2. **Build Layer** - Compilation and build tools
3. **Desktop Layer** - Display and audio systems
4. **Network Layer** - Network connectivity
5. **Security Layer** - Security policies
6. **Services Layer** - User-facing services

### Core Modules (9 System Modules)

<details>
<summary>View Core Modules</summary>

1. **account** - User management & home-manager integration
2. **system** - Boot loader, kernel, hardware, thermal, power management
3. **nix** - Nix daemon, garbage collection, binary caches, overlays
4. **packages** - System-wide packages (CLI tools, libraries)
5. **display** - Wayland, Hyprland, GDM, fonts, PipeWire audio
6. **networking** - NetworkManager, systemd-resolved, VPN, TCP tuning, CAKE qdisc
7. **security** - Firewall, PAM, AppArmor, SSH, audit, DNS ad-blocking
8. **services** - Flatpak, Podman/Libvirt, Steam/Gamescope, D-Bus, GVFS, TRIM
9. **sops** - SOPS configuration, age encryption, secret management

Detailed documentation in `modules/core/default.nix` (1095+ lines).

</details>

### Home Modules (78+ Application Modules)

<details>
<summary>View All Home Modules</summary>

**Desktop Environment** (8 modules):

- hyprland, sway, cosmic, gnome, waybar, rofi, swaylock, mako, swayosd, blue, waypaper, wpaperd

**Terminal & Shell** (6 modules):

- foot, kitty, wezterm, tmux, zsh, starship

**Development** (4 modules):

- nvim, git, lazygit, sesh

**Browsers** (5 modules):

- firefox, chrome, brave, vivaldi, zen

**Media** (5 modules):

- audacious, mpv, vlc, mpd, cava

**Communication** (2 modules):

- webcord, elektron

**File Management** (9 modules):

- nemo, yazi, fzf, rsync, ytdlp, btop, fastfetch, search, walker

**Productivity** (6 modules):

- obsidian, clipse, anydesk, transmission, connect, subliminal

**Security** (3 modules):

- gnupg, password-store, sops

**System Integration** (7 modules):

- catppuccin, gtk, qt, xdg-dirs, xdg-mimes, xdg-portal, xserver, candy

**Input** (2 modules):

- fusuma, touchegg

**AI & Advanced** (4 modules):

- ai, flatpak, packages, program

**Scripts** (3 sub-modules):

- bin.nix, start.nix, default.nix

</details>

### Adding New Packages

Edit `modules/home/default.nix` to add user packages or `modules/core/packages/default.nix` for system-wide packages.

### Changing Themes

The configuration uses Catppuccin Mocha by default. Modify `modules/home/catppuccin/` for theme customization.

### Wallpapers

Add custom wallpapers to `wallpapers/` directory. Use `$mainMod w` to access the wallpaper picker.

## 📚 Documentation

For more detailed information:

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Hyprland Documentation](https://wiki.hyprland.org/)
- [PyPrland Documentation](https://github.com/hyprland-community/pyprland)
- [COSMIC Desktop](https://github.com/pop-os/cosmic)

## 👥 Credits

Special thanks to:

- [Frost-Phoenix/nixos-config](https://github.com/Frost-Phoenix/nixos-config) for inspiration and examples
- All component creators and maintainers
- NixOS and Hyprland communities
- The Catppuccin team for the beautiful theme framework
- All flake input maintainers and contributors

## 📊 Project Stats

- **Version**: 4.2.0
- **NixOS State**: 25.11
- **Hyprland**
- **Core Modules**: 9 system modules
- **Home Modules**: 78+ application modules
- **Flake Inputs**: 30+ sources
- **Utility Scripts**: 20+ custom scripts
- **Configuration Lines**: 1095+ (core module documentation alone)
- **Last Updated**: November 19, 2025

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

<!-- Component Links -->
