final: prev: {
  # Allow the GNOME portal backend to be used under Niri, but only for the
  # interfaces we actually want (ScreenCast/Screenshot/RemoteDesktop).
  #
  # `xdg-desktop-portal-gnome` also implements `GlobalShortcuts` and will spawn
  # `org.gnome.Settings.GlobalShortcutsProvider` UI when apps (e.g. Chromium/Brave)
  # probe it. To avoid that, we keep upstream `gnome.portal` (GNOME-only), and
  # ship a dedicated `gnome-niri.portal` which advertises only the screencast/
  # screenshot interfaces for `UseIn=niri`.
  xdg-desktop-portal-gnome = prev.xdg-desktop-portal-gnome.overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + ''
        portal="$out/share/xdg-desktop-portal/portals/gnome.portal"
        if [[ -f "$portal" ]]; then
          # Make sure we don't enable the full GNOME portal in Niri sessions.
          substituteInPlace "$portal" \
            --replace 'UseIn=gnome;niri' 'UseIn=gnome' \
            || true
        fi

        cat >"$out/share/xdg-desktop-portal/portals/gnome-niri.portal" <<'EOF'
[portal]
DBusName=org.freedesktop.impl.portal.desktop.gnome
Interfaces=org.freedesktop.impl.portal.RemoteDesktop;org.freedesktop.impl.portal.ScreenCast;org.freedesktop.impl.portal.Screenshot;
UseIn=niri
EOF
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
