# ==============================================================================
# Ulauncher Application Launcher Configuration
# ==============================================================================
{ pkgs, lib, config, ... }: 
let
  ulauncher_config = ./config;
  
  # =============================================================================
  # Shortcuts Management Script
  # =============================================================================
  manageShortcutsScript = pkgs.writeScriptBin "manage-ulauncher-shortcuts" ''
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Only create directories if they don't exist
    [ ! -d "$HOME/.config/ulauncher" ] && mkdir -p "$HOME/.config/ulauncher"
    [ ! -d "$HOME/.local/share/ulauncher/extensions" ] && mkdir -p "$HOME/.local/share/ulauncher/extensions"
    
    # Only update permissions if needed
    [ ! -w "$HOME/.config/ulauncher" ] && chmod -R u+w "$HOME/.config/ulauncher"
    [ ! -w "$HOME/.local/share/ulauncher" ] && chmod -R u+w "$HOME/.local/share/ulauncher"
    
    # Define shortcuts configuration
    SHORTCUTS_CONTENT='{
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
    }'
    
    # Only write shortcuts if file doesn't exist or content is different
    SHORTCUTS_FILE="$HOME/.config/ulauncher/shortcuts.json"
    if [ ! -f "$SHORTCUTS_FILE" ] || [ "$(cat $SHORTCUTS_FILE)" != "$SHORTCUTS_CONTENT" ]; then
      echo "$SHORTCUTS_CONTENT" > "$SHORTCUTS_FILE"
      chmod 644 "$SHORTCUTS_FILE"
    fi

    # Only copy config files if they don't exist or are different
    for file in ${ulauncher_config}/*; do
      base_name=$(basename "$file")
      target="$HOME/.config/ulauncher/$base_name"
      if [ ! -f "$target" ] || ! cmp -s "$file" "$target"; then
        cp -f "$file" "$target"
      fi
    done
  '';
in {
  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = with pkgs; [ ulauncher ];

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
      Environment = [
        "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
      ];
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  # =============================================================================
  # Activation Script
  # =============================================================================
  home.activation.manageShortcuts = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${manageShortcutsScript}/bin/manage-ulauncher-shortcuts
  '';
}

