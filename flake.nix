# ==============================================================================
#
#   NixOS System Configuration Flake
#   Project: NixOS Configuration Suite (nixosc)
#   Version: 3.0.0
#   Date: 2025-05-12
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#
#   Overview:
#     - Full-stack NixOS configuration (system + home-manager)
#     - Modular, host-aware, theme-enabled, and battery-included
#     - Single source of truth for overlays & nixpkgs config
#
#   Rationale / Key ideas:
#     - One overlay list (overlaysCommon) injected consistently into:
#         1) top-level pkgs (import nixpkgs …)
#         2) nixosSystem via a tiny module (nixpkgs.overlays = overlaysCommon)
#         3) pkgsFor (packages/devShells multi-system world)
#       This removes the “works here, breaks there” class of overlay bugs.
#
#     - Temporary compatibility bridge (shim):
#         buildGo123Module → buildGoModule (Go 1.25)
#       Why? nixpkgs removed buildGo123Module (Go 1.23 is EOL). Some external
#       flakes still call it. The shim keeps builds green while they migrate.
#       Remove the shim once your deps stop calling buildGo123Module.
#
#     - Central nixpkgs config (allowUnfree + permittedInsecurePackages)
#       declared once then reused everywhere to avoid divergence.
#
#   Notes:
#     - External flakes (e.g. some apps you import as inputs) often build with
#       *their own* nixpkgs; your overlays may not affect them. If a package
#       fails *inside a foreign flake*, pin or patch that flake instead.
#
#   License: MIT
#
# ==============================================================================

