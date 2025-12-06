# modules/home/fusuma/default.nix
# ==============================================================================
# Fusuma Touchpad Gesture Configuration
# ==============================================================================
{ config, pkgs, lib, ... }:
let
  cfg = config.my.user.fusuma;
in
{
  options.my.user.fusuma = {
    enable = lib.mkEnableOption "Fusuma gesture recognizer";
  };

 config = lib.mkIf cfg.enable {
   # =============================================================================
   # Service Configuration
   # =============================================================================
   services.fusuma = {
    enable = true;
    package = pkgs.fusuma;
     # =============================================================================
     # Gesture Settings
     # =============================================================================
     settings = {
       # ---------------------------------------------------------------------------
       # Sensitivity Settings
       # ---------------------------------------------------------------------------
       threshold = {
         swipe = 0.7;
         pinch = 0.3;
       };
       # ---------------------------------------------------------------------------
       # Timing Settings
       # ---------------------------------------------------------------------------
       interval = {
         swipe = 0.6;
         pinch = 1.0;
       };
       # ---------------------------------------------------------------------------
       # Gesture Mappings
       # ---------------------------------------------------------------------------
       swipe = {
         "3" = {
           right = {
             command = "${pkgs.wtype}/bin/wtype -M ctrl -k TAB";
             threshold = 0.6;
           };
           left = {
             command = "${pkgs.wtype}/bin/wtype -M ctrl -M shift -k TAB";
             threshold = 0.6;
           };
         };
       };
     };
   };
 };
}
