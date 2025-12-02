# modules/nixos/account/default.nix
# ==============================================================================
# User Account & Home Manager Integration
# ==============================================================================
# Manages the primary user account, groups, sudo privileges, and integrates
# Home Manager into the NixOS configuration.
# ==============================================================================

{ pkgs, lib, config, inputs, ... }:

let
  inherit (lib) mkOption mkIf types;
  cfg = config.my;
in
{
  # ============================================================================
  # Module Options
  # ============================================================================
  options.my = {
    user = {
      name = mkOption {
        type = types.str;
        default = "kenan";
        description = "Primary user account name.";
      };

      description = mkOption {
        type = types.str;
        default = "Kenan";
        description = "Full name of the primary user.";
      };

      shellPackage = mkOption {
        type = types.package;
        default = pkgs.zsh;
        description = "Login shell package (e.g. pkgs.zsh).";
      };

      extraGroups = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Additional groups for the primary user.";
      };
    };

    home = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Home Manager integration.";
      };

      stateVersion = mkOption {
        type = types.str;
        default = "25.11";
        description = "Home Manager state version.";
      };
    };

    security.passwordlessSudo = mkOption {
      type = types.bool;
      default = true;
      description = "Enable passwordless sudo for the wheel group.";
    };
  };

  # ============================================================================
  # Configuration
  # ============================================================================
  config = let
    userName = cfg.user.name;
  in
  {
    # -- User Account ----------------------------------------------------------
    users.users.${userName} = {
      isNormalUser = true;
      description  = cfg.user.description;
      shell        = cfg.user.shellPackage;
      extraGroups  = [
        "wheel" "networkmanager" "storage" "input" 
        "audio" "video" "libvirtd" "kvm"
      ] ++ cfg.user.extraGroups;
    };

    # -- Sudo Configuration ----------------------------------------------------
    security.sudo.wheelNeedsPassword = !cfg.security.passwordlessSudo;

    # -- Home Manager Integration ----------------------------------------------
    home-manager = mkIf cfg.home.enable {
      useGlobalPkgs   = true;
      useUserPackages = true;
      backupFileExtension = "backup";

      # Pass arguments to Home Manager modules
      extraSpecialArgs = {
        inherit inputs pkgs;
        host     = config.networking.hostName;
        username = userName;
      };

      users.${userName} = {
        # Import user modules and external HM modules
        imports = [ 
          ../../user-modules
          inputs.catppuccin.homeModules.catppuccin
        ]; 

        home = {
          username      = userName;
          homeDirectory = "/home/${userName}";
          stateVersion  = cfg.home.stateVersion;
        };

        programs.home-manager.enable = true;
      };
    };
  };
}