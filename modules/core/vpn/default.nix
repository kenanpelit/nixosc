# modules/core/vpn/default.nix
# ==============================================================================
# VPN Configuration
# ==============================================================================
# This configuration manages VPN settings including:
# - Mullvad VPN setup
# - VPN package management
#
# Author: Kenan Pelit
# ==============================================================================

{ pkgs, ... }:
{
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  environment.systemPackages = with pkgs; [
    mullvad-vpn
  ];
}
