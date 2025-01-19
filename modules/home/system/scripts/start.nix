{ pkgs, ... }:
let
  start-acta-always = pkgs.writeShellScriptBin "start-acta-always" (
    builtins.readFile ./start/start-acta-always.sh
  );
  start-acta-default = pkgs.writeShellScriptBin "start-acta-default" (
    builtins.readFile ./start/start-acta-default.sh
  );
  start-acta-never = pkgs.writeShellScriptBin "start-acta-never" (
    builtins.readFile ./start/start-acta-never.sh
  );
  start-akenp-always = pkgs.writeShellScriptBin "start-akenp-always" (
    builtins.readFile ./start/start-akenp-always.sh
  );
  start-akenp-default = pkgs.writeShellScriptBin "start-akenp-default" (
    builtins.readFile ./start/start-akenp-default.sh
  );
  start-akenp-never = pkgs.writeShellScriptBin "start-akenp-never" (
    builtins.readFile ./start/start-akenp-never.sh
  );
  start-alacritty-always = pkgs.writeShellScriptBin "start-alacritty-always" (
    builtins.readFile ./start/start-alacritty-always.sh
  );
  start-alacritty-default = pkgs.writeShellScriptBin "start-alacritty-default" (
    builtins.readFile ./start/start-alacritty-default.sh
  );
  start-alacritty-ncmpcpp-always = pkgs.writeShellScriptBin "start-alacritty-ncmpcpp-always" (
    builtins.readFile ./start/start-alacritty-ncmpcpp-always.sh
  );
  start-alacritty-ncmpcpp-default = pkgs.writeShellScriptBin "start-alacritty-ncmpcpp-default" (
    builtins.readFile ./start/start-alacritty-ncmpcpp-default.sh
  );
  start-alacritty-ncmpcpp-never = pkgs.writeShellScriptBin "start-alacritty-ncmpcpp-never" (
    builtins.readFile ./start/start-alacritty-ncmpcpp-never.sh
  );
  start-alacritty-never = pkgs.writeShellScriptBin "start-alacritty-never" (
    builtins.readFile ./start/start-alacritty-never.sh
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
  start-fcta-always = pkgs.writeShellScriptBin "start-fcta-always" (
    builtins.readFile ./start/start-fcta-always.sh
  );
  start-fcta-default = pkgs.writeShellScriptBin "start-fcta-default" (
    builtins.readFile ./start/start-fcta-default.sh
  );
  start-fcta-never = pkgs.writeShellScriptBin "start-fcta-never" (
    builtins.readFile ./start/start-fcta-never.sh
  );
  start-fkenp-always = pkgs.writeShellScriptBin "start-fkenp-always" (
    builtins.readFile ./start/start-fkenp-always.sh
  );
  start-fkenp-default = pkgs.writeShellScriptBin "start-fkenp-default" (
    builtins.readFile ./start/start-fkenp-default.sh
  );
  start-fkenp-never = pkgs.writeShellScriptBin "start-fkenp-never" (
    builtins.readFile ./start/start-fkenp-never.sh
  );
  start-foot-always = pkgs.writeShellScriptBin "start-foot-always" (
    builtins.readFile ./start/start-foot-always.sh
  );
  start-foot-default = pkgs.writeShellScriptBin "start-foot-default" (
    builtins.readFile ./start/start-foot-default.sh
  );
  start-foot-never = pkgs.writeShellScriptBin "start-foot-never" (
    builtins.readFile ./start/start-foot-never.sh
  );
  start-kcta-always = pkgs.writeShellScriptBin "start-kcta-always" (
    builtins.readFile ./start/start-kcta-always.sh
  );
  start-kcta-default = pkgs.writeShellScriptBin "start-kcta-default" (
    builtins.readFile ./start/start-kcta-default.sh
  );
  start-kcta-never = pkgs.writeShellScriptBin "start-kcta-never" (
    builtins.readFile ./start/start-kcta-never.sh
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
  start-wcta-always = pkgs.writeShellScriptBin "start-wcta-always" (
    builtins.readFile ./start/start-wcta-always.sh
  );
  start-wcta-default = pkgs.writeShellScriptBin "start-wcta-default" (
    builtins.readFile ./start/start-wcta-default.sh
  );
  start-wcta-never = pkgs.writeShellScriptBin "start-wcta-never" (
    builtins.readFile ./start/start-wcta-never.sh
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
    start-acta-always
    start-acta-default
    start-acta-never
    start-akenp-always
    start-akenp-default
    start-akenp-never
    start-alacritty-always
    start-alacritty-default
    start-alacritty-ncmpcpp-always
    start-alacritty-ncmpcpp-default
    start-alacritty-ncmpcpp-never
    start-alacritty-never
    start-discord-always
    start-discord-default
    start-discord-never
    start-fcta-always
    start-fcta-default
    start-fcta-never
    start-fkenp-always
    start-fkenp-default
    start-fkenp-never
    start-foot-always
    start-foot-default
    start-foot-never
    start-kcta-always
    start-kcta-default
    start-kcta-never
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
    start-wcta-always
    start-wcta-default
    start-wcta-never
    start-webcord-always
    start-webcord-default
    start-webcord-never
    start-wezterm-always
    start-wezterm-default
    start-wezterm-never
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
