# systems/x86_64-linux/vhay/default.nix
# ==============================================================================
# VHAY Virtual Machine: Main Host Configuration
# ==============================================================================
{ pkgs, lib, inputs, ... }:

let
  username = "kenan";
in
{
  imports = [
    ./hardware-configuration.nix
    # Modules are now automatically imported by flake.nix via Snowfall Lib
  ];

  # ============================================================================
  # Host Metadata
  # ============================================================================
  my.host = {
    role           = "vm";
    isPhysicalHost = false;
    isVirtualHost  = true;
  };

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