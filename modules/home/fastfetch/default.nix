# modules/home/fastfetch/default.nix
# ==============================================================================
# Home module for Fastfetch system summary.
# Installs fastfetch and manages its user config via Home Manager.
# Tweak output/theme here instead of ad-hoc config files.
# ==============================================================================

{ pkgs, username, lib, config, ... }:
let
  cfg = config.my.user.fastfetch;
in
{
  options.my.user.fastfetch = {
    enable = lib.mkEnableOption "Fastfetch system info";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Configuration File
    # =============================================================================
    xdg.configFile."fastfetch/config.jsonc".text = ''
      {
        "logo": {
          "source": "/home/${username}/Pictures/wallpapers/nixos/nixoslogo.png",
          "type": "kitty-direct",
          "width": 33,
          "padding": {
            "top": 2
          }
        },
        "display": {
          "separator": "",
          "size": {
            "binaryPrefix": "si",
            "ndigits": 0
          },
          "percent": {
            "type": 1
          },
          "key": {
            "Width": 1
          }
        },
        "modules": [
          {
            "type": "title",
            "color": {
              "user": "35",
              "host": "36"
            }
          },
          {
            "type": "separator",
            "string": "▔"
          },
          {
            "type": "os",
            "key": "╭─ ",
            "format": "{3} ({12})",
            "keyColor": "32"
          },
          {
            "type": "host",
            "key": "├─󰟀 ",
            "keyColor": "32"
          },
          {
            "type": "kernel",
            "key": "├─󰒔 ",
            "format": "{1} {2}",
            "keyColor": "32"
          },
          {
            "type": "shell",
            "key": "├─$ ",
            "format": "{1} {4}",
            "keyColor": "32"
          },
          {
            "type": "packages",
            "key": "├─ ",
            "keyColor": "32"
          },
          {
            "type": "uptime",
            "key": "╰─󰔚 ",
            "keyColor": "32"
          },
          "break",
          {
            "type": "display",
            "key": "╭─󰹑 ",
            "keyColor": "33",
            "compactType": "original"
          },
          {
            "type": "de",
            "key": "├─󰧨 ",
            "keyColor": "33"
          },
          {
            "type": "wm",
            "key": "├─ ",
            "keyColor": "33"
          },
          {
            "type": "theme",
            "key": "├─󰉼 ",
            "keyColor": "33"
          },
          {
            "type": "icons",
            "key": "├─ ",
            "keyColor": "33"
          },
          {
            "type": "cursor",
            "key": "├─󰳽 ",
            "keyColor": "33"
          },
          {
            "type": "font",
            "key": "├─ ",
            "format": "{2}",
            "keyColor": "33"
          },
          {
            "type": "terminal",
            "key": "╰─ ",
            "format": "{3}",
            "keyColor": "33"
          },
          "break",
          {
            "type": "colors",
            "symbol": "block"
          }
        ]
      }
    '';
  };
}
