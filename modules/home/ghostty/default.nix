# modules/home/ghostty/default.nix
# ==============================================================================
# Ghostty terminal setup (Catppuccin Mocha themed) with sensible defaults
# ==============================================================================
{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.ghostty;

  # Catppuccin Mocha 16-color palette
  palette = {
    black = "#45475a";
    red = "#f38ba8";
    green = "#a6e3a1";
    yellow = "#f9e2af";
    blue = "#89b4fa";
    magenta = "#cba6f7";
    cyan = "#89dceb";
    white = "#cdd6f4";
    brightBlack = "#585b70";
    brightRed = "#f38ba8";
    brightGreen = "#a6e3a1";
    brightYellow = "#f9e2af";
    brightBlue = "#89b4fa";
    brightMagenta = "#cba6f7";
    brightCyan = "#89dceb";
    brightWhite = "#f5e0dc";
  };

  shellCmd = config.home.sessionVariables.SHELL or "zsh";

  ghosttyConfig = ''
    # Appearance
    font-family = "Maple Mono NF"
    font-size = 12
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    cursor-color = "#cba6f7"
    selection-background = "#313244"
    window-decoration = false
    window-padding-x = 10
    window-padding-y = 10
    background-opacity = 1.0
    window-show-tab-bar = auto

    # Palette (Catppuccin Mocha)
    palette = 0=${palette.black}
    palette = 1=${palette.red}
    palette = 2=${palette.green}
    palette = 3=${palette.yellow}
    palette = 4=${palette.blue}
    palette = 5=${palette.magenta}
    palette = 6=${palette.cyan}
    palette = 7=${palette.white}
    palette = 8=${palette.brightBlack}
    palette = 9=${palette.brightRed}
    palette = 10=${palette.brightGreen}
    palette = 11=${palette.brightYellow}
    palette = 12=${palette.brightBlue}
    palette = 13=${palette.brightMagenta}
    palette = 14=${palette.brightCyan}
    palette = 15=${palette.brightWhite}

    # Behaviour
    scrollback = 10000
    copy-on-select = true
    confirm-close-surface = false
    command = "${shellCmd}"

    # Keybindings (familiar to kitty/alacritty users)
    keybind = ctrl+shift+t=new_tab
    keybind = ctrl+shift+w=close_surface
    keybind = ctrl+shift+enter=new_window
    keybind = ctrl+shift+tab=previous_tab
    keybind = ctrl+tab=next_tab
    keybind = ctrl+shift+c=copy_to_clipboard
    keybind = ctrl+shift+v=paste_from_clipboard
  '';
in
{
  options.my.user.ghostty = {
    enable = lib.mkEnableOption "Ghostty terminal";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.ghostty;
      description = "Ghostty package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."ghostty/config".text = ghosttyConfig;
  };
}
