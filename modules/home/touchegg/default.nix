{ config, pkgs, lib, ... }:
{
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

  xdg.configFile."touchegg/touchegg.conf" = {
    text = ''
      <touchégg>
        <settings>
          <property name="animation_delay">150</property>
          <property name="action_execute_threshold">10</property>
          <property name="color">auto</property>
          <property name="borderColor">auto</property>
        </settings>
        <application name="All">
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
