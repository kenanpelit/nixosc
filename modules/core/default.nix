# modules/core/default.nix
# ==============================================================================
# Core System Configuration
# Author: Kenan Pelit
# Description: Centralized imports for all core system modules
# ==============================================================================
{ inputs, nixpkgs, self, username, host, lib, ... }:
{
 imports = [
   # =============================================================================
   # Audio and Media
   # =============================================================================
   ./audio          # Audio subsystem configuration
   ./pipewire       # Modern audio/video framework
   
   # =============================================================================
   # System Services
   # =============================================================================
   ./bootloader     # Boot loader and EFI configuration
   ./services       # Core system services
   ./xserver        # X server configuration
   ./wayland        # Wayland display server
   
   # =============================================================================
   # Hardware Management
   # =============================================================================
   ./hardware       # Hardware detection and support
   ./bluetooth      # Bluetooth subsystem
   ./power          # Power management and TLP

   # =============================================================================
   # Network and Security
   # =============================================================================
   ./network        # Network stack configuration
   ./mullvad        # VPN client and configuration
   ./security       # System security settings
   ./ssh            # SSH configuration
   ./gnupg          # GPG key management
   ./hblock         # Blocking ads, tracking and malware

   # =============================================================================
   # Package Management
   # =============================================================================
   ./flatpak        # Flatpak application support
   ./packages       # System package management
   ./nh             # Nix helper utilities
   ./nixconf        # Nix configuration settings

   # =============================================================================
   # User Environment
   # =============================================================================
   ./fonts          # Font configuration
   ./program        # Core system programs
   ./user           # User account management
   
   # =============================================================================
   # Virtualization and Gaming
   # =============================================================================
   ./podman         # Container runtime
   ./virtualization # Virtual machine support
   ./steam          # Gaming platform support

   # =============================================================================
   # Core Configuration
   # =============================================================================
   ./system         # Base system settings
 ];
}
