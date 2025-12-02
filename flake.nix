{
  description = "Kenan's NixOS Configuration - Snowfall Edition";

  inputs = {
    # Core
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # System
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland
    hyprland = {
      url = "github:hyprwm/hyprland/bb963fb00263bac78a0c633d1d0d02ae4763222c";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hypr-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyprland = {
      url = "github:hyprland-community/pyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Theming
    catppuccin.url = "github:catppuccin/nix";
    distro-grub-themes.url = "github:AdisonCavani/distro-grub-themes";

    # Tools
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    alejandra = {
      url = "github:kamadorueda/alejandra";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Apps
    walker.url = "github:abenz1267/walker/v2.11.3";
    
    elephant = {
      url = "github:abenz1267/elephant/v2.16.1";
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

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
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
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;

      snowfall = {
        namespace = "my"; # Opsiyonel namespace
        
        # Modül yolları (varsayılan değerler)
        # modules.nixos = "./modules/nixos";
        # modules.home = "./modules/home";
      };

      channels-config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "electron-36.9.5"
          "ventoy-1.1.07"
          "libsoup-2.74.3"
        ];
      };

      overlays = with inputs; [
        nur.overlays.default
      ];

      # Tüm sistemlere otomatik eklenecek modüller
      systems.modules.nixos = with inputs; [
        home-manager.nixosModules.home-manager
        catppuccin.nixosModules.catppuccin
        sops-nix.nixosModules.sops
        # Global argümanları modül sistemine enjekte et
        ({ ... }: {
          _module.args.username = "kenan";
        })
      ];

      # Sistemlere özel argümanlar
      systems.specialArgs = {
        username = "kenan";
      };
    };
}