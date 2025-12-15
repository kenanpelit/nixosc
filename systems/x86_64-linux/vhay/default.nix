# systems/x86_64-linux/vhay/default.nix
# ==============================================================================
# vHAY virtual machine host config.
# Imports hardware config; module imports handled via flake/Snowfall.
# Set VM metadata and services/desktops toggles below.
# ==============================================================================
{ pkgs, lib, inputs, ... }:

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

  # ============================================================================
  # System Packages
  # (Basic VM packages)
  # ============================================================================
  environment.systemPackages = with pkgs; [
    networkmanager
    openssl
  ];

  # ============================================================================
  # System State Version
  # ============================================================================
  system.stateVersion = "25.11";
}
