# modules/home/niri/default.nix
# ==============================================================================
# Niri Compositor Configuration - Optimized for DankMaterialShell (DMS)
#
# Design goals:
# - Keep Niri config modular (KDL snippets under ~/.config/niri/dms/)
# - Avoid duplicate keybinds inside a single `binds {}` block (hard error).
#
# Refactored:
# - Logic split into binds.nix, rules.nix, settings.nix
# ==============================================================================
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.my.desktop.niri;
  btEnabled = config.my.user.bt.enable or false;
  scriptsEnabled = config.my.user.scripts.enable or false;
  dmsEnabled = config.my.user.dms.enable or false;
  hmLib = lib.hm or config.lib;
  dag = hmLib.dag or config.lib.dag;
  
  # ---------------------------------------------------------------------------
  # Theme & Palette
  # ---------------------------------------------------------------------------
  catppuccin =
    if config ? catppuccin
    then config.catppuccin
    else { flavor = "mocha"; accent = "mauve"; };
  flavor = catppuccin.flavor or "mocha";
  accent = catppuccin.accent or "mauve";
  gtkTheme = "catppuccin-${flavor}-${accent}-standard+normal";
  cursorTheme = "catppuccin-${flavor}-dark-cursors";
  iconTheme =
    if config ? gtk && config.gtk ? iconTheme && config.gtk.iconTheme ? name
    then config.gtk.iconTheme.name
    else "kora";

  palette = {
    #cyan = "#74c7ec";
    cyan = "#00BCD4";
    sky = "#89dceb";
    mauve = "#cba6f7";
    red = "#f38ba8";

    surface0 = "#313244";
    surface1 = "#45475a";

    skyA80 = "#89dceb80";
    mauveA80 = "#cba6f780";
    mauveFF = "#cba6f7ff";
    redFF = "#f38ba8ff";
  };

  # ---------------------------------------------------------------------------
  # Binary Paths & Features
  # ---------------------------------------------------------------------------
  enableWorkflowBinds = cfg.enableWorkflow;

  bins = {
    kitty = "${pkgs.kitty}/bin/kitty";
    dms = "${config.home.profileDirectory}/bin/dms";
    niriSet = "${config.home.profileDirectory}/bin/niri-set";
    clipse = "clipse";
    niriFlow = "${config.home.profileDirectory}/bin/niri-flow";
    niriSticky = "${config.home.profileDirectory}/bin/niri-sticky";
    niriSwitcher = "${if pkgs ? unstable && pkgs.unstable ? niriswitcher then pkgs.unstable.niriswitcher else pkgs.niriswitcher}/bin/niriswitcher";
  };

  # ---------------------------------------------------------------------------
  # Imports
  # ---------------------------------------------------------------------------
  bindsConfig = import ./binds.nix {
    inherit lib pkgs bins enableWorkflowBinds;
  };

  rulesConfig = import ./rules.nix {
    inherit lib config pkgs;
  };

  settingsConfig = import ./settings.nix {
    inherit lib config pkgs palette gtkTheme cursorTheme iconTheme;
  };

  monitorsConfig = import ./monitors.nix {
    inherit lib palette;
  };

  # ---------------------------------------------------------------------------
  # Niri keybind duplicate guard (eval-time)
  #
  # Niri treats duplicate keybinds inside a single `binds {}` block as a hard
  # error. We also assert at eval time to provide a clearer message.
  # ---------------------------------------------------------------------------
  trimLine =
    s:
    let
      m = builtins.match "^[[:space:]]*(.*[^[:space:]])[[:space:]]*$" s;
    in
    if m == null then "" else builtins.elemAt m 0;

  bindKeyFromLine =
    line:
    let
      trimmed = trimLine line;
      m = builtins.match "^([^[:space:]]+)[[:space:]].*\\{.*$" trimmed;
    in
    if trimmed == "" || lib.hasPrefix "//" trimmed || m == null then null else builtins.elemAt m 0;

  bindConfigText = lib.concatStringsSep "\n" [
    bindsConfig.core
    bindsConfig.workflow
    bindsConfig.dms
    bindsConfig.apps
    bindsConfig.mpv
    bindsConfig.workspaces
    bindsConfig.monitors
    cfg.extraBinds
  ];

  bindKeys =
    lib.filter (k: k != null) (map bindKeyFromLine (lib.splitString "\n" bindConfigText));

  bindKeyCount = k: builtins.length (lib.filter (x: x == k) bindKeys);
  duplicateBindKeys = lib.filter (k: bindKeyCount k > 1) (lib.unique bindKeys);
  duplicateBindKeysPretty = map (k: "${k} (x${toString (bindKeyCount k)})") duplicateBindKeys;

  hotkeyMarkdownLineFromLine =
    line:
    let
      trimmed = trimLine line;
      m = builtins.match "^([^[:space:]]+)[[:space:]].*hotkey-overlay-title=\"([^\"]+)\".*\\{.*$" trimmed;
    in
    if trimmed == "" || lib.hasPrefix "//" trimmed || m == null then
      null
    else
      "- `${builtins.elemAt m 0}`: ${builtins.elemAt m 1}";

  hotkeyTsvLineFromLine =
    line:
    let
      trimmed = trimLine line;
      m = builtins.match "^([^[:space:]]+)[[:space:]].*hotkey-overlay-title=\"([^\"]+)\".*\\{.*$" trimmed;
    in
    if trimmed == "" || lib.hasPrefix "//" trimmed || m == null then
      null
    else
      "${builtins.elemAt m 0}\t${builtins.elemAt m 1}";

  hotkeyMarkdownLines =
    lib.filter (l: l != null) (map hotkeyMarkdownLineFromLine (lib.splitString "\n" bindConfigText));

  hotkeyTsvLines = lib.filter (l: l != null) (map hotkeyTsvLineFromLine (lib.splitString "\n" bindConfigText));

  hotkeysMarkdown =
    lib.concatStringsSep "\n" (
      [
        "# Niri hotkeys"
        ""
        "Bu dosya Home-Manager eval sırasında `modules/home/niri/binds.nix` üzerinden otomatik üretilir."
        ""
      ]
      ++ hotkeyMarkdownLines
    )
    + "\n";

  hotkeysTsv = lib.concatStringsSep "\n" hotkeyTsvLines + "\n";

  # ---------------------------------------------------------------------------
  # Niri Configuration Content & Validation
  # ---------------------------------------------------------------------------
  niriConfigText = lib.concatStringsSep "\n" [
    settingsConfig.main
    monitorsConfig.config
    # Allow DankMaterialShell (DMS) to manage output blocks at runtime.
    # (Must exist at startup; we create a writable placeholder in activation.)
    "include \"dms/outputs.kdl\""
    # Runtime monitor/workspace profile generated by `niri-set init`.
    "include \"dms/monitor-auto.kdl\""
    settingsConfig.layout

    # Writable runtime overrides (used by niri-set, e.g. Zen Mode).
    "include \"dms/zen.kdl\""

    # Include DMS generated cursor config
    "include \"dms/cursor.kdl\""

    # Bindings must be inside a SINGLE `binds {}` block.
    "binds {"
    bindsConfig.core
    bindsConfig.layout
    bindsConfig.workflow
    bindsConfig.dms
    bindsConfig.apps
    bindsConfig.mpv
    bindsConfig.workspaces
    bindsConfig.monitors
    cfg.extraBinds
    "}"

    rulesConfig.rules
    cfg.extraRules
    settingsConfig.animations
    settingsConfig.gestures
    settingsConfig.recentWindows
    settingsConfig.colors
    cfg.extraConfig
  ];

  # Perform real validation using `niri validate` during the Nix build.
  # This replaces the brittle regex-based duplicate check.
  niriConfigValidated = pkgs.runCommand "niri-config-validation" {
    nativeBuildInputs = [ cfg.package ];
  } ''
    mkdir -p dms
    # Mock runtime-generated files so niri validate doesn't complain about missing includes.
    touch dms/outputs.kdl dms/monitor-auto.kdl dms/zen.kdl dms/cursor.kdl
    
    cat > config.kdl <<EOF
    ${niriConfigText}
    EOF

    # If validation fails, the whole Home-Manager build will fail with a clear error.
    if ! niri validate --config config.kdl; then
      echo "-----------------------------------------------------------" >&2
      echo "ERROR: Niri configuration validation failed!" >&2
      echo "Check for duplicate keybinds or syntax errors above." >&2
      echo "-----------------------------------------------------------" >&2
      exit 1
    fi
    cp config.kdl $out
  '';

