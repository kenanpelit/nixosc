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
    # Core Dependencies
    # ==========================================================================
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
    # System Components
    # ==========================================================================
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
    # Desktop Environment (Hyprland)
    # ==========================================================================
    hyprland = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:hyprwm/hyprland/8dfdcfb35385eabb821e668d327b30ea3e483ab8"; # 1212 - Updated commit
#      url = "github:hyprwm/hyprland/f58c80fd3942034d58934ec4e4d93bfcfa3c786e"; # 1210 - Updated commit (glaze override uyumlu)
      # url = "github:hyprwm/hyprland/9aa313402b1be3df2925076bb1292d03e68bb47f"; # 1211 - Glaze override hatası veriyor
    };

    hypr-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyprland = {
      url = "github:hyprland-community/pyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ==========================================================================
    # Theming
    # ==========================================================================
    catppuccin.url = "github:catppuccin/nix";
    distro-grub-themes.url = "github:AdisonCavani/distro-grub-themes";

    # ==========================================================================
    # Development Tools
    # ==========================================================================
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    statix = {
      url = "github:nerdypepper/statix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankMaterialShell = {
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.dgop.follows = "dgop";
      url = "github:AvengeMedia/DankMaterialShell/77fd61f81e981a76be60a94a10ac1db4b8b0a106"; # 1212 - Updated commit
#      url = "github:AvengeMedia/DankMaterialShell/89dcd72d703d525d2034f616ecf19823d5f50457"; # 1212 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/bdc0e8e0fcd370ae5532b4f5c642241286a0958e"; # 1212 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/0709f263af1ecfc9d1a6fa0ad7ac2bf0cbf41da2"; # 1211 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/38db6a41d54f30c5c042fda548d2443852fa3896"; # 1211 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/72cfd37ab796b26b19bc0227070d09dcc0a1c6a0"; # 1211 - Updated commit
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
    # Applications
    # ==========================================================================
    walker.url = "github:abenz1267/walker/v2.12.2";
    
    elephant = {
      url = "github:abenz1267/elephant/v2.17.1";
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
          namespace = "my"; # Custom namespace for internal modules
          
          # Default paths are used:
          # modules/nixos -> System modules
          # modules/home  -> (Not used, we use modules/user-modules manually)
        };

        # Global Nixpkgs configuration
        channels-config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "electron-36.9.5"
            "ventoy-1.1.07"
            "libsoup-2.74.3"
          ];
        };

        # Overlays applied to all systems
        overlays = with inputs; [
          nur.overlays.default
        ];

        # Modules automatically added to all NixOS systems
        systems.modules.nixos = with inputs; [
          home-manager.nixosModules.home-manager
          dankMaterialShell.nixosModules.dankMaterialShell
          nix-flatpak.nixosModules.nix-flatpak
        ];

        # Special arguments available to all modules
        systems.specialArgs = {
          username = "kenan";
        };

              outputs-builder = channels: let
                system = channels.nixpkgs.stdenv.hostPlatform.system;
                alejandra = inputs.alejandra.packages.${system}.default;
                statix = inputs.statix.packages.${system}.default;
                deadnix = inputs.deadnix.packages.${system}.default;
                treefmt = channels.nixpkgs.treefmt;
              in {
                formatter = alejandra;
                
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

                devShells.default = channels.nixpkgs.mkShell {
                  packages = [
                    alejandra
                    statix
                    deadnix
                  ];
                };
              };      })
      [ "snowfall" ];
}
