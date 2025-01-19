# modules/default.nix
# ==============================================================================
# NixOS System Configuration
# ==============================================================================
# This is the root configuration file that manages both system-level (core) and 
# user-level (home) configurations.
#
# Core (/modules/core):
# - System Services: Audio, network, security, virtualization
# - Hardware Management: Bootloader, drivers, power settings
# - Base Configuration: Localization, keyboard, system version
# - Package Management: System-wide packages and Nix settings
#
# Home (/modules/home):
# - Desktop Environment: Window managers, bars, notifications
# - User Applications: Browsers, media players, development tools
# - Shell Environment: Terminal emulators, ZSH, utilities
# - Personal Settings: Themes, keybindings, application configs
#
# Structure:
# /modules
# ├── core/           # System-level configuration
# │   ├── media      # Audio and bluetooth
# │   ├── desktop    # Display servers and fonts
# │   ├── system     # Core system settings
# │   ├── network    # Networking and VPN
# │   ├── security   # System security and encryption
# │   ├── services   # System services
# │   ├── user       # User accounts
# │   ├── gaming     # Gaming support
# │   └── nix        # Nix package manager config
# │
# └── home/          # User-level configuration
#     ├── apps      # User applications
#     ├── desktop   # DE/WM configuration
#     ├── dev       # Development tools
#     ├── media     # Media applications
#     ├── system    # User system tools
#     ├── terminal  # Terminal environment
#     └── security  # User security tools
#
# Author: Kenan Pelit
# ==============================================================================
{ inputs, nixpkgs, self, username, host, lib, ... }:

{
 imports = [
   ./core           # System-level configuration (NixOS)
   ./home           # User-level configuration (Home Manager)
 ];
}
