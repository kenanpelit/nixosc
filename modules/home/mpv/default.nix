# modules/home/mpv/default.nix
# ==============================================================================
# Home module for MPV media player.
# Installs mpv and writes user config/keymaps via Home Manager.
# Adjust playback defaults here instead of manual config edits.
# ==============================================================================

{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.mpv;

  mpvConf = builtins.readFile ./config/mpv.conf;
  inputConf = builtins.readFile ./config/input.conf;

  # mpv'nin ytdl_hook scripti bazen `--no-config` ile çalıştırıldığı için,
  # YouTube erişimi için kritik ayarları (cookies + extractor args) mpv'ye özel
  # bir yt-dlp wrapper'ında topluyoruz.
  ytDlpMpv = pkgs.writeShellScriptBin "yt-dlp-mpv" ''
    set -euo pipefail

    cookie_file="''${XDG_CONFIG_HOME:-$HOME/.config}/yt-dlp/cookies-youtube.txt"
    # brave cookies: tarayıcı kök dizini (içinde "Local State" ve "Default/" olmalı)
    brave_dir="$HOME/.brave/isolated/Kenp"

    extra_args=(
      --extractor-args "youtube:player_client=android_sdkless,web_safari"
      --js-runtimes "deno"
    )

    if [[ -r "$cookie_file" ]]; then
      echo "[yt-dlp-mpv] using cookies file: $cookie_file" >&2
      exec ${pkgs.yt-dlp}/bin/yt-dlp "''${extra_args[@]}" --cookies "$cookie_file" "$@"
    fi

    if [[ -d "$brave_dir" ]]; then
      echo "[yt-dlp-mpv] cookies file missing; trying brave profile dir: $brave_dir" >&2

      mkdir -p "$(dirname "$cookie_file")"

      # cookies.txt yoksa otomatik üretmeyi dene (kullanıcı isterse incognito export ile bu dosyayı override edebilir).
      umask 077
      if ${pkgs.yt-dlp}/bin/yt-dlp "''${extra_args[@]}" --cookies-from-browser "brave+basictext:$brave_dir" --cookies "$cookie_file" "$@" >/dev/null 2>&1; then
        chmod 600 "$cookie_file" || true
        echo "[yt-dlp-mpv] exported cookies to: $cookie_file" >&2
        exec ${pkgs.yt-dlp}/bin/yt-dlp "''${extra_args[@]}" --cookies "$cookie_file" "$@"
      fi

      echo "[yt-dlp-mpv] cookie export failed; falling back to cookies-from-browser" >&2
      exec ${pkgs.yt-dlp}/bin/yt-dlp "''${extra_args[@]}" --cookies-from-browser "brave+basictext:$brave_dir" "$@"
    fi

    echo "[yt-dlp-mpv] no cookies available; proceeding without auth" >&2
    exec ${pkgs.yt-dlp}/bin/yt-dlp "''${extra_args[@]}" "$@"
  '';

  # Helper to copy whole script/script-opts folders
  mkConfigDir = path: {
    source = path;
    recursive = true;
  };
in
{
  options.my.user.mpv = {
    enable = lib.mkEnableOption "mpv configuration (no tar blobs; direct files)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.mpv
      pkgs.yt-dlp
      pkgs.deno
      ytDlpMpv
    ];

    xdg.configFile = {
      "mpv/mpv.conf".text = mpvConf;
      "mpv/input.conf".text = inputConf;
      "mpv/fonts" = mkConfigDir ./config/fonts;
      "mpv/scripts" = mkConfigDir ./config/scripts;
      "mpv/script-opts" = mkConfigDir ./config/script-opts;
      "mpv/script-modules" = mkConfigDir ./config/script-modules;
    };
  };
}
