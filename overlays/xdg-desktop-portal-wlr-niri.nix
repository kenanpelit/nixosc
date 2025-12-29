final: prev: {
  # xdg-desktop-portal discovers implementations via *.portal files and filters
  # them by `UseIn=$XDG_CURRENT_DESKTOP`. Upstream `wlr.portal` doesn't include
  # `niri`, so ScreenCast/Screenshot backends may not be considered under niri
  # sessions (browsers fall back to tab-only sharing).
  xdg-desktop-portal-wlr = prev.xdg-desktop-portal-wlr.overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + ''
        portal="$out/share/xdg-desktop-portal/portals/wlr.portal"
        if [[ -f "$portal" ]]; then
          substituteInPlace "$portal" \
            --replace 'UseIn=wlroots;' 'UseIn=wlroots;niri;' \
            || true
        fi
      '';
  });
}
