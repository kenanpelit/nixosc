final: prev: {
  # Niri ships a default `niri-portals.conf` which prefers `gnome;gtk` but does
  # not map ScreenCast/Screenshot. Under a non-GNOME session this can lead to
  # xdg-desktop-portal falling back to gtk only (tab-only sharing in browsers).
  #
  # We patch the shipped config so that even if this file is picked up, niri
  # sessions still get working ScreenCast/Screenshot via the wlroots portal.
  niri-unstable = prev.niri-unstable.overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + ''
        portal="$out/share/xdg-desktop-portal/niri-portals.conf"
        if [[ -f "$portal" ]]; then
          cat >"$portal" <<'EOF'
[preferred]
default=gtk
org.freedesktop.impl.portal.ScreenCast=wlr
org.freedesktop.impl.portal.Screenshot=wlr
EOF
        fi
      '';
  });
}

