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
      url = "github:hyprwm/hyprland/0b3b012817ca381e40754cb4408e5c0cd3a2c732"; # 0104 - Updated commit
#      url = "github:hyprwm/hyprland/583c4074a5d4229f841d9e470ab427339773b592"; # 0104 - Updated commit
      #      url = "github:hyprwm/hyprland/ee67278038b5b6597172b2a3ee9d57f6ad0eafc7"; # 0103 - Updated commit
      #url = "github:hyprwm/hyprland/v0.53.1"; # v0.53.1
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
      url = "github:AvengeMedia/DankMaterialShell/f163b97c1733e7536ec7e51edfcea1a702d36d32"; # 0104 - Updated commit
#      url = "github:AvengeMedia/DankMaterialShell/166843ded45ee31f52b8bb93c5cb4cd30ca9196a"; # 0104 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/e1817027b1aafee74fd7d38ef109c932cb6758de"; # 0103 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/3e1c6534bdcc234bba90351f714f075d2672f526"; # 0102 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/bae32e51ff6d873e51e29fe20fee378714aba150"; # 0101 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/edfda965e9902f6bfd7f26558d67eff0a1d71942"; # 0101 - Updated commit
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
    walker = {
      url = "github:abenz1267/walker/v2.12.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    elephant = {
      url = "github:abenz1267/elephant/v2.17.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      url = "github:saltnpepper97/stasis/b6efb72a13ac91b0f48204b99cbf98e0d033a131"; # 0104 - Updated commit
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
