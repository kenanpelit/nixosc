# modules/core/desktop/default.nix
# ==============================================================================
# Desktop Environment Configuration
# ==============================================================================
# This configuration file manages all desktop-related settings including:
# - Wayland display server
# - X11 server configuration
# - Font management and rendering
# - Display portals and desktop integration
#
# Key components:
# - Hyprland Wayland compositor
# - X.org server setup
# - System-wide font configuration
# - XDG portal integration
#
# Author: Kenan Pelit
# ==============================================================================

{ inputs, pkgs, lib, username, ... }:
{
 # =============================================================================
 # Wayland Configuration
 # =============================================================================
 programs.hyprland = {
   enable = true;
   package = inputs.hyprland.packages.${pkgs.system}.default;
   portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
 };

 # =============================================================================
 # X Server Configuration
 # =============================================================================
 services = {
   # X Server Settings
   xserver = {
     enable = true;
     # Keyboard Configuration
     xkb = {
       layout = "tr";
       variant = "f";
       options = "ctrl:nocaps";  # Caps Lock as Ctrl
     };
   };

   # Display Manager Settings
   displayManager.autoLogin = {
     enable = true;
     user = "${username}";
   };

   # Input Device Settings
   libinput.enable = true;  # Enable libinput for input devices
 };

 # =============================================================================
 # XDG Portal Configuration
 # =============================================================================
 xdg.portal = {
   enable = true;
   xdgOpenUsePortal = true;
   
   # Default Portal Configuration
   config = {
     common.default = [ "gtk" ];
     hyprland.default = [
       "gtk"
       "hyprland"
     ];
   };

   # Additional Portals
   extraPortals = [
     pkgs.xdg-desktop-portal-gtk
   ];
 };

 # =============================================================================
 # Font Configuration
 # =============================================================================
 fonts = {
   # Font Packages
   packages = with pkgs; [
     nerd-fonts.hack
   ];

   # Font Settings
   fontconfig = {
     # Default Fonts
     defaultFonts = {
       monospace = [ "Hack Nerd Font Mono" ];
       sansSerif = [ "Hack Nerd Font" ];
       serif = [ "Hack Nerd Font" ];
     };

     # Rendering Settings
     subpixel = {
       rgba = "rgb";
       lcdfilter = "default";
     };

     # Hinting Configuration
     hinting = {
       enable = true;
       autohint = true;
     };

     # Anti-aliasing
     antialias = true;

     # Custom Font Configuration
     localConf = ''
       <?xml version="1.0"?>
       <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
       <fontconfig>
         <match target="font">
           <test name="family" compare="contains">
             <string>Hack Nerd Font</string>
           </test>
           <edit name="antialias" mode="assign">
             <bool>true</bool>
           </edit>
         </match>
       </fontconfig>
     '';
   };
   
   enableDefaultPackages = true;
 };

 # =============================================================================
 # Environment Configuration
 # =============================================================================
 environment = {
   variables = {
     FONTCONFIG_PATH = "/etc/fonts";
   };
 };

 # =============================================================================
 # User Application Font Settings
 # =============================================================================
 home-manager.users.${username} = {
   home.stateVersion = "25.05";
   
   # Dunst notification font
   services.dunst.settings.global = {
     font = "Hack Nerd Font 13";
   };

   # Rofi font setting
   programs.rofi.font = "Hack Nerd Font 13";
 };

 # =============================================================================
 # Systemd Configuration
 # =============================================================================
 systemd.extraConfig = "DefaultTimeoutStopSec=10s";
}
