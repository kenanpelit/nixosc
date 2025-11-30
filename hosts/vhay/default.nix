# ==============================================================================
# VHAY - NixOS Host Configuration
# Main system configuration for the "vhay" virtual machine
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
