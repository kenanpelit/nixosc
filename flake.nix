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
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

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

    # Niri: Scrollable-tiling Wayland compositor
    # Using sodiboo's flake for better integration (HM module + overlay wiring).
    # Upstream niri itself is pulled via `inputs.niri-unstable` (pinned in flake.lock).
    niri = {
      url = "github:sodiboo/niri-flake";
      # Track niri against unstable nixpkgs, independent from the system base channel.
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs-stable.follows = "nixpkgs";
      inputs.niri-unstable.url = "github:YaLTeR/niri/main";
    };

    # ==========================================================================
    # Desktop: Theming
    # ==========================================================================
    # - catppuccin: Global theming modules + palettes
    # - distro-grub-themes: GRUB bootloader themes
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    distro-grub-themes = {
      url = "github:AdisonCavani/distro-grub-themes";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      # Pinned commit (bumped intentionally via `osc-fiup dank` + flake.lock).
      url = "github:AvengeMedia/DankMaterialShell/fce120fa311282ddd41866cfca47a3723fa26c54"; # 0209 - Updated commit
      # url = "github:AvengeMedia/DankMaterialShell/5b8b7b04be165f7979bac9a42157ff054f1dcca8";
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
    #  url = "github:abenz1267/walker/v2.14.1";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};

    #elephant = {
    #  url = "github:abenz1267/elephant/v2.19.1";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};

    browser-previews = {
      url = "github:nix-community/browser-previews";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    snowfall-lib,
    ...
  }: let
    lib = nixpkgs.lib;
  in
    # snowfall-lib produces an internal `snowfall` output; hide it so
    # `nix flake show` stays focused on consumable outputs.
    lib.removeAttrs (snowfall-lib.mkFlake {
      inherit inputs;
      # Keep evaluation/build source clean:
      # - include only files needed by flake/module evaluation
      # - drop CI metadata from the source closure
      src = lib.cleanSourceWith {
        src = ./.;
        filter = path: type: let
          rel = lib.removePrefix "${toString ./.}/" (toString path);
        in
          lib.cleanSourceFilter path type
          && !(rel == ".github" || lib.hasPrefix ".github/" rel);
      };

      snowfall = {
        # Custom namespace for internal modules (e.g. `my.*` options).
        namespace = "my";
      };

      # Global nixpkgs policy shared by systems/homes.
      # Keep insecure allowlist here so every pkgs instance (NixOS, HM, checks,
      # overlays importing nixpkgs with inherited config) sees the same policy.
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
        # Expose a second package set pinned to `nixos-unstable`, so we can
        # selectively track newer packages (e.g. Hyprland) without moving the
        # whole system off the stable channel.
        (final: prev: {
          unstable = import inputs."nixpkgs-unstable" {
            system = prev.stdenv.hostPlatform.system;
            config = prev.config;
          };
        })
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

      outputs-builder = channels: let
        system = channels.nixpkgs.stdenv.hostPlatform.system;
        unstablePkgs = inputs."nixpkgs-unstable".legacyPackages.${system};
        # Prefer unstable tool versions when available, but keep stable
        # fallback so branch updates never block local tooling.
        toolFromChannels = name:
          if builtins.hasAttr name unstablePkgs
          then unstablePkgs.${name}
          else channels.nixpkgs.${name};
        alejandra = toolFromChannels "alejandra";
        statix = toolFromChannels "statix";
        deadnix = toolFromChannels "deadnix";
        treefmt = toolFromChannels "treefmt";
        # Optional checks: only emit attrs for hosts/homes that exist.
        mkNixosChecks = hosts:
          if self ? nixosConfigurations
          then
            lib.listToAttrs (
              map
              (host: {
                name = "nixos-${host}";
                value = self.nixosConfigurations.${host}.config.system.build.toplevel;
              })
              (builtins.filter (host: builtins.hasAttr host self.nixosConfigurations) hosts)
            )
          else {};
        mkHomeChecks = homes:
          if self ? homeConfigurations
          then
            lib.listToAttrs (
              map
              (home: {
                name = "home-${builtins.replaceStrings ["@"] ["-"] home}";
                value = self.homeConfigurations.${home}.activationPackage;
              })
              (builtins.filter (home: builtins.hasAttr home self.homeConfigurations) homes)
            )
          else {};
      in {
        # Default formatter for the repo.
        formatter = alejandra;

        # CI-friendly checks (run locally via `nix flake check`).
        checks =
          {
            statix =
              channels.nixpkgs.runCommand "statix-check" {
                nativeBuildInputs = [statix];
              } ''
                statix check ${./.}
                touch $out
              '';

            deadnix =
              channels.nixpkgs.runCommand "deadnix-check" {
                nativeBuildInputs = [deadnix];
              } ''
                deadnix --fail ${./.}
                touch $out
              '';

            treefmt =
              channels.nixpkgs.runCommand "treefmt-check" {
                nativeBuildInputs = [treefmt];
              } ''
                treefmt --fail-on-change --clear-cache --check ${./.}
                touch $out
              '';
          }
          # Keep critical targets in CI, but only when they exist.
          // mkNixosChecks ["hay" "vhay"]
          // mkHomeChecks ["kenan@hay"];

        # Developer shell: same core toolchain used by checks.
        devShells.default = channels.nixpkgs.mkShell {
          packages = [
            alejandra
            statix
            deadnix
            treefmt
          ];
        };
      };
    }) ["snowfall"];
}
