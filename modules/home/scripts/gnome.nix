{ pkgs, ... }:
let
  gnome-brave-ai = pkgs.writeShellScriptBin "gnome-brave-ai" (
    builtins.readFile ./gnome/gnome-brave-ai.sh
  );
  gnome-brave-compecta = pkgs.writeShellScriptBin "gnome-brave-compecta" (
    builtins.readFile ./gnome/gnome-brave-compecta.sh
  );
  gnome-brave-discord = pkgs.writeShellScriptBin "gnome-brave-discord" (
    builtins.readFile ./gnome/gnome-brave-discord.sh
  );
  gnome-brave-exclude = pkgs.writeShellScriptBin "gnome-brave-exclude" (
    builtins.readFile ./gnome/gnome-brave-exclude.sh
  );
  gnome-brave-kenp = pkgs.writeShellScriptBin "gnome-brave-kenp" (
    builtins.readFile ./gnome/gnome-brave-kenp.sh
  );
  gnome-brave-spotify = pkgs.writeShellScriptBin "gnome-brave-spotify" (
    builtins.readFile ./gnome/gnome-brave-spotify.sh
  );
  gnome-brave-tiktok = pkgs.writeShellScriptBin "gnome-brave-tiktok" (
    builtins.readFile ./gnome/gnome-brave-tiktok.sh
  );
  gnome-brave-whatsapp = pkgs.writeShellScriptBin "gnome-brave-whatsapp" (
    builtins.readFile ./gnome/gnome-brave-whatsapp.sh
  );
  gnome-brave-whats = pkgs.writeShellScriptBin "gnome-brave-whats" (
    builtins.readFile ./gnome/gnome-brave-whats.sh
  );
  gnome-brave-youtube = pkgs.writeShellScriptBin "gnome-brave-youtube" (
    builtins.readFile ./gnome/gnome-brave-youtube.sh
  );
  gnome-chrome-ai = pkgs.writeShellScriptBin "gnome-chrome-ai" (
    builtins.readFile ./gnome/gnome-chrome-ai.sh
  );
  gnome-chrome-compecta = pkgs.writeShellScriptBin "gnome-chrome-compecta" (
    builtins.readFile ./gnome/gnome-chrome-compecta.sh
  );
  gnome-chrome-kenp = pkgs.writeShellScriptBin "gnome-chrome-kenp" (
    builtins.readFile ./gnome/gnome-chrome-kenp.sh
  );
  gnome-chrome-whats = pkgs.writeShellScriptBin "gnome-chrome-whats" (
    builtins.readFile ./gnome/gnome-chrome-whats.sh
  );
  gnome-discord = pkgs.writeShellScriptBin "gnome-discord" (
    builtins.readFile ./gnome/gnome-discord.sh
  );
  gnome-ferdium = pkgs.writeShellScriptBin "gnome-ferdium" (
    builtins.readFile ./gnome/gnome-ferdium.sh
  );
  gnome-kitty-single = pkgs.writeShellScriptBin "gnome-kitty-single" (
    builtins.readFile ./gnome/gnome-kitty-single.sh
  );
  gnome-kkenp = pkgs.writeShellScriptBin "gnome-kkenp" (
    builtins.readFile ./gnome/gnome-kkenp.sh
  );
  gnome-mkenp = pkgs.writeShellScriptBin "gnome-mkenp" (
    builtins.readFile ./gnome/gnome-mkenp.sh
  );
  gnome-mpv = pkgs.writeShellScriptBin "gnome-mpv" (
    builtins.readFile ./gnome/gnome-mpv.sh
  );
  gnome-spotify = pkgs.writeShellScriptBin "gnome-spotify" (
    builtins.readFile ./gnome/gnome-spotify.sh
  );
  gnome-webcord = pkgs.writeShellScriptBin "gnome-webcord" (
    builtins.readFile ./gnome/gnome-webcord.sh
  );
  gnome-wezterm-rmpc = pkgs.writeShellScriptBin "gnome-wezterm-rmpc" (
    builtins.readFile ./gnome/gnome-wezterm-rmpc.sh
  );
  gnome-wezterm = pkgs.writeShellScriptBin "gnome-wezterm" (
    builtins.readFile ./gnome/gnome-wezterm.sh
  );
  gnome-wkenp = pkgs.writeShellScriptBin "gnome-wkenp" (
    builtins.readFile ./gnome/gnome-wkenp.sh
  );
  gnome-zen-compecta = pkgs.writeShellScriptBin "gnome-zen-compecta" (
    builtins.readFile ./gnome/gnome-zen-compecta.sh
  );
  gnome-zen-discord = pkgs.writeShellScriptBin "gnome-zen-discord" (
    builtins.readFile ./gnome/gnome-zen-discord.sh
  );
  gnome-zen-kenp = pkgs.writeShellScriptBin "gnome-zen-kenp" (
    builtins.readFile ./gnome/gnome-zen-kenp.sh
  );
  gnome-zen-novpn = pkgs.writeShellScriptBin "gnome-zen-novpn" (
    builtins.readFile ./gnome/gnome-zen-novpn.sh
  );
  gnome-zen-proxy = pkgs.writeShellScriptBin "gnome-zen-proxy" (
    builtins.readFile ./gnome/gnome-zen-proxy.sh
  );
  gnome-zen-spotify = pkgs.writeShellScriptBin "gnome-zen-spotify" (
    builtins.readFile ./gnome/gnome-zen-spotify.sh
  );
  gnome-zen-whats = pkgs.writeShellScriptBin "gnome-zen-whats" (
    builtins.readFile ./gnome/gnome-zen-whats.sh
  );
in {
  home.packages = with pkgs; [
    gnome-brave-ai
    gnome-brave-compecta
    gnome-brave-discord
    gnome-brave-exclude
    gnome-brave-kenp
    gnome-brave-spotify
    gnome-brave-tiktok
    gnome-brave-whatsapp
    gnome-brave-whats
    gnome-brave-youtube
    gnome-chrome-ai
    gnome-chrome-compecta
    gnome-chrome-kenp
    gnome-chrome-whats
    gnome-discord
    gnome-ferdium
    gnome-kitty-single
    gnome-kkenp
    gnome-mkenp
    gnome-mpv
    gnome-spotify
    gnome-webcord
    gnome-wezterm-rmpc
    gnome-wezterm
    gnome-wkenp
    gnome-zen-compecta
    gnome-zen-discord
    gnome-zen-kenp
    gnome-zen-novpn
    gnome-zen-proxy
    gnome-zen-spotify
    gnome-zen-whats
  ];
}
