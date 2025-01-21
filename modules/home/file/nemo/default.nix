# modules/home/file/nemo/default.nix
# ==============================================================================
# Nemo File Manager Configuration
# ==============================================================================
{ pkgs, ... }:
{
 # =============================================================================
 # Package Installation
 # =============================================================================
 home.packages = (with pkgs; [ nemo ]);

 # =============================================================================
 # Custom Actions
 # =============================================================================
 home.file.".local/share/nemo/actions/kitty.nemo_action".text = ''
   [Nemo Action]
   Active=true
   Name=Open in Kitty
   Comment=Open current directory in Kitty terminal
   Exec=kitty --working-directory %P
   Selection=none
   Extensions=any;
   Conditions=local;
   Icon-Name=utilities-terminal
 '';

 # =============================================================================
 # DConf Settings
 # =============================================================================
 dconf.settings = {
   # ---------------------------------------------------------------------------
   # Cinnamon Default Terminal
   # ---------------------------------------------------------------------------
   "org/cinnamon/desktop/default-applications/terminal" = {
     exec = "kitty";
   };
   
   # ---------------------------------------------------------------------------
   # General Preferences
   # ---------------------------------------------------------------------------
   "org/nemo/preferences" = {
     always-use-browser = true;
     close-device-view-on-device-eject = true;
     date-font-choice = "auto-mono";
     date-format = "iso";
     last-server-connect-method = 3;
     quick-renames-with-pause-in-between = true;
     show-edit-icon-toolbar = false;
     show-full-path-titles = false;
     show-hidden-files = true;
     show-home-icon-toolbar = true;
     show-new-folder-icon-toolbar = true;
     show-open-in-terminal-toolbar = true;
     show-search-icon-toolbar = false;
     show-show-thumbnails-toolbar = false;
     thumbnail-limit = 10485760;
     terminal = "kitty";
   };
   # ---------------------------------------------------------------------------
   # Menu Configuration
   # ---------------------------------------------------------------------------
   "org/nemo/preferences/menu-config" = {
     background-menu-open-as-root = false;
     selection-menu-open-as-root = false;
     selection-menu-open-in-terminal = true;
     selection-menu-scripts = false;
   };
   # ---------------------------------------------------------------------------
   # Search Settings
   # ---------------------------------------------------------------------------
   "org/nemo/search" = {
     search-reverse-sort = false;
     search-sort-column = "name";
   };
   # ---------------------------------------------------------------------------
   # Window State
   # ---------------------------------------------------------------------------
   "org/nemo/window-state" = {
     maximized = true;
     network-expanded = true;
     side-pane-view = "places";
     sidebar-bookmark-breakpoint = 2;
     sidebar-width = 220;
     start-with-sidebar = true;
   };
 };
}
