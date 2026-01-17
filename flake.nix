# ==============================================================================
#  NixOS Configuration Flake - Snowfall Edition
# ==============================================================================
#
#  Author:  Kenan Pelit
#  Repo:    https://github.com/kenanpelit/nixosc
#  License: MIT
#  Date:    2025-12-06 (initial Snowfall v4 migration)
#
# ------------------------------------------------------------------------------
#  ARCHITECTURE
# ------------------------------------------------------------------------------
#
#  Snowfall-lib v4 layout: NixOS + Home Manager in a single repo.
#
#  Structure:
#    ├── systems/              # Host configs per arch (hay, vhay, …)
#    ├── homes/                # Home Manager profiles (e.g. kenan@hay)
#    ├── modules/
#    │   ├── nixos/            # System-level modules (services, hardware)
#    │   └── home/             # User-level modules (HM apps/services)
#    ├── overlays/             # Nixpkgs overlays
#    ├── secrets/              # sops-nix secrets (age key in ~/.config/sops/age)
#    ├── assets/               # Encrypted dotfiles, mpv/tmux bundles, etc.
#    └── wallpapers/           # Theming assets
#
# ------------------------------------------------------------------------------
#  USAGE
# ------------------------------------------------------------------------------
#
#  Build & Switch:
#    $ ./install.sh install <host>                 # system + home for host
#    $ nixos-rebuild switch --flake .#hay          # system only
#    $ home-manager switch --flake .#kenan@hay     # home only
#
#  Update Inputs (pin bumps):
#    $ ./install.sh update                          # flake update flow
#    $ osc-fiup {dank|hypr|stasis|walker}           # targeted bump helpers
#
# ==============================================================================

