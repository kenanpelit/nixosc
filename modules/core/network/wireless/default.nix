# modules/core/network/wireless/default.nix
# ==============================================================================
# Wireless Configuration
# ==============================================================================
# This configuration manages wireless network settings including:
# - IWD configuration and settings
# - Network profiles
# - Power management
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
  networking.wireless.iwd = {
    enable = true;
    settings = {
      General = {
        EnableNetworkConfiguration = "true";
        AddressRandomization = "none";
        RoamRetryInterval = "15";
        DisableANQP = "true";
        MacAddressRandomization = "vendor";
        RoamThreshold = "-70";
        RoamThresholdSet = "true";
      };

      Network = {
        EnableIPv6 = "false";
        NameResolvingService = "systemd";
        RoutePriorityOffset = "300";
        PowerSave = "false";
        EnableAutoConnect = "true";
      };

      # Network Profiles
      "Network.Ken_5" = {
        Address = "192.168.1.100/24";
        Gateway = "192.168.1.1";
        DNS = "1.1.1.1";
        AutoConnect = "true";
        Hidden = "false";
        PowerSave = "false";
      };

      "Network.Ken_2_4" = {
        Address = "192.168.1.101/24";
        Gateway = "192.168.1.1";
        DNS = "1.1.1.1";
        AutoConnect = "true";
        Hidden = "false";
        PowerSave = "false";
      };
    };
  };
}
