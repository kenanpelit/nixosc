# modules/default.nix
# ==============================================================================
# NixOS System Configuration
# ==============================================================================
# This is the root configuration file that manages both system-level (core) and 
# user-level (home) configurations.
#
# Core (/modules/core):
# - System: Core settings, bootloader, drivers
# - Desktop: Display servers, fonts
# - Gaming: Gaming-related configs and tools
# - Media: Audio and bluetooth services
# - Network: Networking, VPN, firewall
# - Nix: Package manager configuration
# - Security: System security, encryption
# - Services: System-wide services
# - System: Hardware and base settings
# - User: User accounts management
# - Virtualization: VM and container support
#
# Home (/modules/home):
# - Apps: General user applications
# - Browser: Web browsers and extensions
# - Desktop: DE/WM, bars, notifications
# - Development: Programming tools and IDEs
# - File: File managers and tools
# - Gnome: GNOME-specific configurations
# - Media: Audio/video applications
# - Network: Network tools and VPN clients
# - Security: User-level security tools
# - Services: User services
# - System: System utilities
# - Terminal: Shell and terminal emulators
# - Utility: General utility programs
# - XDG: XDG base directory compliance
#
# Structure:
# /modules
# ├── core/              # System-level configuration
# │   ├── desktop       # Display and UI
# │   ├── gaming        # Gaming support
# │   ├── media         # Audio/video
# │   ├── network       # Network stack
# │   ├── nix          # Package management
# │   ├── security     # System security
# │   ├── services     # System services
# │   ├── system       # Core settings
# │   ├── user         # User management
# │   └── virtualization# VM support
# │
# └── home/             # User-level configuration
#     ├── apps         # User applications
#     ├── browser      # Web browsers
#     ├── desktop      # DE/WM config
#     ├── development  # Dev tools
#     ├── file         # File management
#     ├── gnome        # GNOME settings
#     ├── media        # Media tools
#     ├── network      # Network utils
#     ├── security     # User security
#     ├── services     # User services
#     ├── system       # System tools
#     ├── terminal     # Shell environment
#     ├── utility      # General utils
#     └── xdg          # XDG compliance
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
