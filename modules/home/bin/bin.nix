# bin.nix
{ pkgs, ... }:
let
  # Hyprland Scripts
  hypr-airplane-mode = pkgs.writeShellScriptBin "hypr-airplane-mode" (
    builtins.readFile ./bin/hypr-airplane_mode.sh
  );
  hypr-audio-switcher = pkgs.writeShellScriptBin "hypr-audio-switcher" (
    builtins.readFile ./bin/hypr-audio_switcher.sh
  );
  hypr-blue-gammastep = pkgs.writeShellScriptBin "hypr-blue-gammastep" (
    builtins.readFile ./bin/hypr-blue-gammastep-manager.sh
  );
  hypr-bluetooth-toggle = pkgs.writeShellScriptBin "hypr-bluetooth-toggle" (
    builtins.readFile ./bin/hypr-bluetooth_toggle.sh
  );
  hypr-colorpicker = pkgs.writeShellScriptBin "hypr-colorpicker" (
    builtins.readFile ./bin/hypr-colorpicker.sh
  );
  hypr-monitor-toggle = pkgs.writeShellScriptBin "hypr-monitor-toggle" (
    builtins.readFile ./bin/hypr-monitor_toggle.sh
  );
  hypr-screenshot = pkgs.writeShellScriptBin "hypr-screenshot" (
    builtins.readFile ./bin/hypr-screenshot.sh
  );
  hypr-status-check = pkgs.writeShellScriptBin "hypr-status-check" (
    builtins.readFile ./bin/hypr-status-check.sh
  );

  # Theme Scripts
  theme-alacritty = pkgs.writeShellScriptBin "theme-alacritty" (
    builtins.readFile ./bin/theme-alacritty.sh
  );
  theme-kitty = pkgs.writeShellScriptBin "theme-kitty" (
    builtins.readFile ./bin/theme-kitty.sh
  );
  theme-gtk = pkgs.writeShellScriptBin "theme-gtk" (
    builtins.readFile ./bin/theme-gtk.sh
  );
  theme-manager = pkgs.writeShellScriptBin "theme-manager" (
    builtins.readFile ./bin/theme-manager.sh
  );

  # Waybar Scripts
  waybar-bluetooth = pkgs.writeShellScriptBin "waybar-bluetooth" (
    builtins.readFile ./bin/waybar-bluetooth-menu.sh
  );
  waybar-wifi = pkgs.writeShellScriptBin "waybar-wifi" (
    builtins.readFile ./bin/waybar-wofi-wifi.sh
  );
  waybar-weather = pkgs.writeShellScriptBin "waybar-weather" (
    builtins.readFile ./bin/waybar-weather-full.sh
  );

  # Wofi Scripts
  wofi-bluetooth = pkgs.writeShellScriptBin "wofi-bluetooth" (
    builtins.readFile ./bin/wofi-bluetooth.sh
  );
  wofi-power = pkgs.writeShellScriptBin "wofi-power" (
    builtins.readFile ./bin/wofi-power.sh
  );
  wofi-wifi = pkgs.writeShellScriptBin "wofi-wifi" (
    builtins.readFile ./bin/wofi-wifi.sh
  );
  wofi-search = pkgs.writeShellScriptBin "wofi-search" (
    builtins.readFile ./bin/wofi-search.sh
  );

  # TMux Scripts
  tmux-plugins = pkgs.writeShellScriptBin "tmux-plugins" (
    builtins.readFile ./bin/tmux-plugins.sh
  );
  tmux-startup = pkgs.writeShellScriptBin "tmux-startup" (
    builtins.readFile ./bin/tmux-startup.sh
  );
  t1 = pkgs.writeShellScriptBin "t1" (
    builtins.readFile ./bin/t1
  );
  t3 = pkgs.writeShellScriptBin "t3" (
    builtins.readFile ./bin/t3
  );
  t4 = pkgs.writeShellScriptBin "t4" (
    builtins.readFile ./bin/t4
  );
  tm = pkgs.writeShellScriptBin "tm" (
    builtins.readFile ./bin/tm
  );

  # Utility Scripts
  publicip = pkgs.writeShellScriptBin "publicip" (
    builtins.readFile ./bin/publicip.sh
  );
  turbo-boost = pkgs.writeShellScriptBin "turbo-boost" (
    builtins.readFile ./bin/turbo-boost-setup.sh
  );

in {
  home.packages = with pkgs; [
    # Hyprland Scripts
    hypr-airplane-mode
    hypr-audio-switcher
    hypr-blue-gammastep
    hypr-bluetooth-toggle
    hypr-colorpicker
    hypr-monitor-toggle
    hypr-screenshot
    hypr-status-check

    # Theme Scripts
    theme-alacritty
    theme-kitty
    theme-gtk
    theme-manager

    # Waybar Scripts
    waybar-bluetooth
    waybar-wifi
    waybar-weather

    # Wofi Scripts
    wofi-bluetooth
    wofi-power
    wofi-wifi
    wofi-search

    # TMux Scripts
    tmux-plugins
    tmux-startup

    # Utility Scripts
    publicip
    turbo-boost
  ];
}
