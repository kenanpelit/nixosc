# modules/core/powersave/default.nix
# ==============================================================================
# Network Power Save Configuration
# ==============================================================================
# This configuration manages power saving features including:
# - WiFi power management
# - Power save notifications
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, ... }:
{
  systemd.user.services.wifi-power-save-notify = {
    description = "Notify WiFi power save status";
    after = [ "graphical-session.target" "disable-wifi-power-save.service" ];
    bindsTo = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    
    environment = {
      WAYLAND_DISPLAY = "wayland-1";
      XDG_RUNTIME_DIR = "/run/user/1000";
      DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
    };
    
    path = [ pkgs.networkmanager pkgs.gawk pkgs.libnotify ];
    
    script = ''
      interface=$(nmcli -t -f DEVICE device status | grep "^wlan" | head -n1)
      if [ -n "$interface" ]; then
        notify-send -t 10000 "Wi-Fi Güç Tasarrufu" "$interface için güç tasarrufu kapatıldı."
      fi
    '';
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
  };
  
  systemd.services.disable-wifi-power-save = {
    description = "Disable WiFi power save";
    after = [ "NetworkManager.service" ];
    requires = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.networkmanager pkgs.gawk ];
    
    script = ''
      for interface in $(nmcli -t -f DEVICE device status | grep "^wlan")
      do
        nmcli connection modify type wifi wifi.powersave 2 || \
        nmcli radio wifi off && nmcli radio wifi on
      done
    '';
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
      User = "root";
    };
  };
}