{
  description = "Kenan's NixOS Configuration - Modern, Modular, Snowfall-based";

  # NOTE: We intentionally do not set `nixConfig.extra-substituters` here.
  # Substituters/trusted keys are managed centrally via `modules/nixos/nix`.
  # Keeping only one source avoids drift between `flake.nix` and system policy.

  inputs = {
    # ==========================================================================
    # Core (Foundation)
    # ==========================================================================
    # - nixpkgs: base package set and module tree (pinned to a release branch)
    # - snowfall-lib: repo layout + mkFlake glue
    # - home-manager: user-level configuration
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ==========================================================================
    # System (NixOS modules / hardware / secrets)
    # ==========================================================================
    # - sops-nix: secret management via SOPS
    # - NUR: extra packages/overlays
    # - nixos-hardware: hardware profiles
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # ==========================================================================
    # Desktop: Compositors / WMs
    # ==========================================================================
    # This repo uses multiple Wayland compositors; we keep them pinned for
    # reproducibility and to prevent session/greeter breakage between updates.

    # Hyprland: Dynamic tiling Wayland compositor
    hyprland = {
      inputs.nixpkgs.follows = "nixpkgs";
      # Pinned commit (updated via `osc-fiup hypr`)
      url = "github:hyprwm/hyprland/92a3b9199939c8b7b61281d1d59dbaa9cc2b2d6c"; # 0117 - Updated commit
#      url = "github:hyprwm/hyprland/36aa465a216002169879a60416d2f10c28741162"; # 0117 - Updated commit
      #      url = "github:hyprwm/hyprland/0b13d398fe597c9b30beb8207828586718b8a9b0"; # 0116 - Updated commit
      #      url = "github:hyprwm/hyprland/ac9df44788492fd1d12da8ec0fbbf691386c45a4"; # 0115 - Updated commit
      #      url = "github:hyprwm/hyprland/e0cf88809de12c39ad8a1ad1c0194967b0029ec8"; # 0114 - Updated commit
      #      url = "github:hyprwm/hyprland/8d03fcc8d76245be013254ea30fbe534f680dc9f"; # 0112 - Updated commit
    };

    hypr-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyprland = {
      url = "github:hyprland-community/pyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland plugins (upstream)
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
      inputs.systems.follows = "hyprland/systems";
    };

    # Niri: Scrollable-tiling Wayland compositor
    # Using sodiboo's flake for better integration (HM module + overlay wiring).
    # Upstream niri itself is pulled via `inputs.niri-unstable` (pinned in flake.lock).
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.niri-unstable.url = "github:YaLTeR/niri/main";
    };

    # Nsticky: Helper for creating "sticky" windows (scratchpads) in Niri
    nsticky = {
      url = "github:kenanpelit/nsticky";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ==========================================================================
    # Desktop: Theming
    # ==========================================================================
    # - catppuccin: Global theming modules + palettes
    # - distro-grub-themes: GRUB bootloader themes
    catppuccin.url = "github:catppuccin/nix";
    distro-grub-themes.url = "github:AdisonCavani/distro-grub-themes";

    # ==========================================================================
    # Desktop: Shell (DankMaterialShell / DMS)
    # ==========================================================================
    # - dgop: Dependency for DMS
    # - dankMaterialShell: Advanced Quickshell-based desktop shell
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankMaterialShell = {
      inputs.nixpkgs.follows = "nixpkgs";
      # Pinned commit (updated via `osc-fiup dank`)
      url = "github:AvengeMedia/DankMaterialShell/ec8ab4746228f53e3885f9319c2a3121d60cc4fe"; # 0117 - Updated commit
#      url = "github:AvengeMedia/DankMaterialShell/d7b7086b215834a8fae5a8021efca6989d5b8370"; # 0116 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/d6dacc29759c9591d4df9a6b11f08698520773ac"; # 0116 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/c992f2b582d6b0f8a3de598e7a8448012c9a4399"; # 0116 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/3243adebca1b3e6b0cc764aa0ccbac0168e88fdc"; # 0116 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/623eec3689b803489b66abf47918ea7af022b737"; # 0115 - Updated commit
    };

    # ==========================================================================
    # Dev Tools / Lint / Format
    # ==========================================================================
    # These are used in `outputs-builder` for checks and devShell tooling.
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    statix = {
      url = "github:nerdypepper/statix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deadnix = {
      url = "github:astro/deadnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    alejandra = {
      url = "github:kamadorueda/alejandra";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dsearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ==========================================================================
    # Apps / Extras
    # ==========================================================================
    # Optional GUI tools, app launchers, and helper flakes.
    #walker = {
    #  url = "github:abenz1267/walker/v2.13.0";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};

    #elephant = {
    #  url = "github:abenz1267/elephant/v2.18.2";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};

    browser-previews = {
      url = "github:nix-community/browser-previews";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cachix-pkgs = {
      url = "github:cachix/cachix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:gerg-l/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stasis = {
      inputs.nixpkgs.follows = "nixpkgs";
      # Pinned commit (updated via `osc-fiup stasis`)
      url = "github:saltnpepper97/stasis/dde31c01e2d4aca672f95dd13a735c9430b0d016"; # 0114 - Updated commit
#      url = "github:saltnpepper97/stasis/ee98c8f55f137b24c6262dbecf4c0fa178075c60"; # 0113 - Updated commit
      #      url = "github:saltnpepper97/stasis/201de746ba3a3348d955cf100c0fbbe11f3b106d"; # 0112 - Updated commit
      #      url = "github:saltnpepper97/stasis/6dba64776cb20097e08f6d905e3ac8ec8769a4ab"; # 0111 - Updated commit
      #      url = "github:saltnpepper97/stasis/8f519faaa032a0170cd5ae516388d895b4d4dd83"; # 0106 - Updated commit
      #      url = "github:saltnpepper97/stasis/b6efb72a13ac91b0f48204b99cbf98e0d033a131"; # 0104 - Updated commit
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nix-search-tv.url = "github:3timeslazy/nix-search-tv";

    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };
  };

  outputs = inputs @ { self, nixpkgs, snowfall-lib, ... }:
    let
      lib = nixpkgs.lib;
    in
    # snowfall-lib produces an internal `snowfall` attribute; hide it to keep
    # `nix flake show` focused on real outputs.
    lib.removeAttrs (snowfall-lib.mkFlake {
        inherit inputs;
        src = ./.;

        snowfall = {
          # Custom namespace for internal modules (e.g. `my.*` options).
          namespace = "my";
        };

        # Global nixpkgs config (applies to all systems/homes in this flake).
        channels-config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "electron-36.9.5"
            "ventoy-1.1.07"
            "libsoup-2.74.3"
          ];
        };

        # Overlays applied to all systems.
        overlays = with inputs; [
          nur.overlays.default
          niri.overlays.niri
          (import ./overlays/xdg-desktop-portal-wlr-niri.nix)
          (import ./overlays/xdg-desktop-portal-gnome-niri.nix)
        ];

        # Modules automatically added to all NixOS systems.
        systems.modules.nixos = with inputs; [
          home-manager.nixosModules.home-manager
          # DMS upstream renamed `nixosModules.dankMaterialShell` -> `nixosModules.dank-material-shell`.
          # Using `default` keeps us compatible and avoids the deprecation warning.
          dankMaterialShell.nixosModules.default
          nix-flatpak.nixosModules.nix-flatpak
        ];

        # Special arguments available to all modules.
        systems.specialArgs = {
          username = "kenan";
        };

        outputs-builder =
          channels:
          let
            system = channels.nixpkgs.stdenv.hostPlatform.system;
            alejandra = inputs.alejandra.packages.${system}.default;
            statix = inputs.statix.packages.${system}.default;
            deadnix = inputs.deadnix.packages.${system}.default;
            treefmt = channels.nixpkgs.treefmt;
          in
          {
            # Default formatter for the repo.
            formatter = alejandra;

            # CI-friendly checks (run locally via `nix flake check`).
            checks = {
              statix = channels.nixpkgs.runCommand "statix-check" {
                nativeBuildInputs = [ statix ];
              } ''
                statix check ${./.}
                touch $out
              '';

              deadnix = channels.nixpkgs.runCommand "deadnix-check" {
                nativeBuildInputs = [ deadnix ];
              } ''
                deadnix --fail ${./.}
                touch $out
              '';

              treefmt = channels.nixpkgs.runCommand "treefmt-check" {
                nativeBuildInputs = [ treefmt ];
              } ''
                treefmt --fail-on-change --clear-cache --check ${./.}
                touch $out
              '';

              # Keep these here so CI fails early if a host or home breaks.
              nixos-hay = self.nixosConfigurations.hay.config.system.build.toplevel;
              nixos-vhay = self.nixosConfigurations.vhay.config.system.build.toplevel;
              home-kenan-hay = self.homeConfigurations."kenan@hay".activationPackage;
            };

            # Developer shell: quick access to repo tooling.
            devShells.default = channels.nixpkgs.mkShell {
              packages = [
                alejandra
                statix
                deadnix
              ];
            };
          };
      }) [ "snowfall" ];
}
