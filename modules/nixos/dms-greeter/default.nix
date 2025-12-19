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

  # Upstream module options (we import `inputs.dankMaterialShell.nixosModules.greeter`).
  dmsGreeterCfg = config.programs."dank-material-shell".greeter;

  hyprPkg =
    if config.programs ? hyprland && config.programs.hyprland ? package
    then config.programs.hyprland.package
    else pkgs.hyprland;

  niriPkg =
    if config.programs ? niri && config.programs.niri ? package
    then config.programs.niri.package
    else pkgs.niri-unstable;

  swayPkg =
    if config.programs ? sway && config.programs.sway ? package
    then config.programs.sway.package
    else pkgs.sway;

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

    if [ -x "${hyprPkg}/bin/start-hyprland" ]; then
      exec "${hyprPkg}/bin/start-hyprland" "$@"
    fi

    if [ -x "${hyprPkg}/bin/Hyprland" ]; then
      exec "${hyprPkg}/bin/Hyprland" "$@"
    fi

    echo "dms-greeter: Hyprland executable not found in ${hyprPkg}/bin" >&2
    exit 127
  '';

  compositorPkg =
    if cfg.compositor == "hyprland" then hyprPkg else if cfg.compositor == "niri" then niriPkg else swayPkg;

  greeterPath = lib.makeBinPath (
    (lib.optionals (cfg.compositor == "hyprland") [ hyprlandGreeterHyprlandWrapper ])
    ++ [
      dmsGreeterCfg.quickshell.package
      compositorPkg
      # Greeter scans sessions via `find | sort` and parses via `bash + grep`.
      # Don't rely on host PATH contents; make it explicit.
      pkgs.bash
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
    ]
  );

  dmsShellPkg = inputs.dankMaterialShell.packages.${pkgs.stdenv.hostPlatform.system}.dms-shell;
  dmsGreeterAsset = "${inputs.dankMaterialShell}/quickshell/Modules/Greetd/assets/dms-greeter";

  greeterCompositorCustomConfig =
    if cfg.compositor == "hyprland" then
      ''
        env = DMS_RUN_GREETER,1

        misc {
          disable_hyprland_logo = true
        }

        input {
          kb_layout = ${cfg.layout}
          ${lib.optionalString (cfg.variant != "") "kb_variant = ${cfg.variant}"}
        }
      ''
    else if cfg.compositor == "niri" then
      ''
        hotkey-overlay {
          skip-at-startup
        }

        environment {
          DMS_RUN_GREETER "1"
        }

        input {
          keyboard {
            xkb {
              layout "${cfg.layout}"
              ${lib.optionalString (cfg.variant != "") "variant \"${cfg.variant}\""}
            }
          }
        }

        debug {
          keep-max-bpc-unchanged
        }

        gestures {
          hot-corners {
            off
          }
        }

        layout {
          background-color "#000000"
        }
      ''
    else
      ''
        input * {
          xkb_layout "${cfg.layout}"
          ${lib.optionalString (cfg.variant != "") "xkb_variant \"${cfg.variant}\""}
        }
      '';

  # NOTE: greetd 0.10.3 crashes on multiline TOML arrays (like `environment = [ ... ]`).
  # NixOS generates multiline arrays for `services.greetd.settings.*.environment`, so we must
  # avoid it and set env vars inside the command wrapper instead.
  greeterCommand = pkgs.writeShellScriptBin "dms-greeter" ''
    set -euo pipefail

    export XKB_DEFAULT_LAYOUT=${lib.escapeShellArg cfg.layout}
    ${lib.optionalString (cfg.variant != "") ''
      export XKB_DEFAULT_VARIANT=${lib.escapeShellArg cfg.variant}
    ''}

    export HOME=${lib.escapeShellArg greeterHome}
    export XDG_CACHE_HOME=${lib.escapeShellArg "${greeterHome}/.cache"}
    export XDG_STATE_HOME=${lib.escapeShellArg "${greeterHome}/.local/state"}
    export PATH=${lib.escapeShellArg "${greeterPath}:/run/current-system/sw/bin"}:''${PATH:+":$PATH"}
    # DMS greeter discovers sessions from:
    # - /usr/share/{wayland-sessions,xsessions}
    # - $HOME/.local/share/{wayland-sessions,xsessions}
    # - $XDG_DATA_DIRS/{wayland-sessions,xsessions}
    #
    # On NixOS, system session .desktop files live under:
    #   /run/current-system/sw/share/{wayland-sessions,xsessions}
    # but greetd does not source /etc/profile so XDG_DATA_DIRS is usually empty.
    # Without this, the session list in the greeter becomes empty.
    export XDG_DATA_DIRS=/run/current-system/sw/share:/usr/local/share:/usr/share

    exec ${
      lib.escapeShellArgs (
        [
          "sh"
          dmsGreeterAsset
          "--cache-dir"
          greeterHome
          "--command"
          cfg.compositor
          "-p"
          "${dmsShellPkg}/share/quickshell/dms"
        ]
        ++ lib.optionals (dmsGreeterCfg.compositor.customConfig != "") [
          "-C"
          "${pkgs.writeText "dmsgreeter-compositor-config" dmsGreeterCfg.compositor.customConfig}"
        ]
      )
    } ${lib.optionalString dmsGreeterCfg.logs.save "> ${lib.escapeShellArg dmsGreeterCfg.logs.path} 2>&1"}
  '';
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

    programs."dank-material-shell".greeter = {
      enable = true;
      compositor.name = cfg.compositor;
      compositor.customConfig = lib.mkDefault greeterCompositorCustomConfig;
      configHome = "/home/${user}";
      logs = {
        save = true;
        path = "/var/log/dms-greeter/dms-greeter.log";
      };
    };

    # Greeter kullanıcısının HOME'u genelde /var/empty oluyor; Hyprland/Qt cache gibi
    # şeyler buraya yazmaya çalışınca hata basıyor. HOME + cache'i writable yapalım.
    services.greetd.settings.default_session.user = lib.mkDefault "greeter";
    services.greetd.settings.default_session.command = lib.mkForce (lib.getExe greeterCommand);

    # Ensure log directory exists and is writable by greeter user
    systemd.tmpfiles.rules = [
      "d /var/log/dms-greeter 0755 greeter greeter -"
      "f /var/log/dms-greeter/dms-greeter.log 0664 greeter greeter -"
    ];
  };
}
