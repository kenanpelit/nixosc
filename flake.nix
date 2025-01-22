# ==============================================================================
# NixOS System Configuration Flake
# Author: Kenan Pelit
# Description: Main configuration file for NixOS system setup
#
# This flake defines the complete NixOS system configuration, including:
# - Package management and overlays
# - User environment (via home-manager) 
# - System services and settings
# - Hardware-specific configurations
# ==============================================================================
{
 description = "Kenan's nixos configuration";
 
 # Define all external dependencies and inputs
 # Each input represents a source for packages, modules, or configurations
 inputs = {
   # === Core System Packages ===
   # Main repository for most packages
   nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
   
   # === User Environment Management ===
   # Home-manager for user-specific configurations  
   home-manager = {
     url = "github:nix-community/home-manager";
     inputs.nixpkgs.follows = "nixpkgs";  # Use the same nixpkgs as above
   };
   
   # Community package repository for additional software
   nur = {
     url = "github:nix-community/NUR";
     inputs.nixpkgs.follows = "nixpkgs";  # Ensure version compatibility
   };
   
   # === Security and Secrets Management ===
   # For managing sensitive configuration data
   sops-nix = {
     url = "github:Mic92/sops-nix";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   
   # === GRUB Theme ===
   # Custom GRUB bootloader themes
   distro-grub-themes = {
     url = "github:AdisonCavani/distro-grub-themes";
     inputs.nixpkgs.follows = "nixpkgs";
   };
 
   # === Desktop Environment - Hyprland Ecosystem ===
   # Core Hyprland compositor
   hyprland = {
     url = "github:hyprwm/hyprland/e66eab7b6a90514251439f661454c536afa3e5c8";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   
   # Essential Hyprland plugins
   hyprland-plugins = {
     url = "github:hyprwm/hyprland-plugins";
     inputs.hyprland.follows = "hyprland";
   };
   
   # Additional Hyprland utilities and tools
   hypr-contrib = {
     url = "github:hyprwm/contrib";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   
   hyprpicker = {
     url = "github:hyprwm/hyprpicker";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   
   hyprmag = {
     url = "github:SIMULATAN/hyprmag";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   
   hyprpanel = {
     url = "github:hyprland-community/hyprpanel";
     inputs.nixpkgs.follows = "nixpkgs";
   };

   # === Development Tools ===
   # Nix code formatter and linter
   alejandra = {
     url = "github:kamadorueda/alejandra/3.0.0";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   
   # === Application Customization ===
   # Spotify customization framework
   spicetify-nix = {
     url = "github:gerg-l/spicetify-nix";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   
   # === System Integration and Tools ===
   # Flatpak integration for additional software support
   nix-flatpak = {
     url = "github:gmodena/nix-flatpak";
   };
   
   # Enhanced browser configuration
   zen-browser = {
     url = "github:0xc000022070/zen-browser-flake";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   
   # Chrome
   browser-previews = {
     url = "github:nix-community/browser-previews";
     inputs.nixpkgs.follows = "nixpkgs";
   };

   # Binary cache management
   cachix-pkgs = {
     url = "github:cachix/cachix";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   
   # === Terminal and File Management ===
   # Terminal file manager plugins (raw source)
   yazi-plugins = {
     url = "github:yazi-rs/plugins";
     flake = false;  # Raw source, not a Nix flake
   };
 };
 
 # System outputs and configurations
 outputs = { nixpkgs, self, home-manager, sops-nix, distro-grub-themes, ... }@inputs:
   let
     # === Global Variables ===
     username = "kenan";        # Primary user account
     system = "x86_64-linux";   # System architecture
     
     # Configure nixpkgs with system-wide settings
     pkgs = import nixpkgs {
       inherit system;
       config = {
         allowUnfree = true;  # Enable proprietary software
         permittedInsecurePackages = [
           # Add any required insecure packages here
           # "example-package-1.0.0"
         ];
       };
     };
     
     # Import nixpkgs library for helper functions
     lib = nixpkgs.lib;
     
     # === System Configuration Helper ===
     # Function to create a complete NixOS system configuration
     mkSystem = { system, host, modules }: 
       nixpkgs.lib.nixosSystem {
         inherit system;
         
         # Add default and machine-specific modules
         modules = [
           # GRUB theme module for all systems
           distro-grub-themes.nixosModules.${system}.default
           
           # Home-manager integration
           inputs.home-manager.nixosModules.home-manager
           {
             home-manager = {
               useGlobalPkgs = true;
               useUserPackages = true;
               extraSpecialArgs = {
                 inherit inputs username host;
               };
             };
           }
         ] ++ modules;  # Add machine-specific modules
         
         # Pass additional arguments to all modules
         specialArgs = {
           inherit self inputs username host system;
         };
       };
   in
   {
     # === Machine Configurations ===
     nixosConfigurations = {
       # Personal laptop configuration
       hay = mkSystem {
         inherit system;
         host = "hay";
         modules = [ ./hosts/hay ];
       };
       
       # Development VM configuration
       vhay = mkSystem {
         inherit system;
         host = "vhay";
         modules = [ ./hosts/vhay ];
       };
     };
      # You can add additional outputs here, such as:
      # - Development shells
      # - Custom packages
      # - NixOS modules
      # - Home-manager modules
    };
}
