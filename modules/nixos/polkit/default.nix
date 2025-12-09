# modules/nixos/polkit/default.nix
# ==============================================================================
# NixOS module for polkit (system-wide stack).
# Provides host defaults and service toggles declared in this file.
# Keeps machine-wide settings centralized under modules/nixos.
# Extend or override options here instead of ad-hoc host tweaks.
# ==============================================================================

{ ... }: { security.polkit.enable = true; }
