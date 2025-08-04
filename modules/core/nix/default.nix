# modules/core/nix/default.nix
# ==============================================================================
# Nix Ecosystem Configuration
# ==============================================================================
# This configuration manages Nix system settings including:
# - Core Nix daemon and store optimization
# - NH (Nix Helper) tool configuration
# - Nixpkgs configuration and overlays
# - Garbage collection and maintenance
# - Package permissions and experimental features
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, inputs, username, ... }:
{
  # Core Nix Configuration
  nix = {
    settings = {
      # User Access Settings
      allowed-users = [ "${username}" "root" ];
      trusted-users = [ "${username}" "root" ];
      
      # Store Optimization Settings
      auto-optimise-store = true;
      keep-outputs = true;
      keep-derivations = true;
      sandbox = true;
    };
    
    # Garbage Collection
    gc = {
      automatic = lib.mkIf (!config.programs.nh.clean.enable) true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    
    # Store Optimization
    optimise = {
      automatic = true;
      dates = [ "03:00" ];
    };
    
    # Experimental Features
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Nixpkgs Configuration
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    overlays = [ inputs.nur.overlays.default ];
  };

  # NH (Nix Helper) Configuration
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 5";  # Retention policy
    };
    flake = "/home/${username}/.nixosc";
  };
  
  # Nix Utilities
  environment.systemPackages = with pkgs; [
    nix-tree
  ];
}

