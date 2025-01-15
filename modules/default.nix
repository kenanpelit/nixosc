# ==============================================================================
# Core - Home System Configuration
# Author: Kenan Pelit
# Description: Main imports for core system configuration
# ==============================================================================

{ inputs, nixpkgs, self, username, host, lib, ... }:
{
  imports = [
    ./core          # core
    ./home          # home
  ];
}
