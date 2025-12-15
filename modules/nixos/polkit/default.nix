# modules/nixos/polkit/default.nix
# ==============================================================================
# NixOS Polkit rules and agent defaults for system-wide authorization.
# Define privilege prompts and policies centrally for all desktops.
# Adjust rules here to avoid scattered polkit snippets per host.
# ==============================================================================

{ ... }: { security.polkit.enable = true; }
