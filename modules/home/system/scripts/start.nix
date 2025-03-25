{ pkgs, ... }:
let
  start-chrome-ai-always = pkgs.writeShellScriptBin "start-chrome-ai-always" (
    builtins.readFile ./start/start-chrome-ai-always.sh
  );
  start-chrome-ai-default = pkgs.writeShellScriptBin "start-chrome-ai-default" (
    builtins.readFile ./start/start-chrome-ai-default.sh
  );
  start-chrome-ai-never = pkgs.writeShellScriptBin "start-chrome-ai-never" (
    builtins.readFile ./start/start-chrome-ai-never.sh
  );
  start-chrome-compectta-always = pkgs.writeShellScriptBin "start-chrome-compectta-always" (
    builtins.readFile ./start/start-chrome-compectta-always.sh
  );
  start-chrome-compectta-default = pkgs.writeShellScriptBin "start-chrome-compectta-default" (
    builtins.readFile ./start/start-chrome-compectta-default.sh
  );
  start-chrome-compectta-never = pkgs.writeShellScriptBin "start-chrome-compectta-never" (
    builtins.readFile ./start/start-chrome-compectta-never.sh
  );
  start-chrome-kenp-always = pkgs.writeShellScriptBin "start-chrome-kenp-always" (
    builtins.readFile ./start/start-chrome-kenp-always.sh
  );
  start-chrome-kenp-default = pkgs.writeShellScriptBin "start-chrome-kenp-default" (
    builtins.readFile ./start/start-chrome-kenp-default.sh
  );
  start-chrome-kenp-never = pkgs.writeShellScriptBin "start-chrome-kenp-never" (
    builtins.readFile ./start/start-chrome-kenp-never.sh
  );
  start-chrome-whats-always = pkgs.writeShellScriptBin "start-chrome-whats-always" (
    builtins.readFile ./start/start-chrome-whats-always.sh
  );
  start-chrome-whats-default = pkgs.writeShellScriptBin "start-chrome-whats-default" (
    builtins.readFile ./start/start-chrome-whats-default.sh
  );
  start-chrome-whats-never = pkgs.writeShellScriptBin "start-chrome-whats-never" (
    builtins.readFile ./start/start-chrome-whats-never.sh
  );
  start-discord-always = pkgs.writeShellScriptBin "start-discord-always" (
    builtins.readFile ./start/start-discord-always.sh
  );
  start-discord-default = pkgs.writeShellScriptBin "start-discord-default" (
    builtins.readFile ./start/start-discord-default.sh
  );
  start-discord-never = pkgs.writeShellScriptBin "start-discord-never" (
    builtins.readFile ./start/start-discord-never.sh
  );
  start-kitty-single-always = pkgs.writeShellScriptBin "start-kitty-single-always" (
    builtins.readFile ./start/start-kitty-single-always.sh
  );
  start-kitty-single-default = pkgs.writeShellScriptBin "start-kitty-single-default" (
    builtins.readFile ./start/start-kitty-single-default.sh
  );
  start-kitty-single-never = pkgs.writeShellScriptBin "start-kitty-single-never" (
    builtins.readFile ./start/start-kitty-single-never.sh
  );
  start-kkenp-always = pkgs.writeShellScriptBin "start-kkenp-always" (
    builtins.readFile ./start/start-kkenp-always.sh
  );
  start-kkenp-default = pkgs.writeShellScriptBin "start-kkenp-default" (
    builtins.readFile ./start/start-kkenp-default.sh
  );
  start-kkenp-never = pkgs.writeShellScriptBin "start-kkenp-never" (
    builtins.readFile ./start/start-kkenp-never.sh
  );
  start-mpv-always = pkgs.writeShellScriptBin "start-mpv-always" (
    builtins.readFile ./start/start-mpv-always.sh
  );
  start-mpv-default = pkgs.writeShellScriptBin "start-mpv-default" (
    builtins.readFile ./start/start-mpv-default.sh
  );
  start-mpv-never = pkgs.writeShellScriptBin "start-mpv-never" (
    builtins.readFile ./start/start-mpv-never.sh
  );
  start-spotify-always = pkgs.writeShellScriptBin "start-spotify-always" (
    builtins.readFile ./start/start-spotify-always.sh
  );
  start-spotify-default = pkgs.writeShellScriptBin "start-spotify-default" (
    builtins.readFile ./start/start-spotify-default.sh
  );
  start-spotify-never = pkgs.writeShellScriptBin "start-spotify-never" (
    builtins.readFile ./start/start-spotify-never.sh
  );
  start-transmission-gtk-always = pkgs.writeShellScriptBin "start-transmission-gtk-always" (
    builtins.readFile ./start/start-transmission-gtk-always.sh
  );
  start-transmission-gtk-default = pkgs.writeShellScriptBin "start-transmission-gtk-default" (
    builtins.readFile ./start/start-transmission-gtk-default.sh
  );
  start-transmission-gtk-never = pkgs.writeShellScriptBin "start-transmission-gtk-never" (
    builtins.readFile ./start/start-transmission-gtk-never.sh
  );
  start-webcord-always = pkgs.writeShellScriptBin "start-webcord-always" (
    builtins.readFile ./start/start-webcord-always.sh
  );
  start-webcord-default = pkgs.writeShellScriptBin "start-webcord-default" (
    builtins.readFile ./start/start-webcord-default.sh
  );
  start-webcord-never = pkgs.writeShellScriptBin "start-webcord-never" (
    builtins.readFile ./start/start-webcord-never.sh
  );
  start-wezterm-always = pkgs.writeShellScriptBin "start-wezterm-always" (
    builtins.readFile ./start/start-wezterm-always.sh
  );
  start-wezterm-default = pkgs.writeShellScriptBin "start-wezterm-default" (
    builtins.readFile ./start/start-wezterm-default.sh
  );
  start-wezterm-never = pkgs.writeShellScriptBin "start-wezterm-never" (
    builtins.readFile ./start/start-wezterm-never.sh
  );
  start-wezterm-rmpc-always = pkgs.writeShellScriptBin "start-wezterm-rmpc-always" (
    builtins.readFile ./start/start-wezterm-rmpc-always.sh
  );
  start-wezterm-rmpc-default = pkgs.writeShellScriptBin "start-wezterm-rmpc-default" (
    builtins.readFile ./start/start-wezterm-rmpc-default.sh
  );
  start-wezterm-rmpc-never = pkgs.writeShellScriptBin "start-wezterm-rmpc-never" (
    builtins.readFile ./start/start-wezterm-rmpc-never.sh
  );
  start-wkenp-always = pkgs.writeShellScriptBin "start-wkenp-always" (
    builtins.readFile ./start/start-wkenp-always.sh
  );
  start-wkenp-default = pkgs.writeShellScriptBin "start-wkenp-default" (
    builtins.readFile ./start/start-wkenp-default.sh
  );
  start-wkenp-never = pkgs.writeShellScriptBin "start-wkenp-never" (
    builtins.readFile ./start/start-wkenp-never.sh
  );
  start-zen-compecta-always = pkgs.writeShellScriptBin "start-zen-compecta-always" (
    builtins.readFile ./start/start-zen-compecta-always.sh
  );
  start-zen-compecta-default = pkgs.writeShellScriptBin "start-zen-compecta-default" (
    builtins.readFile ./start/start-zen-compecta-default.sh
  );
  start-zen-compecta-never = pkgs.writeShellScriptBin "start-zen-compecta-never" (
    builtins.readFile ./start/start-zen-compecta-never.sh
  );
  start-zen-discord-always = pkgs.writeShellScriptBin "start-zen-discord-always" (
    builtins.readFile ./start/start-zen-discord-always.sh
  );
  start-zen-discord-default = pkgs.writeShellScriptBin "start-zen-discord-default" (
    builtins.readFile ./start/start-zen-discord-default.sh
  );
  start-zen-discord-never = pkgs.writeShellScriptBin "start-zen-discord-never" (
    builtins.readFile ./start/start-zen-discord-never.sh
  );
  start-zen-kenp-always = pkgs.writeShellScriptBin "start-zen-kenp-always" (
    builtins.readFile ./start/start-zen-kenp-always.sh
  );
  start-zen-kenp-default = pkgs.writeShellScriptBin "start-zen-kenp-default" (
    builtins.readFile ./start/start-zen-kenp-default.sh
  );
  start-zen-kenp-never = pkgs.writeShellScriptBin "start-zen-kenp-never" (
    builtins.readFile ./start/start-zen-kenp-never.sh
  );
  start-zen-novpn-always = pkgs.writeShellScriptBin "start-zen-novpn-always" (
    builtins.readFile ./start/start-zen-novpn-always.sh
  );
  start-zen-novpn-default = pkgs.writeShellScriptBin "start-zen-novpn-default" (
    builtins.readFile ./start/start-zen-novpn-default.sh
  );
  start-zen-novpn-never = pkgs.writeShellScriptBin "start-zen-novpn-never" (
    builtins.readFile ./start/start-zen-novpn-never.sh
  );
  start-zen-proxy-always = pkgs.writeShellScriptBin "start-zen-proxy-always" (
    builtins.readFile ./start/start-zen-proxy-always.sh
  );
  start-zen-proxy-default = pkgs.writeShellScriptBin "start-zen-proxy-default" (
    builtins.readFile ./start/start-zen-proxy-default.sh
  );
  start-zen-proxy-never = pkgs.writeShellScriptBin "start-zen-proxy-never" (
    builtins.readFile ./start/start-zen-proxy-never.sh
  );
  start-zen-spotify-always = pkgs.writeShellScriptBin "start-zen-spotify-always" (
    builtins.readFile ./start/start-zen-spotify-always.sh
  );
  start-zen-spotify-default = pkgs.writeShellScriptBin "start-zen-spotify-default" (
    builtins.readFile ./start/start-zen-spotify-default.sh
  );
  start-zen-spotify-never = pkgs.writeShellScriptBin "start-zen-spotify-never" (
    builtins.readFile ./start/start-zen-spotify-never.sh
  );
  start-zen-whats-always = pkgs.writeShellScriptBin "start-zen-whats-always" (
    builtins.readFile ./start/start-zen-whats-always.sh
  );
  start-zen-whats-default = pkgs.writeShellScriptBin "start-zen-whats-default" (
    builtins.readFile ./start/start-zen-whats-default.sh
  );
  start-zen-whats-never = pkgs.writeShellScriptBin "start-zen-whats-never" (
    builtins.readFile ./start/start-zen-whats-never.sh
  );

