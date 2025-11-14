# modules/home/hyprland/hyprland.nix
# ==============================================================================
# Hyprland Main Configuration
# ==============================================================================
{ inputs, pkgs, ... }:
{
  # =============================================================================
  # Required Packages
  # =============================================================================
  home.packages = with pkgs; [
    # ---------------------------------------------------------------------------
    # Core Utilities
    # ---------------------------------------------------------------------------
    swww               # Dynamic wallpaper tool
    hyprpicker         # Color picker
    grim               # Screenshot utility
    slurp              # Screen area selector
    glib               # GLib utilities
    wayland            # Wayland core
    direnv             # Environment manager

    # ---------------------------------------------------------------------------
    # Screenshot and Recording
    # ---------------------------------------------------------------------------
    inputs.hypr-contrib.packages.${pkgs.stdenv.hostPlatform.system}.grimblast # Enhanced screenshot
    wf-recorder        # Screen recorder

    # ---------------------------------------------------------------------------
    # Enhancement Tools
    # ---------------------------------------------------------------------------
    #inputs.hyprmag.packages.${pkgs.stdenv.hostPlatform.system}.hyprmag # Screen magnifier
    wl-clip-persist    # Clipboard manager
    cliphist           # Clipboard history
  ];

  # =============================================================================
  # Systemd Integration
  # =============================================================================
  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];

  # =============================================================================
  # Window Manager Configuration
  # =============================================================================
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland = {
      enable = true;
      #hidpi = true;
    };
    systemd.enable = true;
  };
}
