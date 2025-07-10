# modules/home/xdg-mimes/default.nix
# ==============================================================================
# XDG MIME Type Configuration
# ==============================================================================
{ pkgs, lib, ... }:
with lib;
let
 # =============================================================================
 # Default Applications Map
 # =============================================================================
 defaultApps = {
   browser = [ "brave-browser.desktop" ];
   text = [ "kitty-nvim.desktop" ];
   image = [ "imv-dir.desktop" ];
   audio = [ "mpv.desktop" ];
   video = [ "mpv.desktop" ];
   directory = [ "nemo.desktop" ];
   office = [ "libreoffice.desktop" ];
   pdf = [ "org.gnome.Evince.desktop" ];
   terminal = [ "kitty.desktop" ];
   archive = [ "org.gnome.FileRoller.desktop" ];
   discord = [ "webcord.desktop" ];
 };
 # =============================================================================
 # MIME Type Mapping
 # =============================================================================
 mimeMap = {
   # Text Types
   text = [ "text/plain" ];
   # Image Types
   image = [
     "image/bmp"
     "image/gif"
     "image/jpeg"
     "image/jpg"
     "image/png"
     "image/svg+xml"
     "image/tiff"
     "image/vnd.microsoft.icon"
     "image/webp"
   ];
   # Audio Types
   audio = [
     "audio/aac"
     "audio/mpeg"
     "audio/ogg"
     "audio/opus"
     "audio/wav"
     "audio/webm"
     "audio/x-matroska"
   ];
   # Video Types
   video = [
     "video/mp2t"
     "video/mp4"
     "video/mpeg"
     "video/ogg"
     "video/webm"
     "video/x-flv"
     "video/x-matroska"
     "video/x-msvideo"
   ];
   # Special Types
   directory = [ "inode/directory" ];
   browser = [
     "text/html"
     "application/xhtml+xml"
     "x-scheme-handler/about"
     "x-scheme-handler/http"
     "x-scheme-handler/https"
     "x-scheme-handler/unknown"
   ];
   # Office Types
   office = [
     "application/vnd.oasis.opendocument.text"
     "application/vnd.oasis.opendocument.spreadsheet"
     "application/vnd.oasis.opendocument.presentation"
     "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
     "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
     "application/vnd.openxmlformats-officedocument.presentationml.presentation"
     "application/msword"
     "application/vnd.ms-excel"
     "application/vnd.ms-powerpoint"
     "application/rtf"
   ];
   # Other Types
   pdf = [ "application/pdf" ];
   terminal = [ "terminal" ];
   archive = [
     "application/zip"
     "application/rar"
     "application/7z"
     "application/*tar"
   ];
   discord = [ "x-scheme-handler/discord" ];
 };
 # =============================================================================
 # Association Generation
 # =============================================================================
 associations =
   with lists;
   listToAttrs (
     flatten (
       mapAttrsToList (
         key: map (type: attrsets.nameValuePair type defaultApps."${key}")
       ) mimeMap
     )
   );
in
{
 # =============================================================================
 # XDG Configuration
 # =============================================================================
 xdg.configFile."mimeapps.list".force = true;
 xdg.mimeApps.enable = true;
 xdg.mimeApps.associations.added = associations;
 xdg.mimeApps.defaultApplications = associations;

 # =============================================================================
 # Desktop Entry Configuration
 # =============================================================================
 xdg.desktopEntries.kitty-nvim = {
   name = "Kitty+Neovim";
   genericName = "Text Editor";
   exec = "kitty -e nvim %F";
   terminal = false;
   categories = [ "Utility" "TextEditor" ];
   mimeType = [ "text/plain" ];
 };

 # =============================================================================
 # Package Installation and Environment
 # =============================================================================
 home.packages = with pkgs; [ junction ];
 home.sessionVariables = {
   TERMINAL = "kitty";
   BROWSER = "brave";
   WINEDLLOVERRIDES = "winemenubuilder.exe=d"; # Prevent Wine file associations
 };
}

