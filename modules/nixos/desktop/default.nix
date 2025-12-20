# modules/nixos/desktop/default.nix
# ==============================================================================
# NixOS desktop glue: themes, portals, session defaults shared across WMs/DEs.
# Keep cross-desktop settings here for consistent look-and-feel.
# Modify global desktop policy here instead of per-session tweaks.
#
# NOTE:
# - Do NOT set GDK_BACKEND globally; it can break the screencast portal.
# - "dbus.packages = [ gcr gnome-keyring ]" only installs D-Bus service files.
#   It does NOT guarantee gnome-keyring is actually started.
# - Enabling gnome-keyring here makes Secret Service (and related integration)
#   consistent across compositors like niri/hyprland.
# ==============================================================================

{ pkgs, lib, config, ... }:

let
  isVirtualHost = config.my.host.isVirtualHost;
in
{
  services = {
    gvfs.enable = true;
    fstrim.enable = true;

    dbus = {
      enable = true;

      # Provide D-Bus services for Secret Service / keyring prompts (gcr),
      # and gnome-keyring D-Bus activation files.
      packages = with pkgs; [ gcr gnome-keyring ];
    };

    # Start gnome-keyring (Secret Service / PKCS#11 / optional SSH agent socket).
    # Without this, apps may fall back to gcr-prompter popups later in the session.
    gnome.gnome-keyring.enable = true;

    blueman.enable = true;
    touchegg.enable = false;
    tumbler.enable = true;
    fwupd.enable = true;

    spice-vdagentd.enable = lib.mkDefault false;
    printing.enable = false;

    avahi = {
      enable = false;
      nssmdns4 = false;
    };

    # Keep speech-dispatcher fully disabled system-wide.
    speechd.enable = lib.mkForce false;
  };

  # Hard-disable speech dispatcher units/sockets at user level as well.
  systemd.user.services.speech-dispatcher = {
    enable = false;
    unitConfig.ConditionPathExists = "!/dev/null";
  };
  systemd.user.sockets.speech-dispatcher = {
    enable = false;
    unitConfig.ConditionPathExists = "!/dev/null";
  };

  environment.sessionVariables = {
    # Avoid GTK a11y bridge overhead/noise (common desktop hardening/perf tweak).
    GTK_A11Y = "none";
    NO_AT_BRIDGE = "1";

    # Make SSH use the keyring-managed agent socket (stable for Wayland sessions).
    # This reduces repeated "enter passphrase" prompts caused by changing agents/sockets.
    SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/keyring/ssh";
  };
}
