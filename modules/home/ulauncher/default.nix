# modules/home/ulauncher/default.nix
# ==============================================================================
# Ulauncher Application Launcher Configuration
# ==============================================================================
{ pkgs, lib, ... }: 
let
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
      # Search Shortcut
      "6524dac6-7723-4a88-b920-65b1f96ee946": {
          "id": "6524dac6-7723-4a88-b920-65b1f96ee946",
          "name": "search",
          "keyword": "br",
          "cmd": "https://search.brave.com/search?q=%s",
          "icon": "~/.config/ulauncher/brave.png",
          "is_default_search": true,
          "run_without_argument": false,
          "added": 1684850439.0202124
      },
      
      # Quit All Applications Shortcut
      "0eb1c1b7-8e36-4a13-abd4-0b6bb1f7bdb9": {
          # ... (shortcut configuration)
      },
      
      # Work Tools Shortcut
      "b7d20d83-ca3d-4c5d-8705-1b567fa8dcee": {
          # ... (shortcut configuration)
      }
    }
    EOF

    # Adjust file paths
    sed -i "s|\\\$HOME|$HOME|g" "$shortcutsFile"
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
  home.activation.manageShortcuts = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${manageShortcutsScript}/bin/manage-ulauncher-shortcuts
  '';
}
