# modules/home/gnome/default.nix
# ==============================================================================
# GNOME Desktop Environment Configuration
# ==============================================================================
{ pkgs, ... }:
let
  colors = import ./../../themes/default.nix;
in
{
  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = (
    with pkgs;
    [
      evince # pdf
      file-roller # archive
      gnome-text-editor # gedit
    ]
  );
  # =============================================================================
  # DConf Settings
  # =============================================================================
  dconf.settings = {
    # ---------------------------------------------------------------------------
    # Text Editor Configuration
    # ---------------------------------------------------------------------------
    "org/gnome/TextEditor" = {
      custom-font = "${colors.fonts.editor.family} ${toString colors.fonts.sizes.xl}";
      highlight-current-line = true;
      indent-style = "space";
      restore-session = false;
      show-grid = false;
      show-line-numbers = true;
      show-right-margin = false;
      style-scheme = "builder-dark";
      style-variant = "dark";
      tab-width = "uint32 4";
      use-system-font = false;
      wrap-text = false;
    };
    
    # ---------------------------------------------------------------------------
    # Interface Configuration
    # ---------------------------------------------------------------------------
    "org/gnome/desktop/interface" = {
      font-name = "${colors.fonts.main.family} ${toString colors.fonts.sizes.sm}";
      document-font-name = "${colors.fonts.main.family} ${toString colors.fonts.sizes.sm}";
      monospace-font-name = "${colors.fonts.terminal.family} ${toString colors.fonts.sizes.sm}";
    };
  };
}