in
{
  imports = [
    inputs.niri.homeModules.niri
  ];


  options.my.desktop.niri = {
    enable = lib.mkEnableOption "Niri compositor (Wayland) configuration";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.niri-unstable;
      defaultText = lib.literalExpression "pkgs.niri-unstable";
      description = "Which Niri build/package to use.";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra KDL appended to the generated Niri config.";
    };

    extraBinds = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra lines appended inside the generated `binds {}` block.";
    };

    extraRules = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra KDL appended after the generated window rules.";
    };

    systemd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable systemd --user session wiring (niri-session.target + session services).";
    };

    btAutoConnectDelaySeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 5;
      description = "Delay (in seconds) before running Bluetooth auto-connect in Niri sessions.";
    };

    bootstrapDelaySeconds = lib.mkOption {
      type = lib.types.ints.between 0 30;
      default = 1;
      description = "Delay before running startup init logic in niri-bootstrap.";
    };

    bootstrapNotifications = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show compact notify-send popups for bootstrap success/failure.";
    };

    initArrangeWindows = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run `niri-set go` during `niri-set init` on startup.";
    };

    initFocusWorkspace = lib.mkOption {
      type = lib.types.nullOr (lib.types.ints.between 1 9);
      default = null;
      description = "Optional workspace index to focus during startup init (null disables forced focus).";
    };

    enableWorkflow = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable daemon-free Niri workflow keybinds and helpers (niri-flow).";
    };

    enableNiriswitcher = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install niriswitcher application switcher";
    };
    
    enableGamingVrrRules = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable VRR window rules for common game launchers (gamescope/steam)";
    };

    preferNoCsd = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Set `prefer-no-csd` in niri config (hint apps to avoid CSD).";
    };

    deactivateUnfocusedWindows = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable `debug.deactivate-unfocused-windows` workaround for some Electron/Chromium apps.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      # Niri module from flake handles package installation via `programs.niri.package`
      programs.niri.enable = true;
      programs.niri.package = cfg.package;
      
      # Ensure portals exist for file pickers, screencast, screenshot, etc.
      my.user.xdg-portal.enable = lib.mkDefault true;

      # Use the validated config file from the Nix store.
      xdg.configFile."niri/config.kdl".source = niriConfigValidated;

      home.packages =
        lib.optional cfg.enableNiriswitcher (if pkgs ? unstable && pkgs.unstable ? niriswitcher then pkgs.unstable.niriswitcher else pkgs.niriswitcher)
        ++ [
          (pkgs.writeShellScriptBin "osc-clipview" ''
            set -euo pipefail
            mime=$(wl-paste --list-types | head -n 1)
            if [[ $mime == image/* ]]; then
              # Use a unique temp file to avoid races between concurrent previews.
              niri msg action spawn -- kitty --class "clip-preview" bash -lc '
                set -euo pipefail
                tmp_img="$(mktemp /tmp/clip_preview.XXXXXX.png)"
                cleanup() { rm -f "$tmp_img"; }
                trap cleanup EXIT INT TERM
                wl-paste >"$tmp_img"
                kitten icat --hold "$tmp_img"
              '
            else
              # Show text in kitty
              niri msg action spawn -- kitty --class "clip-preview" bash -c "wl-paste | less"
            fi
          '')
        ];

      # Helper file for niri-arrange-windows script (still needs to be a file)
      xdg.configFile."niri/dms/workspace-rules.tsv".text = rulesConfig.arrangeRulesTsv;

      # Kısayol cheatsheet (binds.nix hotkey-overlay-title alanlarından).
      xdg.configFile."niri/dms/hotkeys.md".text = hotkeysMarkdown;
      xdg.configFile."niri/dms/hotkeys.tsv".text = hotkeysTsv;

      # DMS generates some Niri snippets (cursor.kdl, outputs.kdl, alttab.kdl, …)
      # at runtime. Home-Manager's `xdg.configFile` would create Nix-store symlinks
      # which are read-only and break that workflow, so we ensure real files here.
      home.activation.niriDmsRuntimeFiles = dag.entryAfter [ "writeBoundary" ] ''
        set -eu

        DMS_DIR=${lib.escapeShellArg "${config.xdg.configHome}/niri/dms"}
        mkdir -p "$DMS_DIR"

        ensure_writable_file() {
          local f="$1"

          # Remove Nix store symlinks (or other non-regular nodes).
          if [ -L "$f" ]; then
            rm -f "$f"
          elif [ -e "$f" ] && [ ! -f "$f" ]; then
            rm -rf "$f"
          fi

          if [ ! -f "$f" ]; then
            : >"$f"
          fi
        }

        ensure_writable_file "$DMS_DIR/cursor.kdl"
        ensure_writable_file "$DMS_DIR/outputs.kdl"
        ensure_writable_file "$DMS_DIR/monitor-auto.kdl"
        ensure_writable_file "$DMS_DIR/alttab.kdl"
      '';

      # Keep Zen override file writable (niri watches include files and live-reloads).
      home.activation.niriZenConfig = dag.entryAfter [ "writeBoundary" ] ''
        set -eu

        ZEN_FILE=${lib.escapeShellArg "${config.xdg.configHome}/niri/dms/zen.kdl"}
        ZEN_DIR="$(dirname "$ZEN_FILE")"

        mkdir -p "$ZEN_DIR"

        # Ensure it's a normal, writable file (not a Nix store symlink).
        if [ -L "$ZEN_FILE" ]; then
          rm -f "$ZEN_FILE"
        fi

        if [ ! -f "$ZEN_FILE" ]; then
          : >"$ZEN_FILE"
        fi

        # Migration: older niri-set zen wrote invalid inline KDL like `border { off }`.
        if grep -qE 'border[[:space:]]*\\{[[:space:]]*off[[:space:]]*\\}' "$ZEN_FILE" 2>/dev/null; then
          cat >"$ZEN_FILE" <<'EOF'
layout {
  gaps 0;

  border {
    off;
  }

  focus-ring {
    off;
  }

  tab-indicator {
    off;
  }

  insert-hint {
    off;
  }
}
EOF
        fi
      '';
    }

    (lib.mkIf cfg.systemd.enable {
      # -------------------------------------------------------------------------
      # Systemd --user integration for Niri sessions
      # -------------------------------------------------------------------------

      systemd.user.targets.niri-session.Unit = {
        Description = "Niri session (user services)";
        Wants = [ "graphical-session.target" "xdg-desktop-autostart.target" ];
        After = [ "graphical-session.target" "dbus.service" ];
        BindsTo = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      # Polkit agent:
      # - Skip this when DMS is enabled (DMS already provides a listener).
      # - Prevent duplicate agent registration warnings.
      systemd.user.services.niri-polkit-agent = lib.mkIf (!dmsEnabled) {
        Unit = {
          Description = "Polkit authentication agent (polkit-gnome)";
          After = [ "graphical-session.target" "niri-session.target" ];
          PartOf = [ "niri-session.target" ];
          ConditionEnvironment = [ "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP=niri" ];
        };
        Service = {
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          StandardOutput = "journal";
          StandardError = "journal";
        };
        Install = {
          WantedBy = [ "niri-session.target" ];
        };
      };

      # A tiny readiness gate for compositor-dependent services.
      # (Used by DMS and other daemons that need a working NIRI_SOCKET.)
      systemd.user.services.niri-ready = {
        Unit = {
          Description = "Niri ready (IPC/socket)";
          After = [ "graphical-session.target" "niri-session.target" ];
          PartOf = [ "niri-session.target" ];
          ConditionEnvironment = [ "WAYLAND_DISPLAY" "NIRI_SOCKET" "XDG_CURRENT_DESKTOP=niri" ];
        };
        Service = {
          Type = "oneshot";
          TimeoutStartSec = 60;
          RemainAfterExit = true;
          ExecStart = "${pkgs.bash}/bin/bash -lc 'for ((i=0;i<200;i++)); do ${cfg.package}/bin/niri msg version >/dev/null 2>&1 && exit 0; sleep 0.1; done; echo \"niri-ready: timeout waiting for IPC\" >&2; exit 1'";
          StandardOutput = "journal";
          StandardError = "journal";
        };
        Install = {
          WantedBy = [ "niri-session.target" ];
        };
      };

      # Bootstrap runs only startup init.
      # Long-running daemons are managed as independent units below.
      systemd.user.services.niri-bootstrap = {
        Unit = {
          Description = "Niri bootstrap (init)";
          Requires = [ "niri-ready.service" ];
          Wants = [ "pipewire.service" "wireplumber.service" ];
          After = [ "graphical-session.target" "niri-session.target" "niri-ready.service" "pipewire.service" "wireplumber.service" ];
          PartOf = [ "niri-session.target" ];
          ConditionEnvironment = [ "WAYLAND_DISPLAY" "NIRI_SOCKET" "XDG_CURRENT_DESKTOP=niri" ];
        };
        Service = {
          Type = "oneshot";
          TimeoutStartSec = 60;
          Environment = [
            "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/%u/bin"
            "NIRI_BOOT_DELAY=${toString cfg.bootstrapDelaySeconds}"
          ];
          ExecStart = "${pkgs.bash}/bin/bash -lc '${pkgs.writeShellScript "niri-bootstrap" ''
            set -eEuo pipefail

            warn() { printf "[niri-bootstrap] WARN: %s\n" "$*" >&2; }
            ${lib.optionalString cfg.bootstrapNotifications ''
              boot_notify() {
                local urgency="''${1:-normal}"
                local body="''${2:-Init tamamlandı}"
                if command -v notify-send >/dev/null 2>&1; then
                  notify-send -a "Niri" -u "$urgency" -t 2200 "Niri Bootstrap" "$body" >/dev/null 2>&1 || true
                fi
              }

              on_err() {
                boot_notify critical "Init başarısız (journalctl --user -u niri-bootstrap.service -b)"
              }
              trap on_err ERR
            ''}

            delay_s="''${NIRI_BOOT_DELAY:-1}"
            [[ "$delay_s" =~ ^[0-9]+$ ]] || delay_s=1
            sleep "$delay_s"

            if command -v niri-set >/dev/null 2>&1; then
              ${lib.optionalString (!cfg.initArrangeWindows) "export NIRI_INIT_SKIP_ARRANGE=1"}
              ${lib.optionalString (cfg.initFocusWorkspace == null) "export NIRI_INIT_SKIP_FOCUS_WORKSPACE=1"}
              ${lib.optionalString (cfg.initFocusWorkspace != null) "export NIRI_INIT_FOCUS_WORKSPACE=${toString cfg.initFocusWorkspace}"}
              if ! niri-set init; then
                warn "niri-set init failed"
                exit 1
              fi
            else
              warn "niri-set not found"
              exit 1
            fi

            ${lib.optionalString cfg.bootstrapNotifications ''
              trap - ERR
              boot_notify normal "Init tamamlandı"
            ''}
          ''}'";
          StandardOutput = "journal";
          StandardError = "journal";
        };
        Install = {
          WantedBy = [ "niri-session.target" ];
        };
      };

      systemd.user.services.niri-sticky = {
        Unit = {
          Description = "Niri: sticky daemon";
          After = [ "graphical-session.target" "niri-session.target" "niri-ready.service" ];
          PartOf = [ "niri-session.target" ];
          ConditionEnvironment = [ "WAYLAND_DISPLAY" "NIRI_SOCKET" "XDG_CURRENT_DESKTOP=niri" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${bins.niriSticky}";
          Restart = "on-failure";
          RestartSec = 2;
          StandardOutput = "journal";
          StandardError = "journal";
        };
        Install = {
          WantedBy = [ "niri-session.target" ];
        };
      };

      systemd.user.services.niriswitcher = lib.mkIf cfg.enableNiriswitcher {
        Unit = {
          Description = "Niri: niriswitcher daemon";
          After = [ "graphical-session.target" "niri-session.target" "niri-ready.service" ];
          PartOf = [ "niri-session.target" ];
          ConditionEnvironment = [ "WAYLAND_DISPLAY" "NIRI_SOCKET" "XDG_CURRENT_DESKTOP=niri" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${bins.niriSwitcher}";
          Restart = "on-failure";
          RestartSec = 2;
          StandardOutput = "journal";
          StandardError = "journal";
        };
        Install = {
          WantedBy = [ "niri-session.target" ];
        };
      };

      systemd.user.services.niri-bt-autoconnect = lib.mkIf (btEnabled && scriptsEnabled) {
        Unit = {
          Description = "Niri: Bluetooth autoconnect";
          Wants = [ "pipewire.service" "wireplumber.service" "niri-ready.service" ];
          After = [ "graphical-session.target" "niri-session.target" "niri-ready.service" "pipewire.service" "wireplumber.service" ];
          PartOf = [ "niri-session.target" ];
          ConditionEnvironment = [ "WAYLAND_DISPLAY" "NIRI_SOCKET" "XDG_CURRENT_DESKTOP=niri" ];
        };
        Service = {
          Type = "oneshot";
          TimeoutStartSec = 120;
          Environment = [
            "NIRI_BOOT_BT_DELAY=${toString cfg.btAutoConnectDelaySeconds}"
            "NIRI_BOOT_BT_TIMEOUT=${toString config.my.user.bt.autoToggle.timeoutSeconds}"
          ];
          ExecStart = "${pkgs.bash}/bin/bash -lc '${pkgs.writeShellScript "niri-bt-autoconnect" ''
            set -euo pipefail

            delay_s="''${NIRI_BOOT_BT_DELAY:-5}"
            timeout_s="''${NIRI_BOOT_BT_TIMEOUT:-30}"

            [[ "$delay_s" =~ ^[0-9]+$ ]] || delay_s=5
            [[ "$timeout_s" =~ ^[0-9]+$ ]] || timeout_s=30

            sleep "$delay_s"
            if command -v bluetooth_toggle >/dev/null 2>&1; then
              timeout "''${timeout_s}s" bluetooth_toggle --connect || true
            fi
          ''}'";
          StandardOutput = "journal";
          StandardError = "journal";
        };
        Install = {
          WantedBy = [ "niri-session.target" ];
        };
      };
    })
  ]);
}
