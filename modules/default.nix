# ==============================================================================
# Core - Home System Configuration
# Author: kenanpelit
# Description: Main imports for core system configuration
# ==============================================================================

{ inputs, nixpkgs, self, username, host, lib, ... }:
{
  imports = [
    ./core          # core
    ./home          # home
  ];
}
