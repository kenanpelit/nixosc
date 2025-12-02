# modules/home/touchegg/default.nix
# ==============================================================================
# Touchégg Multi-Desktop Gesture Configuration
# ==============================================================================
{ config, pkgs, lib, ... }:

let
  # Desktop-specific configurations
  toucheggConfigs = {
    # Hyprland Configuration
    hyprland = ''
      <touchégg>
        <settings>
          <property name="animation_delay">150</property>
          <property name="action_execute_threshold">10</property>
          <property name="color">auto</property>
          <property name="borderColor">auto</property>
        </settings>

        <application name="All">
          <!-- Three Finger Gestures - Hyprland Workspace Navigation -->
          <gesture type="SWIPE" fingers="3" direction="RIGHT">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>hypr-workspace-monitor -tn</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="3" direction="LEFT">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>hypr-workspace-monitor -tp</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="3" direction="UP">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>hypr-workspace-monitor -wt</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="3" direction="DOWN">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>hypr-workspace-monitor -mt</command>
              <on>begin</on>
            </action>
          </gesture>

          <!-- Four Finger Gestures - Hyprland Special Actions -->
          <gesture type="SWIPE" fingers="4" direction="UP">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>hypr-workspace-monitor -msf</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="4" direction="DOWN">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>hypr-workspace-monitor -ms</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="4" direction="RIGHT">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>hypr-workspace-monitor -wr</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="4" direction="LEFT">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>hypr-workspace-monitor -wl</command>
              <on>begin</on>
            </action>
          </gesture>

          <!-- Pinch Gestures -->
          <gesture type="PINCH" fingers="3" direction="IN">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>hyprctl dispatch fullscreen 1</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="PINCH" fingers="3" direction="OUT">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>hyprctl dispatch fullscreen 0</command>
              <on>begin</on>
            </action>
          </gesture>
        </application>
      </touchégg>
    '';

    # GNOME Configuration
    gnome = ''
      <touchégg>
        <settings>
          <property name="animation_delay">150</property>
          <property name="action_execute_threshold">10</property>
          <property name="color">auto</property>
          <property name="borderColor">auto</property>
        </settings>

        <application name="All">
          <!-- Three Finger Gestures - GNOME Workspace Navigation -->
          
          <!-- 3 Finger Up: Activities Overview -->
          <gesture type="SWIPE" fingers="3" direction="UP">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval 'Main.overview.show();'</command>
              <on>begin</on>
            </action>
          </gesture>

          <!-- 3 Finger Down: Show Desktop -->
          <gesture type="SWIPE" fingers="3" direction="DOWN">
            <action type="SHOW_DESKTOP">
              <animate>true</animate>
            </action>
          </gesture>

          <!-- 3 Finger Left: Previous Workspace (Ctrl+Alt+Left) -->
          <gesture type="SWIPE" fingers="3" direction="LEFT">
            <action type="SEND_KEYS">
              <repeat>false</repeat>
              <keys>Control_L+Alt_L+Left</keys>
              <on>begin</on>
            </action>
          </gesture>

          <!-- 3 Finger Right: Next Workspace (Ctrl+Alt+Right) -->
          <gesture type="SWIPE" fingers="3" direction="RIGHT">
            <action type="SEND_KEYS">
              <repeat>false</repeat>
              <keys>Control_L+Alt_L+Right</keys>
              <on>begin</on>
            </action>
          </gesture>

          <!-- Four Finger Gestures - Window Management -->
          
          <!-- 4 Finger Up: Move Window to Upper Monitor (Super+Shift+Up) -->
          <gesture type="SWIPE" fingers="4" direction="UP">
            <action type="SEND_KEYS">
              <repeat>false</repeat>
              <keys>Super_L+Shift_L+Up</keys>
              <on>begin</on>
            </action>
          </gesture>

          <!-- 4 Finger Down: Move Window to Lower Monitor (Super+Shift+Down) -->
          <gesture type="SWIPE" fingers="4" direction="DOWN">
            <action type="SEND_KEYS">
              <repeat>false</repeat>
              <keys>Super_L+Shift_L+Down</keys>
              <on>begin</on>
            </action>
          </gesture>

          <!-- 4 Finger Left: Move Window to Left Workspace (Super+Shift+Page_Up) -->
          <gesture type="SWIPE" fingers="4" direction="LEFT">
            <action type="SEND_KEYS">
              <repeat>false</repeat>
              <keys>Super_L+Shift_L+Page_Up</keys>
              <on>begin</on>
            </action>
          </gesture>

          <!-- 4 Finger Right: Move Window to Right Workspace (Super+Shift+Page_Down) -->
          <gesture type="SWIPE" fingers="4" direction="RIGHT">
            <action type="SEND_KEYS">
              <repeat>false</repeat>
              <keys>Super_L+Shift_L+Page_Down</keys>
              <on>begin</on>
            </action>
          </gesture>

          <!-- Pinch Gestures - Window State -->
          
          <!-- Pinch In: Maximize Window -->
          <gesture type="PINCH" fingers="3" direction="IN">
            <action type="MAXIMIZE_RESTORE_WINDOW">
              <animate>true</animate>
            </action>
          </gesture>

          <!-- Pinch Out: Restore Window -->
          <gesture type="PINCH" fingers="3" direction="OUT">
            <action type="MAXIMIZE_RESTORE_WINDOW">
              <animate>true</animate>
            </action>
          </gesture>
        </application>
      </touchégg>
    '';
  };

  # Config selector script
  selectToucheggConfig = pkgs.writeShellScript "touchegg-select-config" ''
    CONFIG_DIR="$HOME/.config/touchegg"
    
    # Ensure config directory exists
    mkdir -p "$CONFIG_DIR"
    
    # Detect desktop environment
    DESKTOP="''${XDG_CURRENT_DESKTOP,,}"  # Convert to lowercase
    
    case "$DESKTOP" in
      gnome)
        echo "Touchégg: Configuring for GNOME"
        CONFIG_SOURCE="$CONFIG_DIR/gnome.conf"
        ;;
      hyprland)
        echo "Touchégg: Configuring for Hyprland"
        CONFIG_SOURCE="$CONFIG_DIR/hyprland.conf"
        ;;
      *)
        echo "Touchégg: Unknown desktop '$DESKTOP', using Hyprland config as fallback"
        CONFIG_SOURCE="$CONFIG_DIR/hyprland.conf"
        ;;
    esac
    
    # Create symlink to active config
    if [ -f "$CONFIG_SOURCE" ]; then
      ln -sf "$CONFIG_SOURCE" "$CONFIG_DIR/touchegg.conf"
      echo "Touchégg: Active config -> $CONFIG_SOURCE"
    else
      echo "Touchégg: ERROR - Config file not found: $CONFIG_SOURCE"
      exit 1
    fi
  '';

in
{
  # =============================================================================
  # Desktop-Specific Configuration Files
  # =============================================================================
  xdg.configFile = {
    "touchegg/hyprland.conf".text = toucheggConfigs.hyprland;
    "touchegg/gnome.conf".text = toucheggConfigs.gnome;
  };

  # =============================================================================
  # Systemd Service Configuration
  # =============================================================================
  systemd.user.services.touchegg = {
    Unit = {
      Description = "Touchégg Multi-Desktop Gesture Daemon";
      Documentation = "https://github.com/JoseExposito/touchegg";
      After = [ "graphical-session-pre.target" "dbus.service" ];
      PartOf = [ "graphical-session.target" ];
      Requires = [ "dbus.service" ];
    };

    Service = {
      Type = "simple";
      
      # Select correct config before starting
      ExecStartPre = [
        "${pkgs.coreutils}/bin/sleep 2"
        "${selectToucheggConfig}"
      ];
      
      ExecStart = "${pkgs.touchegg}/bin/touchegg --daemon";
      
      Restart = "on-failure";
      RestartSec = "3s";
      
      Environment = [
        "XDG_RUNTIME_DIR=/run/user/%U"
      ];
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
