# modules/nixos/dms-greeter/default.nix
# ==============================================================================
# NixOS integration for DankMaterialShell greeter service.
# Handles system service enablement and greeter assets in one place.
# Adjust greeter behaviour here instead of host-specific tweaks.
# ==============================================================================

{ lib, config, inputs, pkgs, ... }:
let
  cfg = config.my.greeter.dms or { enable = false; };
  user = config.my.user.name or "kenan";
  greeterHome = "/var/lib/dms-greeter";

  hyprPkg =
    if config.programs ? hyprland && config.programs.hyprland ? package
    then config.programs.hyprland.package
    else pkgs.hyprland;

  # DMS greeter, Hyprland'ı `Hyprland` binary adıyla çalıştırıyor.
  # Hyprland ise start-hyprland wrapper'ı olmadan başlatılınca uyarı basıyor.
  # Greeter oturumunda PATH'in başına bu wrapper'ı koyarak uyarıyı bitiriyoruz.
  hyprlandGreeterHyprlandWrapper = pkgs.writeShellScriptBin "Hyprland" ''
    set -euo pipefail
    wrapper_dir="$(cd "$(dirname "$0")" && pwd -P)"
    path=":''${PATH:-}:"
    path="''${path//:''${wrapper_dir}:/:}"
    path="''${path%:}"
    export PATH="${hyprPkg}/bin''${path}"
    exec "${hyprPkg}/bin/start-hyprland" "$@"
  '';

  greeterPath =
    if cfg.compositor == "hyprland"
    then "${lib.makeBinPath [ hyprlandGreeterHyprlandWrapper ]}:/run/current-system/sw/bin"
    else "/run/current-system/sw/bin";
in {
  imports = [ inputs.dankMaterialShell.nixosModules.greeter ];

  options.my.greeter.dms = {
    enable = lib.mkEnableOption "DMS Greeter via greetd";

    compositor = lib.mkOption {
      type = lib.types.enum [ "hyprland" "niri" "sway" ];
      default = "hyprland"; # valid names: hyprland, niri, sway
      description = "Compositor name passed to dms-greeter (hyprland, niri, or sway).";
    };

    layout = lib.mkOption {
      type = lib.types.str;
      default = "tr";
      description = "Keyboard layout passed to greetd (XKB_DEFAULT_LAYOUT).";
    };

    variant = lib.mkOption {
      type = lib.types.str;
      default = "f";
      description = "Keyboard layout variant passed to greetd (XKB_DEFAULT_VARIANT). Leave empty to skip.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.greetd.enable = true;

    programs.dankMaterialShell.greeter = {
      enable = true;
      compositor.name = cfg.compositor;
      configHome = "/home/${user}";
      logs = {
        save = true;
        path = "/var/log/dms-greeter/dms-greeter.log";
      };
    };

    # Greeter kullanıcısının HOME'u genelde /var/empty oluyor; Hyprland/Qt cache gibi
    # şeyler buraya yazmaya çalışınca hata basıyor. HOME + cache'i writable yapalım.
    services.greetd.settings.default_session.user = lib.mkDefault "greeter";
    services.greetd.settings.default_session.environment =
      [
        "XKB_DEFAULT_LAYOUT=${cfg.layout}"
        "HOME=${greeterHome}"
        "XDG_CACHE_HOME=${greeterHome}/.cache"
        "XDG_STATE_HOME=${greeterHome}/.local/state"
        "PATH=${greeterPath}"
      ]
      ++ lib.optional (cfg.variant != "") "XKB_DEFAULT_VARIANT=${cfg.variant}";

    # Ensure log directory exists and is writable by greeter user
    systemd.tmpfiles.rules = [
      "d /var/log/dms-greeter 0755 greeter greeter -"
      "f /var/log/dms-greeter/dms-greeter.log 0664 greeter greeter -"
    ];
  };
}
