# modules/home/niri/rules.nix
# ==============================================================================
# Niri Window Rules - Modular Configuration
#
# Contains logic for window placement, floating rules, sizing, and specific
# application behaviors (e.g., PiP, dialogs).
# Imported by default.nix
# ==============================================================================
{ lib, config, ... }:
let
  cfg = config.my.desktop.niri;

  # ----------------------------------------------------------------------------
  # Window Rule Helpers
  # ----------------------------------------------------------------------------
  mkFixedFloating = 
    { w, h, x ? null, y ? null, relativeTo ? "top-right", opacity ? null, focus ? true }:
    ''
      open-floating true;
      default-column-width { fixed ${toString w}; }
      default-window-height { fixed ${toString h}; }
      ${lib.optionalString (x != null && y != null)
        ''default-floating-position x=${toString x} y=${toString y} relative-to="${relativeTo}";''}
      min-width ${toString w};
      max-width ${toString w};
      min-height ${toString h};
      max-height ${toString h};
      ${lib.optionalString (opacity != null) "opacity ${toString opacity};"}
      ${lib.optionalString focus "open-focused true;"}
    '';

  mkProportionalFloating = 
    { w, h, x ? null, y ? null, relativeTo ? "top-right", focus ? true }:
    ''
      open-floating true;
      default-column-width { proportion ${toString w}; }
      default-window-height { proportion ${toString h}; }
      ${lib.optionalString (x != null && y != null)
        ''default-floating-position x=${toString x} y=${toString y} relative-to="${relativeTo}";''}
      ${lib.optionalString focus "open-focused true;"}
    '';

  renderMatchAppIds = appIdRegexes:
    lib.concatStringsSep "\n" (map (r: ''      match app-id=r#"${r}"#;'' ) appIdRegexes);

  privacyScreencastAppIds = [
    "^org\\.keepassxc\\.KeePassXC$"
    "^org\\.gnome\\.World\\.Secrets$"
    "^com\\.bitwarden\\.desktop$"
    "^io\\.ente\\.auth$"
    "^clipse$"
    "^gcr-prompter$"
    "^polkit-gnome-authentication-agent-1$"
    "^(nm-connection-editor|blueman-manager)$"
    "^(discord|WebCord|ferdium|com\\.rtosta\\.zapzap|org\\.telegram\\.desktop|Signal|Slack|whatsapp-for-linux)$"
  ];

  privacyScreenCaptureAppIds = [
    "^org\\.keepassxc\\.KeePassXC$"
    "^org\\.gnome\\.World\\.Secrets$"
    "^com\\.bitwarden\\.desktop$"
    "^io\\.ente\\.auth$"
    "^clipse$"
    "^gcr-prompter$"
    "^polkit-gnome-authentication-agent-1$"
  ];

  # ----------------------------------------------------------------------------
  # Workspace assignment rules for daily apps
  # ----------------------------------------------------------------------------
  workspaceRules = [
    { appId = "^discord$"; workspace = "5"; maximize = true; }
    { appId = "^WebCord$"; workspace = "5"; maximize = true; }
    { appId = "^(spotify|Spotify|com\.spotify\.Client)$"; workspace = "8"; }
    { appId = "^audacious$"; workspace = "5"; }
    { appId = "^transmission$"; workspace = "7"; }
    { appId = "^org\.keepassxc\.KeePassXC$"; workspace = "7"; }
    { appId = "^Kenp$"; workspace = "1"; maximize = true; }
    { appId = "^Ai$"; workspace = "3"; maximize = true; }
    { appId = "^CompecTA$"; workspace = "4"; maximize = true; }
    { appId = "^brave-youtube\.com__-Default$"; workspace = "7"; maximize = true; }
    { appId = "^ferdium$"; workspace = "9"; maximize = true; }
    { appId = "^com\.rtosta\.zapzap$"; workspace = "9"; maximize = true; }
    { appId = "^org\.telegram\.desktop$"; workspace = "6"; maximize = true; }
    { appId = "^vlc$"; workspace = "6"; }
    { appId = "^remote-viewer$"; workspace = "6"; maximize = true; }
  ];

  # Rules for the "arrange windows" helper script.
  arrangeRules =
    [
      # Terminal / session anchor
      { appId = "^(TmuxKenp|Tmux)$"; workspace = "2"; }
      { appId = "^(kitty|org\\.wezfurlong\\.wezterm)$"; title = "^Tmux$"; workspace = "2"; }
    ]
    ++ workspaceRules;

  renderWorkspaceRules = lib.concatStringsSep "\n" (
    map (r: ''
      window-rule {
        match app-id=r#"${r.appId}"#;
        open-on-workspace "${r.workspace}";
        ${lib.optionalString (r.maximize or false) "open-maximized true; open-maximized-to-edges true;"}
      }
    '') workspaceRules
  );

in
{
  arrangeRulesTsv =
    lib.concatStringsSep "\n" (map (r: "${r.appId}\t${r.workspace}\t${r.title or ""}") arrangeRules)
    + "\n";

  rules = ''
    // ========================================================================
    // Window Rules
    // ========================================================================

    // Global Styling
    window-rule {
      geometry-corner-radius 12;
      clip-to-geometry true;
    }

    // Auto-Sizing: Browsers (Wider)
    window-rule {
      match app-id=r#"^(firefox|brave-browser|chrome|chromium)$"#;
      default-column-width { proportion 0.6; }
    }

    // Auto-Sizing: Chat & Social (Narrow)
    window-rule {
      match app-id=r#"^(discord|WebCord|org\.telegram\.desktop|Slack|Signal|whatsapp-for-linux)$"#;
      default-column-width { proportion 0.33333; }
    }

    // Auto-Sizing: Terminals & Code (Half Split)
    window-rule {
      match app-id=r#"^(kitty|Alacritty|code|vscode|org\.wezfurlong\.wezterm)$"#;
      default-column-width { proportion 0.5; }
    }

    // Floating Windows
    window-rule {
      match is-floating=true;
      shadow { on; }
    }

    // Tiling Windows
    window-rule {
      match is-floating=false;
      shadow {
        on;
        color "#00000060";
        offset x=0 y=4;
        spread 0;
        softness 16;
      }
    }

    // QuickShell
    window-rule {
      match app-id=r#"^org\.quickshell$"#;
      open-floating true;
    }

    // Variable Refresh Rate
    window-rule {
      match app-id=r#"^mpv$"#;
      variable-refresh-rate true;
    }

    ${lib.optionalString cfg.enableGamingVrrRules ''
    // Variable Refresh Rate - Gaming (optional)
    window-rule {
      match app-id=r#"^(gamescope|steam|steamwebhelper)$"#;
      variable-refresh-rate true;
    }
    ''}

    // Picture-in-Picture
    window-rule {
      match title=r#"(?i)^picture[- ]in[- ]picture$"#;
      ${mkFixedFloating { w = 640; h = 360; x = 32; y = 96; opacity = "1.0"; }}
    }

    // MPV (non-PiP)
    window-rule {
      match app-id=r#"^mpv$"#;
      exclude title=r#"^Picture-in-Picture( - mpv)?$"#;
      ${mkFixedFloating { w = 640; h = 360; x = 32; y = 96; opacity = "1.0"; }}
    }

    // MPV (PiP)
    window-rule {
      match app-id=r#"^mpv$"# title=r#"^Picture-in-Picture( - mpv)?$"#;
      ${mkFixedFloating { w = 640; h = 360; x = 32; y = 96; opacity = "1.0"; }}
    }

    // Common dialogs / utilities
    window-rule {
      match title="^Open File$";
      match title="^File Upload$";
      match title="^Save As$";
      match title="^Confirm to replace files$";
      match title="^File Operation Progress$";
      match app-id=r#"^pavucontrol$"#;
      match app-id=r#"^nm-connection-editor$"#;
      match app-id=r#"^blueman-manager$"#;
      match app-id=r#"^polkit-gnome-authentication-agent-1$"#;
      match app-id=r#"^hyprland-share-picker$"#;
      open-floating true;
    }

    // Tmux
    window-rule {
      match app-id=r#"^(TmuxKenp|Tmux)$"#;
      match app-id=r#"^(kitty|org\.wezfurlong\.wezterm)$"# title=r#"^Tmux$"#;
      open-on-workspace "2";
      open-maximized true;
      open-maximized-to-edges true;
      open-focused true;
    }

    // Audio Mixer
    window-rule {
      match app-id=r#"^org\.pulseaudio\.pavucontrol$"#;
      ${mkProportionalFloating { w = 0.25; h = 0.80; x = 32; y = 144; }}
    }

    // Clipboard Manager
    window-rule {
      match app-id=r#"^clipse$"#;
      ${mkProportionalFloating { w = 0.25; h = 0.80; x = 32; y = 144; }}
    }

    // Ente Auth (2FA)
    // Keep it floating like Clipse, but do not force a workspace.
    window-rule {
      match app-id=r#"^io\.ente\.auth$"#;
      ${mkProportionalFloating { w = 0.25; h = 0.80; x = 32; y = 144; }}
    }

    // Notes
    window-rule {
      match app-id=r#"^anote$"#;
      ${mkFixedFloating { w = 1152; h = 864; }}
    }

    // Keyring / password prompt
    window-rule {
      match app-id=r#"^gcr-prompter$"#;
      ${mkFixedFloating { w = 600; h = 230; x = 0; y = 96; relativeTo = "top"; }}
    }

    // Workspace Assignments
    ${renderWorkspaceRules}

    // Better dialog placement
    window-rule {
      match app-id=r#"^(blueman-manager|nm-connection-editor)$"#;
      open-floating true;
      default-column-width { fixed 900; }
      default-window-height { fixed 650; }
      open-focused true;
    }

    window-rule {
      match app-id=r#"^polkit-gnome-authentication-agent-1$"#;
      open-floating true;
      default-column-width { fixed 520; }
      default-window-height { fixed 240; }
      open-focused true;
    }

    window-rule {
      match title=r#"^(Open File|File Upload|Save As|Confirm to replace files|File Operation Progress)$"#;
      open-floating true;
      default-column-width { proportion 0.60; }
      default-window-height { proportion 0.75; }
      open-focused true;
    }

    // Privacy - block from screencast (xdg-desktop-portal / screen sharing)
    window-rule {
${renderMatchAppIds privacyScreencastAppIds}
      block-out-from "screencast";
    }

    // Privacy - block from *all* screen captures (screenshots + screencasts)
    // Note: interactive built-in screenshot UI still works; only "automatic" capture is blocked.
    window-rule {
${renderMatchAppIds privacyScreenCaptureAppIds}
      block-out-from "screen-capture";
    }

    // Screencast indicator (dynamic cast / window cast target)
    window-rule {
      match is-window-cast-target=true;

      focus-ring {
        active-color "#f38ba8";
        inactive-color "#7d0d2d";
      }

      border {
        inactive-color "#7d0d2d";
      }

      shadow {
        color "#7d0d2d70";
      }

      tab-indicator {
        active-color "#f38ba8";
        inactive-color "#7d0d2d";
      }
    }

    // Borderless apps
    window-rule {
      match app-id=r#"^(org\.gnome\..*|org\.wezfurlong\.wezterm|zen|com\.mitchellh\.ghostty|kitty|firefox|brave-browser)$"#;
      draw-border-with-background false;
    }

    window-rule {
      match app-id=r#"^(Kenp|Ai|CompecTA|Whats|Exclude|brave-youtube\.com__-Default|ferdium)$"#;
      draw-border-with-background false;
    }

    // Inactive dimming
    window-rule {
      match is-active=false;
      exclude app-id=r#"^mpv$"#;
      exclude app-id=r#"^vlc$"#;
      exclude app-id=r#"^brave-youtube\.com__-Default$"#;
      exclude title=r#"^Picture-in-Picture$"#;
      exclude app-id=r#"^steam_app_\d+$"#;
      exclude app-id=r#"^com\.obsproject\.Studio$"#;
      opacity 0.85;
    }

    // ========================================================================
    // Layer Rules
    // ========================================================================
    
    // DMS: Wallpaper Blur
    layer-rule {
      match namespace=r#"^dms:blurwallpaper$"#;
      place-within-backdrop true;
    }

    // DMS: UI Elements (Bar, Dock, Panel)
    layer-rule {
      match namespace=r#"^dms:(bar|dock|panel).*$"#;
      geometry-corner-radius 0;
    }

    // DMS: Overlays (Launcher, OSD, Popups) - Add shadows for depth
    layer-rule {
      match namespace=r#"^dms:(launcher|osd|popup).*$"#;
      shadow {
        on;
        color "#00000060";
        spread 2;
        softness 12;
      }
    }

    // Notifications: Layout
    layer-rule {
      match namespace="^notifications$";
      geometry-corner-radius 12;
    }

    // Notifications: Privacy
    layer-rule {
      match namespace="^notifications$";
      block-out-from "screencast";
    }

    layer-rule {
      match namespace="^notifications$";
      block-out-from "screen-capture";
    }
  '';
}
