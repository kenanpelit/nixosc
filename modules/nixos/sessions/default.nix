# modules/nixos/sessions/default.nix
# ==============================================================================
# NixOS session definitions for DE/WM entries and login sessions.
# Register available sessions centrally for all display managers.
# Keep session metadata consistent by editing this file.
# ==============================================================================

{ pkgs, lib, inputs, config, ... }:

let
  username = config.my.user.name or "kenan";
  cfg = config.my.display;

  hyprlandPkg =
    inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.default;

  hyprPortalPkg =
    inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

  hyprlandOptimizedSession = pkgs.writeTextFile {
    name = "hyprland-optimized-session";
    destination = "/share/wayland-sessions/hyprland-optimized.desktop";
    text = ''
      [Desktop Entry]
      Name=Hyprland (Optimized)
      Comment=Hyprland with pinned flake build and user-session integration

      Type=Application
      DesktopNames=Hyprland
      X-GDM-SessionType=wayland
      X-Session-Type=wayland

      Exec=/etc/profiles/per-user/${username}/bin/hyprland_tty

      Keywords=wayland;wm;tiling;hyprland;compositor;
    '';
    passthru.providedSessions = [ "hyprland-optimized" ];
  };

  gnomeSessionWrapper = pkgs.writeTextFile {
    name = "gnome-session-wrapper";
    destination = "/share/wayland-sessions/gnome-nixos.desktop";
    text = ''
      [Desktop Entry]
      Name=GNOME (NixOS)
      Comment=GNOME with systemd user session support and custom launcher

      Type=Application
      DesktopNames=GNOME
      X-GDM-SessionType=wayland
      X-Session-Type=wayland
      X-GDM-SessionRegisters=true
      X-GDM-CanRunHeadless=true

      Exec=/etc/profiles/per-user/${username}/bin/gnome_tty
    '';
    passthru.providedSessions = [ "gnome-nixos" ];
  };

  niriSession = pkgs.writeTextFile {
    name = "niri-session";
    destination = "/share/wayland-sessions/niri.desktop";
    text = ''
      [Desktop Entry]
      Name=Niri (Wayland)
      Comment=Scrollable tiling Wayland compositor

      Type=Application
      DesktopNames=Niri
      X-GDM-SessionType=wayland
      X-Session-Type=wayland

      Exec=${pkgs.niri}/bin/niri

      Keywords=wayland;wm;tiling;niri;compositor;
    '';
    passthru.providedSessions = [ "niri" ];
  };
in
{
  config = lib.mkIf cfg.enable {
    # Session definitions for DM
    services.displayManager.sessionPackages = lib.mkMerge [
      (lib.optional cfg.enableHyprland hyprlandOptimizedSession)
      (lib.optional cfg.enableGnome gnomeSessionWrapper)
      (lib.optional cfg.enableNiri niriSession)
    ];

    # Packages needed for sessions/portals
    environment.systemPackages = lib.mkMerge [
      (lib.optional cfg.enableHyprland hyprlandPkg)
      (lib.optional cfg.enableHyprland hyprPortalPkg)
      (lib.optional cfg.enableNiri pkgs.niri)
    ];
  };
}
