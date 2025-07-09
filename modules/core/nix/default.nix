# modules/core/nix/default.nix
# ==============================================================================
# Nix Settings Configuration - Simplified
# ==============================================================================
# This configuration manages core Nix settings including:
# - Store optimization
# - Garbage collection
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, username, ... }:
{
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
    
    # Experimental Features - Always set, to make sure it's effective
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  
  # Add only essential Nix utilities 
  environment.systemPackages = with pkgs; [
    nix-tree
  ];
}

