# modules/core/account/default.nix
# ==============================================================================
# User Account & Home-Manager Integration (Single-User Focused)
# ==============================================================================
#
# Module:      modules/core/account
# Purpose:     Declarative primary user, groups, sudo policy and HM wiring
# Author:      Kenan Pelit
# Last Edited: 2025-11-15
#
# Design Goals:
#   1. Single source of truth for the *primary* user
#   2. Clear, minimal and composable options (my.user / my.home / my.security)
#   3. Safe defaults, but easy to tighten or relax on a per-host basis
#   4. Strong but honest boundaries (no fake "ONLY here" guarantees)
#
# Notes:
#   - This module assumes a *single main user* on a laptop/desktop.
#   - Additional users should be defined in a separate module if needed.
#
# ==============================================================================

{ pkgs, lib, username, config, inputs, host, ... }:

let
  inherit (lib) mkOption mkIf types;

  cfg = config.my;
in
{
  # ============================================================================
  # Module Options
  # ============================================================================

  options.my = {
    # --------------------------------------------------------------------------
    # Primary User Options
    # --------------------------------------------------------------------------
    user = {
      name = mkOption {
        type = types.str;
        default = username;
        description = ''
          Primary user account name.

          Default: the "username" argument passed from the flake.
        '';
      };

      description = mkOption {
        type = types.str;
        default = username;
        description = ''
          Full name or description for the primary user.
        '';
      };

      shellPackage = mkOption {
        type = types.package;
        default = pkgs.zsh;
        description = ''
          Login shell package for the primary user (e.g. pkgs.zsh, pkgs.bashInteractive).
        '';
      };

      extraGroups = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Additional groups to add on top of the base workstation groups.

          Base groups are:
            - wheel, networkmanager, storage
            - input, audio, video
            - libvirtd, kvm
        '';
      };
    };

    # --------------------------------------------------------------------------
    # Home-Manager Options
    # --------------------------------------------------------------------------
    home = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable Home-Manager for the primary user and wire it to modules/home.
        '';
      };

      stateVersion = mkOption {
        type = types.str;
        default = "25.11";
        description = ''
          Home-Manager state version.

          IMPORTANT:
          - Set this once when you start using Home-Manager on this machine.
          - Do NOT bump it casually; it controls migration behavior.
        '';
      };
    };

    # --------------------------------------------------------------------------
    # Security / Sudo Options
    # --------------------------------------------------------------------------
    security.passwordlessSudo = mkOption {
      type = types.bool;
      default = true;
      description = ''
        If true, members of the wheel group can sudo without a password.

        Trade-offs:
          - true  : Faster workflow, less friction (but weaker local security)
          - false : Stronger local security, more typing
      '';
    };
  };

  # ============================================================================
  # Concrete Configuration
  # ============================================================================

  config = let
    userName = cfg.user.name;
  in
  {
    # --------------------------------------------------------------------------
    # User Account Definition
    # --------------------------------------------------------------------------
    users.users.${userName} = {
      isNormalUser = true;
      description  = cfg.user.description;
      shell        = cfg.user.shellPackage;

      # Base workstation groups:
      #   - wheel          : admin / sudo
      #   - networkmanager : manage network / Wi-Fi / VPN
      #   - storage        : access removable storage
      #   - input          : input devices
      #   - audio          : audio stack
      #   - video          : GPU / hardware acceleration
      #   - libvirtd, kvm  : virtualization
      extraGroups =
        [
          "wheel"
          "networkmanager"
          "storage"
          "input"
          "audio"
          "video"
          "libvirtd"
          "kvm"
        ]
        ++ cfg.user.extraGroups;
    };

    # Optional: leave this to another module if you want a more global policy.
    # users.mutableUsers = false;
    #
    # Rationale:
    #   - Keeping this unset avoids surprising behavior on existing systems.
    #   - If you want fully declarative users, set users.mutableUsers = false
    #     in a higher-level "security" or "policy" module.

    # --------------------------------------------------------------------------
    # Sudo Policy (Passwordless Switch)
    # --------------------------------------------------------------------------
    security.sudo = {
      wheelNeedsPassword = !cfg.security.passwordlessSudo;

      # Example: cache sudo credentials for 30 minutes (disabled by default).
      # extraConfig = ''
      #   Defaults timestamp_timeout=30
      # '';
    };

    # --------------------------------------------------------------------------
    # Home-Manager Wiring for Primary User
    # --------------------------------------------------------------------------
    home-manager = mkIf cfg.home.enable {
      # Reuse system pkgs to avoid multiple nixpkgs trees.
      useGlobalPkgs = true;

      # Install user-specific packages to the user profile.
      useUserPackages = true;

      # Keep a backup of pre-existing dotfiles on first activation.
      backupFileExtension = "backup";

      # Extra arguments passed to all Home-Manager modules.
      # - host     : current host descriptor from the flake
      # - username : primary user name (resolved via my.user.name)
      # - inputs   : flake inputs (for pinning, overlays, etc.)
      # - pkgs     : package set (sometimes handy inside HM modules)
      extraSpecialArgs = {
        inherit inputs host pkgs;
        username = userName;
      };

      users.${userName} = {
        # Main user configuration tree:
        #   modules/home/default.nix + submodules
        imports = [ ../../home ];

        home = {
          username      = userName;
          homeDirectory = "/home/${userName}";
          stateVersion  = cfg.home.stateVersion;
        };

        # Allow Home-Manager to manage itself (hm command).
        programs.home-manager.enable = true;
      };
    };

    # --------------------------------------------------------------------------
    # Explicit Non-Responsibilities (for clarity)
    # --------------------------------------------------------------------------
    #
    # This module deliberately does NOT configure:
    #   - Display manager / desktop environment
    #   - DBus, keyring or PAM services
    #   - NetworkManager itself
    #   - Podman / Docker / virtualization runtimes
    #
    # Those belong in:
    #   - modules/core/display
    #   - modules/core/services
    #   - modules/core/networking
    #   - modules/core/virtualization
    #
    # This module only owns:
    #   - Primary user account
    #   - Group memberships for that user
    #   - Sudo policy toggle
    #   - Home-Manager integration for that user
    #
    # --------------------------------------------------------------------------
  };
}
