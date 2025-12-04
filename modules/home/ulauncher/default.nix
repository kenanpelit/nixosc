# modules/home/ulauncher/default.nix
# ==============================================================================
# Ulauncher Application Launcher Configuration
# ==============================================================================
{ pkgs, lib, config, ... }: 
let
  cfg = config.my.user.ulauncher;
  hmLib = lib.hm or config.lib;
  dag = hmLib.dag or config.lib.dag;
  ulauncher_config = ./config;
  
  # =============================================================================
  # Shortcuts Management Script
  # =============================================================================
  manageShortcutsScript = pkgs.writeScriptBin "manage-ulauncher-shortcuts" ''
    #!/usr/bin/env bash
    set -euo pipefail
    configDir="$HOME/.config/ulauncher"
    shortcutsFile="$configDir/shortcuts.json"
    # Ensure config directory exists
    mkdir -p "$configDir"
    # Define shortcuts configuration
    cat > "$shortcutsFile" << 'EOF'
    {
      "e3da2cba-0674-4f5f-9fc1-4095343b22e5": {
          "id": "e3da2cba-0674-4f5f-9fc1-4095343b22e5",
          "name": "Google Search",
          "keyword": "g",
          "cmd": "https://google.com/search?q=%s",
          "icon": "/nix/store/q54fmb9h1xdn0xy1s29vw2c01mhrm7gw-ulauncher-5.15.7/share/ulauncher/media/google-search-icon.png",
          "is_default_search": true,
          "run_without_argument": false,
          "added": 1737661428.837797
      },
      "bdfb7c37-7e1f-4ea6-baae-28c3f9b670b5": {
          "id": "bdfb7c37-7e1f-4ea6-baae-28c3f9b670b5",
          "name": "Stack Overflow",
          "keyword": "so",
          "cmd": "https://stackoverflow.com/search?q=%s",
          "icon": "/nix/store/q54fmb9h1xdn0xy1s29vw2c01mhrm7gw-ulauncher-5.15.7/share/ulauncher/media/stackoverflow-icon.svg",
          "is_default_search": true,
          "run_without_argument": false,
          "added": 1737661428.8378139
      },
      "78dba65a-c058-431a-8996-e94e23c74fd3": {
          "id": "78dba65a-c058-431a-8996-e94e23c74fd3",
          "name": "Wikipedia",
          "keyword": "wiki",
          "cmd": "https://en.wikipedia.org/wiki/%s",
          "icon": "/nix/store/q54fmb9h1xdn0xy1s29vw2c01mhrm7gw-ulauncher-5.15.7/share/ulauncher/media/wikipedia-icon.png",
          "is_default_search": true,
          "run_without_argument": false,
          "added": 1737661428.8378263
      }
    }
    EOF
    # Adjust file paths
    sed -i "s|\\\$HOME|$HOME|g" "$shortcutsFile"
  '';
in {
  options.my.user.ulauncher = {
    enable = lib.mkEnableOption "Ulauncher";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Service Configuration
    # =============================================================================
    systemd.user.services.ulauncher = {
      Unit = {
        Description = "ulauncher application launcher service";
        Documentation = "https://ulauncher.io";
        After = ["graphical-session-pre.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.bash}/bin/bash -lc '${pkgs.ulauncher}/bin/ulauncher --hide-window'";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  
    # =============================================================================
    # Configuration Files
    # =============================================================================
    xdg.configFile = {
      "ulauncher" = {
        recursive = true;
        source = "${ulauncher_config}";
      };
    };
  
    # =============================================================================
    # Activation Script
    # =============================================================================
    home.activation.manageShortcuts = dag.entryAfter ["writeBoundary"] ''
      ${manageShortcutsScript}/bin/manage-ulauncher-shortcuts
    '';
  };
}