in {
  home.packages = with pkgs; [
    start-chrome-ai-always
    start-chrome-ai-default
    start-chrome-ai-never
    start-chrome-compectta-always
    start-chrome-compectta-default
    start-chrome-compectta-never
    start-chrome-kenp-always
    start-chrome-kenp-default
    start-chrome-kenp-never
    start-chrome-whats-always
    start-chrome-whats-default
    start-chrome-whats-never
    start-discord-always
    start-discord-default
    start-discord-never
    start-kitty-single-always
    start-kitty-single-default
    start-kitty-single-never
    start-kkenp-always
    start-kkenp-default
    start-kkenp-never
    start-mpv-always
    start-mpv-default
    start-mpv-never
    start-spotify-always
    start-spotify-default
    start-spotify-never
    start-transmission-gtk-always
    start-transmission-gtk-default
    start-transmission-gtk-never
    start-webcord-always
    start-webcord-default
    start-webcord-never
    start-wezterm-always
    start-wezterm-default
    start-wezterm-never
    start-wezterm-rmpc-always
    start-wezterm-rmpc-default
    start-wezterm-rmpc-never
    start-wkenp-always
    start-wkenp-default
    start-wkenp-never
    start-zen-compecta-always
    start-zen-compecta-default
    start-zen-compecta-never
    start-zen-discord-always
    start-zen-discord-default
    start-zen-discord-never
    start-zen-kenp-always
    start-zen-kenp-default
    start-zen-kenp-never
    start-zen-novpn-always
    start-zen-novpn-default
    start-zen-novpn-never
    start-zen-proxy-always
    start-zen-proxy-default
    start-zen-proxy-never
    start-zen-spotify-always
    start-zen-spotify-default
    start-zen-spotify-never
    start-zen-whats-always
    start-zen-whats-default
    start-zen-whats-never
  ];
}
