# modules/home/nemo/default.nix
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
  # DConf Settings
  # =============================================================================
  dconf.settings = {
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
      show-open-in-terminal-toolbar = false;
      show-search-icon-toolbar = false;
      show-show-thumbnails-toolbar = false;
      thumbnail-limit = 10485760;
    };

    # ---------------------------------------------------------------------------
    # Menu Configuration
    # ---------------------------------------------------------------------------
    "org/nemo/preferences/menu-config" = {
      background-menu-open-as-root = false;
      selection-menu-open-as-root = false;
      selection-menu-open-in-terminal = false;
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

