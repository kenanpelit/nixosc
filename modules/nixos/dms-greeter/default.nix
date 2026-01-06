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

  # Greeter must use the same Hyprland build as `start-hyprland`, otherwise
  # Hyprland may exit immediately on unknown internal args like `--watchdog-fd`.
  hyprPkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.default;

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

    # If start-hyprland calls `Hyprland` with its internal args (like
    # `--watchdog-fd`), don't re-wrap it into another start-hyprland process.
    for arg in "$@"; do
      if [ "$arg" = "--watchdog-fd" ] && [ -x "${hyprPkg}/bin/Hyprland" ]; then
        exec "${hyprPkg}/bin/Hyprland" "$@"
      fi
    done

    if [ -x "${hyprPkg}/bin/start-hyprland" ]; then
      exec "${hyprPkg}/bin/start-hyprland" -- "$@"
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

        # Simplified startup: launch QuickShell directly, then exit Hyprland.
        exec-once = sh -c "qs -p ${dmsShellPkg}/share/quickshell/dms >> /var/log/dms-greeter/qs.log 2>&1; hyprctl dispatch exit"
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

    # Ensure log directory exists
    mkdir -p /var/log/dms-greeter
    chown $(id -u):$(id -g) /var/log/dms-greeter

    exec > >(tee -a /var/log/dms-greeter/dms-greeter.log) 2>&1
    echo "--- Starting DMS Greeter at $(date) ---"

    export XKB_DEFAULT_LAYOUT=${lib.escapeShellArg cfg.layout}
    ${lib.optionalString (cfg.variant != "") ''
      export XKB_DEFAULT_VARIANT=${lib.escapeShellArg cfg.variant}
    ''}

    export HOME=${lib.escapeShellArg greeterHome}
    
    # Ensure we are in a writable directory
    cd "$HOME" || { echo "Failed to cd to $HOME"; exit 1; }

    # Ensure XDG_RUNTIME_DIR is set (critical for Wayland socket)
    if [ -z "''${XDG_RUNTIME_DIR:-}" ]; then
      export XDG_RUNTIME_DIR="/run/user/$(id -u)"
      mkdir -p "$XDG_RUNTIME_DIR"
      chmod 0700 "$XDG_RUNTIME_DIR"
    fi

    export XDG_CONFIG_HOME=${lib.escapeShellArg "${greeterHome}/.config"}
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

    echo "Environment prepared. Launching dms-greeter..."
    echo "HOME=$HOME"
    echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
    echo "Compositor: ${cfg.compositor}"

    # Bypass the upstream 'dms-greeter' script because it forcibly appends
    # an 'exec' command that causes a crash loop (qs ...; hyprctl dispatch exit).
    # We manually handle the compositor startup here.

    COMPOSITOR_CONFIG="${pkgs.writeText "dmsgreeter-compositor-config" dmsGreeterCfg.compositor.customConfig}"

    if [ "${cfg.compositor}" = "hyprland" ]; then
      # Hyprland specific launch
      if command -v start-hyprland >/dev/null 2>&1; then
        exec start-hyprland -- --config "$COMPOSITOR_CONFIG"
      else
        exec Hyprland -c "$COMPOSITOR_CONFIG"
      fi
    elif [ "${cfg.compositor}" = "niri" ]; then
      # Niri specific launch
      exec niri -c "$COMPOSITOR_CONFIG"
    elif [ "${cfg.compositor}" = "sway" ]; then
      # Sway specific launch
      exec sway -c "$COMPOSITOR_CONFIG"
    else
      echo "Error: Unsupported compositor '${cfg.compositor}'"
      exit 1
    fi
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

    # Fix: Set the system-level home directory for the 'greeter' user to a writable path.
    # dconf and other libraries rely on /etc/passwd home dir, ignoring the exported env var in some cases.
    users.users.greeter = {
      home = greeterHome;
      createHome = true;
    };

    # Ensure log directory exists and is writable by greeter user
    systemd.tmpfiles.rules = [
      "d /var/log/dms-greeter 0755 greeter greeter -"
      "f /var/log/dms-greeter/dms-greeter.log 0664 greeter greeter -"
      "d /var/lib/dms-greeter 0755 greeter greeter -"
      "d /var/lib/dms-greeter/.config 0755 greeter greeter -"
      "d /var/lib/dms-greeter/.cache 0755 greeter greeter -"
      "d /var/lib/dms-greeter/.local 0755 greeter greeter -"
      "d /var/lib/dms-greeter/.local/state 0755 greeter greeter -"
    ];
  };
}
