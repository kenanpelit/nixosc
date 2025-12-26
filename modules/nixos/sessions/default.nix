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

  niriPkg = pkgs.niri-unstable;
  mangoPkg = inputs.mango.packages.${pkgs.stdenv.hostPlatform.system}.mango;
  cosmicSessionPkg = pkgs."cosmic-session" or null;
  cosmicEnabled = cfg.enableCosmic or false;
  cosmicAvailable = cosmicSessionPkg != null;

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

      Exec=/etc/profiles/per-user/${username}/bin/hypr-set tty

      Keywords=wayland;wm;tiling;hyprland;compositor;
    '';
    passthru.providedSessions = [ "hyprland-optimized" ];
  };

  gnomeSessionWrapper = pkgs.writeTextFile {
    name = "gnome-session-wrapper";
    destination = "/share/wayland-sessions/gnome-optimized.desktop";
    text = ''
      [Desktop Entry]
      Name=GNOME (Optimized)
      Comment=GNOME with systemd user session support and custom launcher (gnome_tty)

      Type=Application
      DesktopNames=GNOME
      X-GDM-SessionType=wayland
      X-Session-Type=wayland
      X-GDM-SessionRegisters=true
      X-GDM-CanRunHeadless=true

      Exec=/etc/profiles/per-user/${username}/bin/gnome_tty
    '';
    passthru.providedSessions = [ "gnome-optimized" ];
  };

  niriSession = pkgs.writeTextFile {
    name = "niri-session";
    # Avoid clobbering Niri's upstream `niri.desktop` (Exec=niri-session),
    # otherwise greeters will only see the upstream entry and our optimized one
    # disappears from the menu.
    destination = "/share/wayland-sessions/niri-optimized.desktop";
    text = ''
      [Desktop Entry]
      Name=Niri (Optimized)
      Comment=Scrollable-tiling Wayland compositor (via niri-set tty)
      Exec=/etc/profiles/per-user/${username}/bin/niri-set tty
      Type=Application
      DesktopNames=niri
    '';
    passthru.providedSessions = [ "niri-optimized" ];
  };

  mangoSession = pkgs.writeTextFile {
    name = "mango-session";
    # Avoid clobbering MangoWC's upstream `mango.desktop`.
    destination = "/share/wayland-sessions/mango-optimized.desktop";
    text = ''
      [Desktop Entry]
      Name=Mango (Optimized)
      Comment=dwl-based Wayland compositor (via mango-set tty)
      Exec=/etc/profiles/per-user/${username}/bin/mango-set tty
      Type=Application
      DesktopNames=mango
      X-GDM-SessionType=wayland
      X-Session-Type=wayland
    '';
    passthru.providedSessions = [ "mango-optimized" ];
  };

  cosmicSession = pkgs.writeTextFile {
    name = "cosmic-session";
    # Avoid clobbering COSMIC's upstream `cosmic.desktop` if/when it exists.
    destination = "/share/wayland-sessions/cosmic-optimized.desktop";
    text = ''
      [Desktop Entry]
      Name=COSMIC (Optimized)
      Comment=COSMIC desktop environment (Epoch)
      Exec=${lib.getExe' cosmicSessionPkg "cosmic-session"}
      Type=Application
      DesktopNames=COSMIC
      X-GDM-SessionType=wayland
      X-Session-Type=wayland
    '';
    passthru.providedSessions = [ "cosmic-optimized" ];
  };

in
{
  config = lib.mkIf cfg.enable {
    programs.mango = lib.mkIf (cfg.enableMangowc or false) {
      enable = true;
      package = mangoPkg;
    };

    assertions = [
      {
        assertion = (!cosmicEnabled) || cosmicAvailable;
        message = "my.display.enableCosmic is enabled, but `pkgs.cosmic-session` is missing from nixpkgs.";
      }
    ];

    # GNOME Shell (mutter) started via `org.gnome.Shell@wayland.service` expects
    # the current logind session to be a *graphical* session (Type=wayland/x11).
    # TTY logins default to Type=tty, which makes GNOME fail with:
    #   "Failed to setup: Failed to find any matching session"
    #
    # Force pam_systemd to register `login` sessions as wayland so GNOME can be
    # started directly from a TTY (tty3) without GDM.
    #
    # NOTE: This uses the (experimental) `security.pam.services.<name>.rules`
    # interface, but it is the least invasive way to pass pam_systemd arguments.
    security.pam.services.login.rules.session.systemd.settings.type = lib.mkDefault "wayland";

    # Session definitions for DM
    services.displayManager.sessionPackages = lib.mkMerge [
      (lib.optional cfg.enableHyprland hyprlandOptimizedSession)
      (lib.optional cfg.enableGnome gnomeSessionWrapper)
      (lib.optional cfg.enableNiri niriSession)
      (lib.optional (cfg.enableMangowc or false) mangoSession)
      (lib.optional (cosmicEnabled && cosmicAvailable) cosmicSession)
    ];

    # Packages needed for sessions/portals
    environment.systemPackages = lib.mkMerge [
      (lib.optional cfg.enableHyprland hyprlandPkg)
      (lib.optional cfg.enableHyprland hyprPortalPkg)
      (lib.optional cfg.enableHyprland hyprlandOptimizedSession)
      
      (lib.optional cfg.enableGnome gnomeSessionWrapper)
      
      (lib.optional cfg.enableNiri niriPkg)
      (lib.optional cfg.enableNiri niriSession)

      (lib.optional (cfg.enableMangowc or false) mangoPkg)
      (lib.optional (cfg.enableMangowc or false) mangoSession)

      (lib.optional (cosmicEnabled && cosmicAvailable) cosmicSessionPkg)
      (lib.optional (cosmicEnabled && cosmicAvailable) cosmicSession)
    ];
  };
}
