# ==============================================================================
#  NixOS Configuration Flake - Snowfall Edition
# ==============================================================================
#
#  Author:  Kenan Pelit
#  Repo:    https://github.com/kenanpelit/nixosc
#  License: MIT
#  Date:    2025-12-06
#
# ------------------------------------------------------------------------------
#  ARCHITECTURE
# ------------------------------------------------------------------------------
#
#  Snowfall Lib v4 layout, with NixOS + Home Manager under one flake.
#
#  Structure (workspace-write sandbox friendly):
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
#    $ ./install.sh install <host>        # system + home for host
#    $ nixos-rebuild switch --flake .#hay # direct call
#    $ home-manager switch --flake .#kenan@hay # home only
#
#  Update Inputs:
#    $ ./install.sh update
#
# ==============================================================================

{
  description = "Kenan's NixOS Configuration - Modern, Modular, Snowfall-based";

  inputs = {
    # ==========================================================================
    # Core (Foundation)
    # ==========================================================================
    # - nixpkgs: pinned NixOS channel
    # - snowfall-lib: repo structure + mkFlake glue
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
    # - sops-nix: secret management
    # - NUR: extra packages/overlays
    # - nixos-hardware: device profiles
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
    # This repo uses multiple Wayland compositors.
    # Keep them pinned for reproducibility (especially for greeter/session paths).
    hyprland = {
      inputs.nixpkgs.follows = "nixpkgs";
      # pinned (glaze override uyumlu)
      url = "github:hyprwm/hyprland/6175ecd4c4ba817c4620f66a75e1e11da7c7a8ca"; # 1219 - Updated commit
#      url = "github:hyprwm/hyprland/f58c80fd3942034d58934ec4e4d93bfcfa3c786e"; # pinned
    };

    hypr-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyprland = {
      url = "github:hyprland-community/pyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Niri: A scrollable-tiling Wayland compositor.
    # Using sodiboo's flake for better NixOS/HM integration and binary cache.
    niri.url = "github:sodiboo/niri-flake";

    # nsticky: A helper for creating "sticky" windows in niri (scratchpad-like behavior).
    nsticky.url = "github:lonerOrz/nsticky";

    # ==========================================================================
    # Desktop: Theming
    # ==========================================================================
    # - catppuccin: theming modules + palettes
    # - distro-grub-themes: GRUB theme assets
    catppuccin.url = "github:catppuccin/nix";
    distro-grub-themes.url = "github:AdisonCavani/distro-grub-themes";

    # ==========================================================================
    # Desktop: Shell (DankMaterialShell / DMS)
    # ==========================================================================
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankMaterialShell = {
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.dgop.follows = "dgop";
      url = "github:AvengeMedia/DankMaterialShell/f2611e0de093d3b300165a67b695ed561e181297"; # 1219 - Updated commit
#      url = "github:AvengeMedia/DankMaterialShell/76006a73771d9413092a9330a9014133fa0f9b10"; # 1219 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/2a91bc41f7aa8cb5734fe4b3d50c577090aba348"; # 1219 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/baf23157fc334b5607bcb5f89919fbe04e9ccd5d"; # 1218 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/8437e1aa7b34021aa9c97882fdbda2cca6d43878"; # 1218 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/78a5f401d76d575fb88757ad812dcda0adc24e3e"; # 1218 - Updated commit
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
    # Optional GUI tools and helper flakes.
    walker.url = "github:abenz1267/walker/v2.12.2";

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

    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nix-search-tv.url = "github:3timeslazy/nix-search-tv";

    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };
  };

  outputs = inputs:
    let
      lib = inputs.nixpkgs.lib;
    in
    lib.removeAttrs
      (inputs.snowfall-lib.mkFlake {
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
        ];

        # Modules automatically added to all NixOS systems.
        systems.modules.nixos = with inputs; [
          home-manager.nixosModules.home-manager
          # DMS upstream renamed `nixosModules.dankMaterialShell` -> `nixosModules.dank-material-shell`.
          # Using `default` keeps us compatible and avoids the deprecation warning.
          dankMaterialShell.nixosModules.default
          nix-flatpak.nixosModules.nix-flatpak
          {
            home-manager.sharedModules = [
              niri.homeModules.niri
            ];
          }
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

              nixos-hay = inputs.self.nixosConfigurations.hay.config.system.build.toplevel;
              nixos-vhay = inputs.self.nixosConfigurations.vhay.config.system.build.toplevel;
              home-kenan-hay = inputs.self.homeConfigurations."kenan@hay".activationPackage;
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
      })
      [ "snowfall" ];
}
