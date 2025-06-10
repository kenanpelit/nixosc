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
  start-brave-kenp = pkgs.writeShellScriptBin "start-brave-kenp" (
    builtins.readFile ./start/start-brave-kenp.sh
  );
  start-brave-spotify = pkgs.writeShellScriptBin "start-brave-spotify" (
    builtins.readFile ./start/start-brave-spotify.sh
  );
  start-brave-whatsapp = pkgs.writeShellScriptBin "start-brave-whatsapp" (
    builtins.readFile ./start/start-brave-whatsapp.sh
  );
  start-brave-whats = pkgs.writeShellScriptBin "start-brave-whats" (
    builtins.readFile ./start/start-brave-whats.sh
  );
  start-brave-youtube = pkgs.writeShellScriptBin "start-brave-youtube" (
    builtins.readFile ./start/start-brave-youtube.sh
  );
  start-discord = pkgs.writeShellScriptBin "start-discord" (
    builtins.readFile ./start/start-discord.sh
  );
  start-ferdium = pkgs.writeShellScriptBin "start-ferdium" (
    builtins.readFile ./start/start-ferdium.sh
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
  start-zen-whats = pkgs.writeShellScriptBin "start-zen-whats" (
    builtins.readFile ./start/start-zen-whats.sh
  );
in {
  home.packages = with pkgs; [
    start-brave-ai
    start-brave-compecta
    start-brave-discord
    start-brave-kenp
    start-brave-spotify
    start-brave-whatsapp
    start-brave-whats
    start-brave-youtube
    start-discord
    start-ferdium
    start-kitty-single
    start-kkenp
    start-mkenp
    start-spotify
    start-webcord
    start-wezterm-rmpc
    start-wezterm
    start-wkenp
    start-zen-compecta
    start-zen-discord
    start-zen-kenp
    start-zen-novpn
    start-zen-whats
  ];
}
