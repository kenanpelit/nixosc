# modules/home/touchegg/default.nix
# ==============================================================================
# Touchégg Gesture Configuration
# ==============================================================================
{ config, pkgs, lib, ... }:
{
  # =============================================================================
  # Systemd Service Configuration
  # =============================================================================
  systemd.user.services.touchegg = {
    Unit = {
      Description = "Touchégg Daemon (User)";
      After = [ "graphical-session-pre.target" "dbus.service" "hyprland-session.target" ];
      PartOf = [ "graphical-session.target" ];
      Requires = [ "dbus.service" ];
    };

    Service = {
      ExecStart = "${pkgs.touchegg}/bin/touchegg --daemon";
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
      Restart = "always";
      RestartSec = "3s";
      Type = "simple";
      Environment = [
        "XDG_RUNTIME_DIR=/run/user/%U"
        "WAYLAND_DISPLAY=${if config.wayland.windowManager.hyprland.enable then "wayland-1" else ""}"
      ];
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # =============================================================================
  # Gesture Configuration
  # =============================================================================
  xdg.configFile."touchegg/touchegg.conf" = {
    text = ''
      <touchégg>
        # ---------------------------------------------------------------------------
        # Global Settings
        # ---------------------------------------------------------------------------
        <settings>
          <property name="animation_delay">150</property>
          <property name="action_execute_threshold">10</property>
          <property name="color">auto</property>
          <property name="borderColor">auto</property>
        </settings>

        # ---------------------------------------------------------------------------
        # Application-wide Gestures
        # ---------------------------------------------------------------------------
        <application name="All">
          # Two Finger Gestures
          <gesture type="SWIPE" fingers="2" direction="RIGHT">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>hypr-workspace-monitor -vn</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="2" direction="LEFT">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>hypr-workspace-monitor -vp</command>
              <on>begin</on>
            </action>
          </gesture>

          # Three Finger Gestures
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

          # Four Finger Gestures
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
        </application>
      </touchégg>
    '';
    executable = true;
  };
}
