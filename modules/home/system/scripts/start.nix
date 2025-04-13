{ pkgs, ... }:
let
  start-brave-ai = pkgs.writeShellScriptBin "start-brave-ai" (
    builtins.readFile ./start/start-brave-ai.sh
  );
  start-brave-compecta = pkgs.writeShellScriptBin "start-brave-compecta" (
    builtins.readFile ./start/start-brave-compecta.sh
  );
  start-brave-discord = pkgs.writeShellScriptBin "start-brave-discord" (
    builtins.readFile ./start/start-brave-discord.sh
  );
  start-brave-exclude = pkgs.writeShellScriptBin "start-brave-exclude" (
    builtins.readFile ./start/start-brave-exclude.sh
  );
  start-brave-kenp = pkgs.writeShellScriptBin "start-brave-kenp" (
    builtins.readFile ./start/start-brave-kenp.sh
  );
  start-brave-spotify = pkgs.writeShellScriptBin "start-brave-spotify" (
    builtins.readFile ./start/start-brave-spotify.sh
  );
  start-brave-tiktok = pkgs.writeShellScriptBin "start-brave-tiktok" (
    builtins.readFile ./start/start-brave-tiktok.sh
  );
  start-brave-whatsapp = pkgs.writeShellScriptBin "start-brave-whatsapp" (
    builtins.readFile ./start/start-brave-whatsapp.sh
  );
  start-brave-whats = pkgs.writeShellScriptBin "start-brave-whats" (
    builtins.readFile ./start/start-brave-whats.sh
  );
  start-brave-yotube = pkgs.writeShellScriptBin "start-brave-yotube" (
    builtins.readFile ./start/start-brave-yotube.sh
  );
  start-chrome-ai = pkgs.writeShellScriptBin "start-chrome-ai" (
    builtins.readFile ./start/start-chrome-ai.sh
  );
  start-chrome-compecta = pkgs.writeShellScriptBin "start-chrome-compecta" (
    builtins.readFile ./start/start-chrome-compecta.sh
  );
  start-chrome-kenp = pkgs.writeShellScriptBin "start-chrome-kenp" (
    builtins.readFile ./start/start-chrome-kenp.sh
  );
  start-chrome-whats = pkgs.writeShellScriptBin "start-chrome-whats" (
    builtins.readFile ./start/start-chrome-whats.sh
  );
  start-discord = pkgs.writeShellScriptBin "start-discord" (
    builtins.readFile ./start/start-discord.sh
  );
  start-kitty-single = pkgs.writeShellScriptBin "start-kitty-single" (
    builtins.readFile ./start/start-kitty-single.sh
  );
  start-kkenp = pkgs.writeShellScriptBin "start-kkenp" (
    builtins.readFile ./start/start-kkenp.sh
  );
  start-mkenp = pkgs.writeShellScriptBin "start-mkenp" (
    builtins.readFile ./start/start-mkenp.sh
  );
  start-mpv = pkgs.writeShellScriptBin "start-mpv" (
    builtins.readFile ./start/start-mpv.sh
  );
  start-spotify = pkgs.writeShellScriptBin "start-spotify" (
    builtins.readFile ./start/start-spotify.sh
  );
  start-webcord = pkgs.writeShellScriptBin "start-webcord" (
    builtins.readFile ./start/start-webcord.sh
  );
  start-wezterm-rmpc = pkgs.writeShellScriptBin "start-wezterm-rmpc" (
    builtins.readFile ./start/start-wezterm-rmpc.sh
  );
  start-wezterm = pkgs.writeShellScriptBin "start-wezterm" (
    builtins.readFile ./start/start-wezterm.sh
  );
  start-wkenp = pkgs.writeShellScriptBin "start-wkenp" (
    builtins.readFile ./start/start-wkenp.sh
  );
  start-zen-compecta = pkgs.writeShellScriptBin "start-zen-compecta" (
    builtins.readFile ./start/start-zen-compecta.sh
  );
  start-zen-discord = pkgs.writeShellScriptBin "start-zen-discord" (
    builtins.readFile ./start/start-zen-discord.sh
  );
  start-zen-kenp = pkgs.writeShellScriptBin "start-zen-kenp" (
    builtins.readFile ./start/start-zen-kenp.sh
  );
  start-zen-novpn = pkgs.writeShellScriptBin "start-zen-novpn" (
    builtins.readFile ./start/start-zen-novpn.sh
  );
  start-zen-proxy = pkgs.writeShellScriptBin "start-zen-proxy" (
    builtins.readFile ./start/start-zen-proxy.sh
  );
  start-zen-spotify = pkgs.writeShellScriptBin "start-zen-spotify" (
    builtins.readFile ./start/start-zen-spotify.sh
  );
  start-zen-whats = pkgs.writeShellScriptBin "start-zen-whats" (
    builtins.readFile ./start/start-zen-whats.sh
  );
in {
  home.packages = with pkgs; [
    start-brave-ai
    start-brave-compecta
    start-brave-discord
    start-brave-exclude
    start-brave-kenp
    start-brave-spotify
    start-brave-tiktok
    start-brave-whatsapp
    start-brave-whats
    start-brave-yotube
    start-chrome-ai
    start-chrome-compecta
    start-chrome-kenp
    start-chrome-whats
    start-discord
    start-kitty-single
    start-kkenp
    start-mkenp
    start-mpv
    start-spotify
    start-webcord
    start-wezterm-rmpc
    start-wezterm
    start-wkenp
    start-zen-compecta
    start-zen-discord
    start-zen-kenp
    start-zen-novpn
    start-zen-proxy
    start-zen-spotify
    start-zen-whats
  ];
}
