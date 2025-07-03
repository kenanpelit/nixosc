# modules/home/services/touchegg/default.nix
# ==============================================================================
# Touchégg Gesture Configuration for GNOME
# ==============================================================================
{ config, pkgs, lib, ... }:
{
  # =============================================================================
  # Systemd Service Configuration
  # =============================================================================
  systemd.user.services.touchegg = {
    Unit = {
      Description = "Touchégg Daemon (User)";
      After = [ "graphical-session-pre.target" "dbus.service" ];
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
        "XDG_SESSION_TYPE=wayland"
        "XDG_CURRENT_DESKTOP=GNOME"
        "WAYLAND_DISPLAY=wayland-0"
      ];
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # =============================================================================
  # Gesture Configuration for GNOME
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
        # Application-wide Gestures for GNOME
        # ---------------------------------------------------------------------------
        <application name="All">
          # Three Finger Gestures - Browser & Navigation
          <gesture type="SWIPE" fingers="3" direction="RIGHT">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>gnome_flow -tn</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="3" direction="LEFT">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>gnome_flow -tp</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="3" direction="UP">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>gnome_flow -wt</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="3" direction="DOWN">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>gnome_flow.sh -vn</command>
              <on>begin</on>
            </action>
          </gesture>

          # Four Finger Gestures - Workspace Management
          <gesture type="SWIPE" fingers="4" direction="UP">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>gnome_flow -wn 1</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="4" direction="DOWN">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>gnome_flow -wn 9</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="4" direction="RIGHT">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>gnome_flow -wr</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="4" direction="LEFT">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>gnome_flow -wl</command>
              <on>begin</on>
            </action>
          </gesture>

          # Five Finger Gestures - Special Actions  
          <gesture type="SWIPE" fingers="5" direction="UP">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>gnome_flow -wn 5</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="5" direction="DOWN">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval 'Main.overview.toggle()'</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="5" direction="LEFT">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>gnome_flow -wn 2</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="5" direction="RIGHT">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>gnome_flow -wn 8</command>
              <on>begin</on>
            </action>
          </gesture>

          # Pinch Gestures - Window & App Management
          <gesture type="PINCH" fingers="4" direction="IN">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval 'Main.overview.show()'</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="PINCH" fingers="4" direction="OUT">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval 'Main.overview.hide()'</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="PINCH" fingers="3" direction="IN">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>gnome_flow -vp</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="PINCH" fingers="3" direction="OUT">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>gnome_flow -vn</command>
              <on>begin</on>
            </action>
          </gesture>
        </application>

        # ---------------------------------------------------------------------------
        # Browser-specific Gestures
        # ---------------------------------------------------------------------------
        <application name="firefox,Firefox,brave-browser,Brave-browser,chromium,Chromium,google-chrome,Google-chrome">
          <gesture type="SWIPE" fingers="3" direction="RIGHT">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>gnome_flow -tn</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="3" direction="LEFT">
            <action type="RUN_COMMAND">
              <repeat>false</repeat>
              <command>gnome_flow -tp</command>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="2" direction="RIGHT">
            <action type="SEND_KEYS">
              <repeat>false</repeat>
              <keys>Alt+Right</keys>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="2" direction="LEFT">
            <action type="SEND_KEYS">
              <repeat>false</repeat>
              <keys>Alt+Left</keys>
              <on>begin</on>
            </action>
          </gesture>
        </application>

        # ---------------------------------------------------------------------------
        # Terminal-specific Gestures
        # ---------------------------------------------------------------------------
        <application name="gnome-terminal,kitty,alacritty,wezterm">
          <gesture type="SWIPE" fingers="3" direction="UP">
            <action type="SEND_KEYS">
              <repeat>false</repeat>
              <keys>Ctrl+Shift+T</keys>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="3" direction="DOWN">
            <action type="SEND_KEYS">
              <repeat>false</repeat>
              <keys>Ctrl+Shift+W</keys>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="3" direction="RIGHT">
            <action type="SEND_KEYS">
              <repeat>false</repeat>
              <keys>Ctrl+Page_Down</keys>
              <on>begin</on>
            </action>
          </gesture>

          <gesture type="SWIPE" fingers="3" direction="LEFT">
            <action type="SEND_KEYS">
              <repeat>false</repeat>
              <keys>Ctrl+Page_Up</keys>
              <on>begin</on>
            </action>
          </gesture>
        </application>
      </touchégg>
    '';
    executable = true;
  };

  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = with pkgs; [
    touchegg
  ];
}

