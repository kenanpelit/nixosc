# modules/home/fastfetch/default.nix
# ==============================================================================
# Fastfetch System Information Tool Configuration
# ==============================================================================
# This configuration manages fastfetch settings including:
# - System information display layout
# - Logo and theming configuration
# - Custom module arrangements
# - Color scheme and formatting
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, username, ... }:
{
  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = [ pkgs.fastfetch ];

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
}

