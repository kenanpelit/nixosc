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
  username = config.home.username;
  btEnabled = config.my.user.bt.enable or false;
  scriptsEnabled = config.my.user.scripts.enable or false;
  
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
    else "a-candy-beauty-icon-theme";

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
  enableNiriusBinds = cfg.enableNirius;

  bins = {
    kitty = "${pkgs.kitty}/bin/kitty";
    dms = "${config.home.profileDirectory}/bin/dms";
    niriSet = "${config.home.profileDirectory}/bin/niri-set";
    clipse = "clipse";
    niriusd = "${pkgs.nirius}/bin/niriusd";
    nirius  = "${pkgs.nirius}/bin/nirius";
    niriuswitcher = "${pkgs.niriswitcher}/bin/niriswitcher";
    nsticky = "${inputs.nsticky.packages.${pkgs.stdenv.hostPlatform.system}.nsticky}/bin/nsticky";
    mpvManager = "${config.home.profileDirectory}/bin/mpv-manager";
  };

  # ---------------------------------------------------------------------------
  # Imports
  # ---------------------------------------------------------------------------
  bindsConfig = import ./binds.nix {
    inherit lib pkgs bins enableNiriusBinds;
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
    bindsConfig.nirius
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

    initDelaySeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 3;
      description = "Delay (in seconds) before running niri-init after session start.";
    };

    btAutoConnectDelaySeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 5;
      description = "Delay (in seconds) before running Bluetooth auto-connect in Niri sessions.";
    };

    enableNirius = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install nirius daemon and CLI helpers";
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
      assertions = [
        {
          assertion = duplicateBindKeys == [ ];
          message =
            "Niri duplicate keybinds detected (binds must be unique): ${lib.concatStringsSep ", " duplicateBindKeysPretty}";
        }
      ];

      # Niri module from flake handles package installation via `programs.niri.package`
      programs.niri.enable = true;
      programs.niri.package = cfg.package;

      # Ensure portals exist for file pickers, screencast, screenshot, etc.
      my.user.xdg-portal.enable = lib.mkDefault true;

      # Use programs.niri.config for build-time validation!
      # We concatenate all parts into one big KDL string to avoid 'include' issues during validation.
      programs.niri.config = lib.concatStringsSep "\n" [
        settingsConfig.main
        monitorsConfig.config
        settingsConfig.layout

        # Bindings must be inside a SINGLE `binds {}` block.
        "binds {"
        bindsConfig.core
        bindsConfig.nirius
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

      home.packages =
        lib.optional cfg.enableNirius pkgs.nirius
        ++ lib.optional cfg.enableNiriswitcher pkgs.niriswitcher
        ++ [
          inputs.nsticky.packages.${pkgs.stdenv.hostPlatform.system}.nsticky
          (pkgs.writeShellScriptBin "osc-clipview" ''
            set -euo pipefail
            mime=$(wl-paste --list-types | head -n 1)
            if [[ $mime == image/* ]]; then
              # Use kitty's icat to show image, holding open with read
              niri msg action spawn -- kitty --class "clip-preview" bash -c "wl-paste > /tmp/clip_preview.png && kitten icat --hold /tmp/clip_preview.png"
            else
              # Show text in kitty
              niri msg action spawn -- kitty --class "clip-preview" bash -c "wl-paste | less"
            fi
          '')
        ]
        ++ lib.optional (builtins.hasAttr "xwayland-satellite" pkgs) pkgs."xwayland-satellite";

      # Helper file for niri-arrange-windows script (still needs to be a file)
      xdg.configFile."niri/dms/workspace-rules.tsv".text = rulesConfig.arrangeRulesTsv;

      # Kısayol cheatsheet (binds.nix hotkey-overlay-title alanlarından).
      xdg.configFile."niri/dms/hotkeys.md".text = hotkeysMarkdown;
      xdg.configFile."niri/dms/hotkeys.tsv".text = hotkeysTsv;

      # Deprecated placeholder (kept to avoid stale references)
      xdg.configFile."niri/dms/alttab.kdl".text = "";
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

      # Polkit agent (required for auth prompts in non-GNOME sessions).
      systemd.user.services.niri-polkit-agent = {
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
          TimeoutStartSec = 15;
          ExecStart = "${pkgs.bash}/bin/bash -lc 'for ((i=0;i<150;i++)); do /etc/profiles/per-user/${username}/bin/niri msg version >/dev/null 2>&1 && exit 0; sleep 0.1; done; exit 0'";
          StandardOutput = "journal";
          StandardError = "journal";
        };
        Install = {
          WantedBy = [ "niri-session.target" ];
        };
      };

      # Bootstrap: fast and observable (oneshot).
      # Keep this unit short-running; move slow/flaky tasks (like BT audio routing)
      # into separate services/timers so startup doesn't appear "stuck".
      systemd.user.services.niri-init = {
        Unit = {
          Description = "Niri bootstrap (monitors + audio + layout)";
          Wants = [ "pipewire.service" "wireplumber.service" ];
          After = [ "graphical-session.target" "niri-session.target" "pipewire.service" "wireplumber.service" ];
          PartOf = [ "niri-session.target" ];
          ConditionEnvironment = [ "WAYLAND_DISPLAY" "NIRI_SOCKET" "XDG_CURRENT_DESKTOP=niri" ];
        };
        Service = {
          Type = "oneshot";
          TimeoutStartSec = 60;
          RemainAfterExit = true;
          Environment = [
            "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/%u/bin"
          ];
          ExecStart = "${pkgs.bash}/bin/bash -lc 'sleep ${toString cfg.initDelaySeconds}; for ((i=0;i<120;i++)); do /etc/profiles/per-user/${username}/bin/niri msg version >/dev/null 2>&1 && break; sleep 0.1; done; /etc/profiles/per-user/${username}/bin/niri-set init'";
          ExecStartPost = "${pkgs.bash}/bin/bash -lc 'command -v notify-send >/dev/null 2>&1 && notify-send -t 2500 \"Niri\" \"Bootstrap tamamlandı\" || true'";
          StandardOutput = "journal";
          StandardError = "journal";
        };
        Install = {
          WantedBy = [ "niri-session.target" ];
        };
      };

      # Bluetooth auto-connect: run later via timer; never block the init unit.
      systemd.user.services.niri-bt-autoconnect = lib.mkIf (btEnabled && scriptsEnabled) {
        Unit = {
          Description = "Niri Bluetooth auto-connect";
          Wants = [ "pipewire.service" "wireplumber.service" ];
          After = [ "graphical-session.target" "niri-session.target" "pipewire.service" "wireplumber.service" "niri-init.service" ];
          PartOf = [ "niri-session.target" ];
          ConditionEnvironment = [ "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP=niri" ];
        };
        Service = {
          Type = "oneshot";
          TimeoutStartSec = "${toString config.my.user.bt.autoToggle.timeoutSeconds}s";
          Environment = [
            "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/%u/bin"
          ];
          ExecStart = "${pkgs.bash}/bin/bash -lc '/etc/profiles/per-user/${username}/bin/bluetooth_toggle --connect'";
          Restart = "on-failure";
          RestartSec = 10;
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };

      systemd.user.timers.niri-bt-autoconnect = lib.mkIf (btEnabled && scriptsEnabled) {
        Unit = {
          Description = "Niri Bluetooth auto-connect (delayed)";
          After = [ "niri-session.target" ];
          PartOf = [ "niri-session.target" ];
        };
        Timer = {
          OnActiveSec = "${toString cfg.btAutoConnectDelaySeconds}s";
          AccuracySec = "5s";
          Unit = "niri-bt-autoconnect.service";
        };
        Install = {
          WantedBy = [ "niri-session.target" ];
        };
      };

      systemd.user.services.niri-nsticky = {
        Unit = {
          Description = "nsticky daemon (niri)";
          After = [ "graphical-session.target" "niri-session.target" "niri-ready.service" ];
          Wants = [ "niri-ready.service" ];
          PartOf = [ "niri-session.target" ];
          ConditionEnvironment = [ "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP=niri" ];
        };
        Service = {
          ExecStart = "${bins.nsticky}";
          Restart = "on-failure";
          RestartSec = 1;
          StandardOutput = "journal";
          StandardError = "journal";
        };
        Install = {
          WantedBy = [ "niri-session.target" ];
        };
      };

      systemd.user.services.niri-niriusd = lib.mkIf cfg.enableNirius {
        Unit = {
          Description = "nirius daemon (niri)";
          After = [ "graphical-session.target" "niri-session.target" "niri-ready.service" ];
          Wants = [ "niri-ready.service" ];
          PartOf = [ "niri-session.target" ];
          ConditionEnvironment = [ "WAYLAND_DISPLAY" "NIRI_SOCKET" "XDG_CURRENT_DESKTOP=niri" ];
        };
        Service = {
          ExecStart = "${bins.niriusd}";
          Restart = "on-failure";
          RestartSec = 1;
          StandardOutput = "journal";
          StandardError = "journal";
        };
        Install = {
          WantedBy = [ "niri-session.target" ];
        };
      };

      systemd.user.services.niri-niriswitcher = lib.mkIf cfg.enableNiriswitcher {
        Unit = {
          Description = "niriswitcher (niri)";
          After = [ "graphical-session.target" "niri-session.target" "niri-ready.service" ];
          Wants = [ "niri-ready.service" ];
          PartOf = [ "niri-session.target" ];
          ConditionEnvironment = [ "WAYLAND_DISPLAY" "NIRI_SOCKET" "XDG_CURRENT_DESKTOP=niri" ];
        };
        Service = {
          ExecStart = "${bins.niriuswitcher}";
          Restart = "on-failure";
          RestartSec = 1;
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
