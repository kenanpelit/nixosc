# hosts/vhay/default.nix
# ==============================================================================
# VHAY Virtual Machine: Main Host Configuration
# ==============================================================================
# This module defines the specific configuration for the 'vhay' virtual machine.
#
# Key Configurations:
# - Imports hardware configuration and all core system modules.
# - Sets the hostname to 'vhay'.
# - Configures NetworkManager.
# - Sets timezone and locale.
# - Configures SSH server access with development-oriented settings.
# - Defines essential system packages for a VM environment.
# - Specifies system state version.
#
# ==============================================================================
{ pkgs, lib, inputs, username, ... }:

{
  # ============================================================================
  # Imports
  # ============================================================================
  imports = [
    ./hardware-configuration.nix
    ../../modules/core
  ];

  # ============================================================================
  # Host Identity
  # ============================================================================
  networking.hostName = "vhay";

  # ============================================================================
  # Networking
  # ============================================================================
  networking = {
    networkmanager.enable = true;
  };

  # Timezone & Locale (Inherited from core/system)
  time.timeZone = "Europe/Istanbul";


  # ============================================================================
  # SSH / Security
  # (Development oriented, loose settings)
  # ============================================================================
  services.openssh = {
    enable = true;
    ports  = [ 22 ];

    settings = {
      PasswordAuthentication = true;
      PermitRootLogin        = "yes";
      AllowUsers             = [ username ];
    };
  };

  # ============================================================================
  # System Packages
  # (Basic VM packages)
  # ============================================================================
  environment.systemPackages = with pkgs; [
    tmux
    ncurses
    git
    neovim
    htop
    networkmanager
  ];

  # ============================================================================
  # System State Version
  # ============================================================================
  system.stateVersion = "25.11";
}