{
  description = "Kenan's NixOS Configuration";

  # ============================================================================
  # INPUTS
  #   Pin every dependency through flake.lock for reproducibility.
  #   Keep follows = "nixpkgs" where practical to ensure ABI alignment.
  # ============================================================================
  inputs = {
    # Core package universe (nixos-unstable gives fresh software)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Quick rollback pin template (uncomment to force a specific revision):
    # nixpkgs.url = "github:NixOS/nixpkgs/b5d4232";

    # User environment management
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Community repository (NUR)
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets (SOPS)
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Theming (Catppuccin)
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # GRUB themes
    distro-grub-themes = {
      url = "github:AdisonCavani/distro-grub-themes";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland ecosystem (pinned for stability)
    hyprland = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:hyprwm/hyprland/adbf7c8663cfbc91fca78d3504fa8f73ce4bd23a"; # 0913 - Updated Commits
#      url = "github:hyprwm/hyprland/46174f78b374b6cea669c48880877a8bdcf7802f";
    };
    hyprlang              = { url = "github:hyprwm/hyprlang";                   inputs.nixpkgs.follows = "nixpkgs"; };
    hyprutils             = { url = "github:hyprwm/hyprutils";                  inputs.nixpkgs.follows = "nixpkgs"; };
    hyprland-protocols    = { url = "github:hyprwm/hyprland-protocols";         inputs.nixpkgs.follows = "nixpkgs"; };
    xdph                  = { url = "github:hyprwm/xdg-desktop-portal-hyprland";inputs.nixpkgs.follows = "nixpkgs"; };
    hyprwayland-scanner   = { url = "github:hyprwm/hyprwayland-scanner";        inputs.nixpkgs.follows = "nixpkgs"; };
    hyprcursor            = { url = "github:hyprwm/hyprcursor";                 inputs.nixpkgs.follows = "nixpkgs"; };
    hyprgraphics          = { url = "github:hyprwm/hyprgraphics";               inputs.nixpkgs.follows = "nixpkgs"; };
    hyprland-qtutils      = { url = "github:hyprwm/hyprland-qtutils";           inputs.nixpkgs.follows = "nixpkgs"; };
    hyprland-plugins      = { url = "github:hyprwm/hyprland-plugins";           inputs.nixpkgs.follows = "nixpkgs"; };
    hypr-contrib          = { url = "github:hyprwm/contrib";                    inputs.nixpkgs.follows = "nixpkgs"; };
    hyprpicker            = { url = "github:hyprwm/hyprpicker";                 inputs.nixpkgs.follows = "nixpkgs"; };
    hyprmag               = { url = "github:SIMULATAN/hyprmag";                 inputs.nixpkgs.follows = "nixpkgs"; };

    # Hyprland Python plugin framework
    pyprland = {
      url = "github:hyprland-community/pyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Poetry2nix (build Python apps via poetry.lock)
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Multi-system support (list of linux arches)
    systems = {
      url = "github:nix-systems/default-linux";
    };

    # Flake compat for legacy (non-flake) tooling
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    # Dev tools, app customization, integrations
    alejandra       = { url = "github:kamadorueda/alejandra/3.1.0"; inputs.nixpkgs.follows = "nixpkgs"; };
    spicetify-nix   = { url = "github:gerg-l/spicetify-nix";        inputs.nixpkgs.follows = "nixpkgs"; };
    nix-flatpak     = { url = "github:gmodena/nix-flatpak"; };
    zen-browser     = { url = "github:0xc000022070/zen-browser-flake"; inputs.nixpkgs.follows = "nixpkgs"; };
    browser-previews= { url = "github:nix-community/browser-previews"; inputs.nixpkgs.follows = "nixpkgs"; };
    cachix-pkgs     = { url = "github:cachix/cachix";               inputs.nixpkgs.follows = "nixpkgs"; };

    # Raw source (not a flake) — used as data only
    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };

    # External tool (beware: may compile with its own nixpkgs)
    nix-search-tv = {
      url = "github:3timeslazy/nix-search-tv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Optional: COSMIC (currently disabled; keep around for future testing)
    # nixos-cosmic = {
    #   url = "github:lilyinstarlight/nixos-cosmic";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  # ============================================================================
  # OUTPUTS
  #   Centralize overlay & config setup and “thread” it through everything.
  # ============================================================================
  outputs = { nixpkgs, self, home-manager, sops-nix, distro-grub-themes, poetry2nix, systems, pyprland
            , hyprland, hyprlang, hyprutils, hyprland-protocols, xdph, hyprcursor, catppuccin, ... }@inputs:
    let
      # --- Global knobs ---
      username = "kenan";       # Primary user
      system   = "x86_64-linux";# Host architecture

      # --- Single source of truth: overlaysCommon ---
      # IMPORTANT: NUR changed its overlay export path; correct usage is
      # inputs.nur.overlays.default (NOT inputs.nur.overlay).
      overlaysCommon = [
        # NUR overlay (new API, replaces `nur.overlay`)
        inputs.nur.overlays.default

        # Temporary compat shim: reintroduce `buildGo123Module` by delegating to
        # `buildGoModule` with Go 1.25. Remove once all consumers are updated.
        (final: prev: {
          buildGo123Module = args:
            prev.buildGoModule (args // { go = prev.go_1_25; });
        })

        # TigerVNC build fix: provide autoreconf tooling so the *nested* autoreconf
        # call works, without forcing an autoreconfPhase at repo root.
        (final: prev: {
          tigervnc = prev.tigervnc.overrideAttrs (old: {
            nativeBuildInputs =
              (old.nativeBuildInputs or []) ++ [
                prev.autoconf
                prev.automake
                prev.libtool
              ];
          });
        })
      ];

      # --- Central nixpkgs config applied everywhere ---
      nixpkgsConfigCommon = {
        allowUnfree = true;
        # Only keep what you really need here. Insecure packages are a footgun;
        # document why each is allowed and remove as soon as possible.
        permittedInsecurePackages = [
          "ventoy-1.1.07"   # Binary blobs; used for multiboot USB creation
          "libsoup-2.74.3"  # EOL legacy GTK dep (audit and phase out)
          "qtwebengine-5.15.19" # Old QtWebEngine; phase out when viable
        ];
      };

      # --- Top-level pkgs (handy for ad hoc use) ---
      # NOTE: This pkgs is *not* the one used by nixosSystem unless we pass it.
      # We still create it for convenience and any out-of-band scripting.
      pkgs = import nixpkgs {
        inherit system;
        overlays = overlaysCommon;
        config   = nixpkgsConfigCommon;
      };

      # Shorthand to nixpkgs lib
      lib = nixpkgs.lib;

      # --- System constructor (DRY for multiple hosts) ---
      # We inject overlays & config via a tiny module at the top of the module list.
      mkSystem = { system, host, modules }:
        lib.nixosSystem {
          inherit system;

          modules = [
            # 1) Ensure the NixOS module graph uses the same overlays & nixpkgs config
            {
              nixpkgs.overlays = overlaysCommon;
              nixpkgs.config   = nixpkgsConfigCommon;
            }

            # 2) System-wide theming / modules
            # GRUB themes (arch-specific selection from the input)
            inputs.distro-grub-themes.nixosModules.${system}.default

            # Catppuccin NixOS module (for system theming)
            inputs.catppuccin.nixosModules.catppuccin

            # 3) Home-manager (sharing the *same* pkgs universe)
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs   = true; # reuse the NixOS pkgs for consistency
                useUserPackages = true; # install to /etc/profiles
                extraSpecialArgs = { inherit inputs username host; };
                users.${username} = {
                  imports = [
                    inputs.catppuccin.homeModules.catppuccin
                    ./modules/home
                  ];
                };
              };
            }

            # 4) Optional global system packages
            # Caution: Packages from *other flakes* may compile with their own nixpkgs,
            # meaning overlaysCommon may not affect them. If that causes issues,
            # comment them out or patch the foreign flake.
            {
              environment.systemPackages = [
                # inputs.nix-search-tv.packages.${system}.default
                # inputs.walker.packages.${system}.default
              ];
            }

            # 5) Safety net: also set permittedInsecure here (mirrors common config)
            # This ensures the NixOS evaluation inherits the same allowances.
            {
              nixpkgs.config.permittedInsecurePackages = nixpkgsConfigCommon.permittedInsecurePackages;
            }
          ] ++ modules;

          # Pass useful handles to all modules (hosts can read these if needed)
          specialArgs = { inherit self inputs username host system; };
        };

      # --- Poetry2nix helpers (to build Python projects reproducibly) ---
      inherit (inputs.poetry2nix.lib) mkPoetry2Nix;

      # --- Multi-system fabric (for packages & devShells across arches) ---
      eachSystem = lib.genAttrs (import systems);

      # pkgsFor: per-system nixpkgs with the same overlays & config.
      pkgsFor = eachSystem (sys:
        import nixpkgs {
          localSystem = sys;
          overlays    = overlaysCommon;
          config      = nixpkgsConfigCommon;
        }
      );
    in
    {
      # ==========================================================================
      # NixOS HOSTS
      #   Add new machines by cloning one of these entries with a different module.
      # ==========================================================================
      nixosConfigurations = {
        hay  = mkSystem { inherit system; host = "hay";  modules = [ ./hosts/hay  ]; };
        vhay = mkSystem { inherit system; host = "vhay"; modules = [ ./hosts/vhay ]; };
      };

      # ==========================================================================
      # PACKAGES (per-system)
      #   Example: build the pyprland application using poetry2nix.
      #   Access via: `nix build .#pyprland` (on matching system)
      # ==========================================================================
      packages = eachSystem (sys:
        let inherit (mkPoetry2Nix { pkgs = pkgsFor.${sys}; }) mkPoetryApplication;
        in {
          pyprland = mkPoetryApplication {
            projectDir  = nixpkgs.lib.cleanSource "${pyprland}";
            checkGroups = []; # disable optional check groups for faster builds
          };
        }
      );

      # ==========================================================================
      # DEV SHELLS
      #   Example: enter a Poetry-enabled shell for pyprland dev:
      #   `nix develop .#pyprland`
      # ==========================================================================
      devShells = eachSystem (sys:
        let inherit (mkPoetry2Nix { pkgs = pkgsFor.${sys}; }) mkPoetryEnv;
        in {
          pyprland = pkgsFor.${sys}.mkShellNoCC {
            packages = with pkgsFor.${sys}; [
              (mkPoetryEnv { projectDir = "${pyprland}"; })
              poetry
            ];
          };
        }
      );
    };

  # ============================================================================
  # BINARY CACHE (nixConfig)
  #   These are *flake-level* cache hints used by Nix when building this flake.
  #   Add more substituters/keys here if you rely on 3rd-party caches.
  # ============================================================================
  nixConfig = {
    extra-substituters = [
      "https://hyprland-community.cachix.org"
      # "https://cosmic.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland-community.cachix.org-1:5dTHY+TjAJjnQs23X+vwMQG4va7j+zmvkTKoYuSUnmE="
      # "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
    ];
  };
}


