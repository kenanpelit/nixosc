final: prev: {
  # Allow the GNOME portal backend to be used under Niri.
  #
  # Niri implements the relevant Mutter D-Bus APIs (e.g. org.gnome.Mutter.ScreenCast),
  # but upstream `gnome.portal` is limited to `UseIn=gnome`, so xdg-desktop-portal
  # ignores it in `XDG_CURRENT_DESKTOP=niri` sessions.
  xdg-desktop-portal-gnome = prev.xdg-desktop-portal-gnome.overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + ''
        portal="$out/share/xdg-desktop-portal/portals/gnome.portal"
        if [[ -f "$portal" ]]; then
          substituteInPlace "$portal" \
            --replace 'UseIn=gnome' 'UseIn=gnome;niri' \
            || true
        fi
      '';
  });

  # Optional: allow gnome-keyring portal under Niri (Secret portal).
  gnome-keyring = prev.gnome-keyring.overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + ''
        portal="$out/share/xdg-desktop-portal/portals/gnome-keyring.portal"
        if [[ -f "$portal" ]]; then
          substituteInPlace "$portal" \
            --replace 'UseIn=gnome' 'UseIn=gnome;niri' \
            || true
        fi
      '';
  });
}

