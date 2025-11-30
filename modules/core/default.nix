# modules/core/default.nix
# Ordered imports matching one-dir-per-topic layout under modules/core.
# Layers: account → system → nix/packages → display → networking → security → sops → services

{ inputs, nixpkgs, self, username, host, lib, ... }:

{
  imports = [
    ./boot
    ./account
    ./system
    ./hardware
    ./power
    ./logind
    ./nix
    ./packages
    ./display
    ./dm
    ./sessions
    ./portals
    ./audio
    ./fonts
    ./networking
    ./vpn
    ./tcp
    ./dns
    ./firewall
    ./polkit
    ./apparmor
    ./audit
    ./hblock
    ./fail2ban
    ./sops
    ./desktop
    ./flatpak
    ./gaming
    ./containers
    ./virtualization
  ];
}
