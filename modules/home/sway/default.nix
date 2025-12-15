# modules/home/sway/default.nix
# ==============================================================================
# Home module for Sway session helpers (VM/testing usage).
# Installs sway-related utilities and user config via Home Manager.
# ==============================================================================

{ config, lib, pkgs, ... }:
let
  cfg = config.my.desktop.sway;
in
{
  options.my.desktop.sway = {
    enable = lib.mkEnableOption "Sway VM manager configuration";
  };

  config = lib.mkIf cfg.enable {
    # XDG configuration files for Sway VM management
    xdg.configFile = {
      
      # NixOS Virtual Machine Configuration
      # Launches NixOS VM in fullscreen mode for development work
      "sway/qemu_vmnixos" = {
        text = ''
          # Launch NixOS VM using the svmnixos command
          exec svmnixos
          
          # Force QEMU windows to fullscreen for better VM experience
          for_window [app_id="qemu"] fullscreen enable
        '';
        executable = true;
      };
      
      # Arch Linux Virtual Machine Configuration  
      # Launches Arch VM in fullscreen mode for testing purposes
      "sway/qemu_vmarch" = {
        text = ''
          # Launch Arch Linux VM using the svmarch command
          exec svmarch
          
          # Force QEMU windows to fullscreen for immersive experience
          for_window [app_id="qemu"] fullscreen enable
        '';
        executable = true;
      };
      
      # Ubuntu Virtual Machine Configuration
      # Launches Ubuntu VM in fullscreen mode for general use
      "sway/qemu_vmubuntu" = {
        text = ''
          # Launch Ubuntu VM using the svmubuntu command
          exec svmubuntu
          
          # Force QEMU windows to fullscreen for optimal viewing
          for_window [app_id="qemu"] fullscreen enable
        '';
        executable = true;
      };
      
    }; # End of xdg.configFile
  };
} # End of module
