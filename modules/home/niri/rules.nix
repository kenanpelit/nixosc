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
      ${lib.optionalString (opacity != null) "opacity ${toString opacity};
"}
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

  # ----------------------------------------------------------------------------
  # Privacy Lists
  # ----------------------------------------------------------------------------
  # Apps that should never be captured (passwords, auth, secrets)
  commonPrivacyAppIds = [
    "^org\.keepassxc\.KeePassXC$"
    "^org\.gnome\.World\.Secrets$"
    "^com\.bitwarden\.desktop$"
    "^io\.ente\.auth$"
    "^clipse$"
    "^gcr-prompter$"
    "^polkit-gnome-authentication-agent-1$"
  ];

  # Apps that should be hidden from screencasts but aren't strictly secrets (messaging)
  messagingPrivacyAppIds = [
    "^(discord|WebCord|ferdium|com\.rtosta\.zapzap|org\.telegram\.desktop|Signal|Slack|whatsapp-for-linux)$"
    "^(nm-connection-editor|blueman-manager)$"
  ];

  privacyScreenCaptureAppIds = commonPrivacyAppIds;
  privacyScreencastAppIds = commonPrivacyAppIds ++ messagingPrivacyAppIds;

  # ----------------------------------------------------------------------------
  # Workspace Assignments
  # ----------------------------------------------------------------------------
  # Unified list for both Niri window rules and external scripts
  workspaceRules = [
    # Core
    { appId = "^(TmuxKenp|Tmux)$"; workspace = "2"; maximize = true; }
    { appId = "^(kitty|org\.wezfurlong\.wezterm)$"; title = "^Tmux$"; workspace = "2"; maximize = true; }
    
    # Dev / AI
    { appId = "^Kenp$"; workspace = "1"; }
    { appId = "^Ai$"; workspace = "3"; }
    { appId = "^CompecTA$"; workspace = "4"; }
    
    # Social / Media
    { appId = "^discord$"; workspace = "5"; }
    { appId = "^WebCord$"; workspace = "5"; }
    { appId = "^audacious$"; workspace = "5"; }
    { appId = "^org\.telegram\.desktop$"; workspace = "6"; }
    { appId = "^vlc$"; workspace = "6"; }
    { appId = "^remote-viewer$"; workspace = "6"; }
    
    # Web / Tools
    { appId = "^transmission$"; workspace = "7"; }
    { appId = "^org\.keepassxc\.KeePassXC$"; workspace = "7"; }
    { appId = "^brave-youtube\.com__-Default$"; workspace = "7"; }
    { appId = "^(spotify|Spotify|com\.spotify\.Client)$"; workspace = "8"; }
    { appId = "^ferdium$"; workspace = "9"; }
    { appId = "^com\.rtosta\.zapzap$"; workspace = "9"; }
  ];

  # Helper to generate Niri window-rule blocks from the list above
  renderWorkspaceRules = lib.concatStringsSep "\n" (
    map (r: ''
      window-rule {
        match app-id=r#"${r.appId}"##{lib.optionalString (r ? title) '' title=r#"${r.title}"''};
        open-on-workspace "${r.workspace}";
        ${lib.optionalString (r.maximize or false) "open-maximized true; open-maximized-to-edges true;"}
      }
    '') workspaceRules
  );

in
{
  # Export for niri-arrange-windows script (TSV format)
  arrangeRulesTsv = 
    lib.concatStringsSep "\n" (map (r: "${r.appId}\t${r.workspace}\t${r.title or ""}") workspaceRules)
    + "\n";

  rules = ''
    // ========================================================================
    // Niri Window Rules - Generated via Home Manager
    // ========================================================================

    // ------------------------------------------------------------------------
    // Global Behavior
    // ------------------------------------------------------------------------
    window-rule {
      geometry-corner-radius 12;
      clip-to-geometry true;
    }

    // Shadow Logic: Floating gets full shadow, Tiling gets subtle shadow
    window-rule {
      match is-floating=true;
      shadow { on; }
    }
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

    // ------------------------------------------------------------------------
    // Special Windows (Helpers, Overlays, VRR)
    // ------------------------------------------------------------------------
    
    // QuickShell & XWayland Bridge
    window-rule {
      match app-id=r#"^org\.quickshell$"#;
      open-floating true;
    }
    window-rule {
      match app-id="xwaylandvideobridge";
      open-floating true;
      open-focused false;
      opacity 0.0;
      default-column-width { fixed 1; }
      default-window-height { fixed 1; }
    }

    // Empty helper windows (DnD placeholders etc.)
    window-rule {
      match app-id=r#"^$" title=r#"^$"#;
      open-floating true;
      open-focused false;
    }

    // Variable Refresh Rate (Video Players)
    window-rule {
      match app-id=r#"^mpv$" #;
      variable-refresh-rate true;
    }

    ${lib.optionalString cfg.enableGamingVrrRules ''
    // Variable Refresh Rate (Gaming)
    window-rule {
      match app-id=r#"^(gamescope|steam|steamwebhelper)$"#;
      variable-refresh-rate true;
    }
    ''}

    // ------------------------------------------------------------------------
    // Picture-in-Picture & Video Players
    // ------------------------------------------------------------------------
    
    // Generic PiP
    window-rule {
      match title=r#"(?i)^picture[- ]in[- ]picture$"#;
      ${mkFixedFloating { w = 640; h = 360; x = 32; y = 96; opacity = "1.0"; }}
    }

    // MPV Floating Rules
    window-rule {
      match app-id=r#"^mpv$" #;
      exclude title=r#"^Picture-in-Picture( - mpv)?$"#;
      ${mkFixedFloating { w = 640; h = 360; x = 32; y = 96; opacity = "1.0"; }}
    }

    // ------------------------------------------------------------------------
    // Floating Applications & Dialogs
    // ------------------------------------------------------------------------

    // Standard Dialogs (File pickers, confirmations)
    window-rule {
      match title=r#"^(Open File|File Upload|Save As|Confirm to replace files|File Operation Progress|Extract archive|Compress\.\.\.)$"#;
      // Exclude specific apps that might share these titles but should be handled differently if needed
      exclude app-id=r#"^Kenp$" #;
      open-floating true;
      default-column-width { proportion 0.60; }
      default-window-height { proportion 0.75; }
      open-focused true;
    }

    // Specific Sizes: Small Tools
    window-rule {
      match app-id=r#"^org\.gnome\.Calculator$"#;
      match app-id=r#"^kcalc$"#;
      ${mkFixedFloating { w = 400; h = 600; x = 0; y = 100; relativeTo = "top"; }}
    }
    
    window-rule {
      match app-id=r#"^polkit-gnome-authentication-agent-1$"#;
      ${mkFixedFloating { w = 520; h = 240; }}
    }

    window-rule {
      match app-id=r#"^gcr-prompter$"#;
      ${mkFixedFloating { w = 600; h = 230; x = 0; y = 96; relativeTo = "top"; }}
    }

    // Specific Sizes: Medium Tools
    window-rule {
      match app-id=r#"^org\.gnome\.Decibels$"#;
      ${mkFixedFloating { w = 640; h = 360; x = 32; y = 96; opacity = "0.5"; }}
    }
    
    window-rule {
      match app-id=r#"^hyprland-share-picker$"#;
      match app-id=r#"^pavucontrol$" #;  // Fallback if not org.pulseaudio...
      open-floating true;
      open-focused true;
    }

    // Specific Sizes: Large Tools (Settings, Managers)
    window-rule {
      match app-id=r#"^(blueman-manager|nm-connection-editor|org\.gnome\.Settings|gnome-disks)$"#;
      ${mkFixedFloating { w = 900; h = 650; }}
    }

    // Side Panels (Clipse, Audio Mixer, Auth)
    window-rule {
      match app-id=r#"^(clipse|org\.pulseaudio\.pavucontrol|io\.ente\.auth)$"#;
      ${mkProportionalFloating { w = 0.25; h = 0.80; x = 32; y = 144; }}
    }
    
    // Clipboard Preview
    window-rule {
      match app-id=r#"^clip-preview$"#;
      ${mkFixedFloating { w = 900; h = 700; opacity = "0.98"; }}
      shadow { on; spread 5; softness 30; }
    }

    // Notes App
    window-rule {
      match app-id=r#"^anote$"#;
      ${mkFixedFloating { w = 1152; h = 864; }}
    }

    // Dropdown Terminal
    window-rule {
      match app-id="dropdown-terminal";
      open-floating true;
      default-column-width { proportion 0.8; }
      default-window-height { fixed 600; }
      default-floating-position x=0 y=20 relative-to="top";
      border { off; }
      shadow { on; spread 10; softness 40; color "#00000080"; }
    }
    
    // Kenp Save File Rule
    window-rule {
      match app-id=r#"^Kenp$" title=r#"^Save File$"#;
      default-column-width { fixed 1280; }
      default-window-height { fixed 933; }
      open-floating true;
    }

    // ------------------------------------------------------------------------
    // Workspace Rules (Generated)
    // ------------------------------------------------------------------------
    ${renderWorkspaceRules}

    // ------------------------------------------------------------------------
    // Privacy & Security
    // ------------------------------------------------------------------------
    // Block from screencast (Window capture will show black/empty)
    window-rule {
${renderMatchAppIds privacyScreencastAppIds}
      block-out-from "screencast";
    }

    // Block from ALL capture (Screenshots + Screencasts)
    window-rule {
${renderMatchAppIds privacyScreenCaptureAppIds}
      block-out-from "screen-capture";
    }

    // Screencast Target Indicator
    window-rule {
      match is-window-cast-target=true;
      focus-ring { active-color "#f38ba8"; inactive-color "#7d0d2d"; }
      border { inactive-color "#7d0d2d"; }
      shadow { color "#7d0d2d70"; }
      tab-indicator { active-color "#f38ba8"; inactive-color "#7d0d2d"; }
    }

    // ------------------------------------------------------------------------
    // Appearance & Dimming
    // ------------------------------------------------------------------------
    
    // Borderless Apps
    window-rule {
      match app-id=r#"^(org\.gnome\..*|org\.wezfurlong\.wezterm|zen|com\.mitchellh\.ghostty|kitty|firefox|brave-browser)$"#;
      match app-id=r#"^(Kenp|Ai|CompecTA|Whats|Exclude|brave-youtube\.com__-Default|ferdium)$"#;
      draw-border-with-background false;
    }

    // Inactive Dimming
    window-rule {
      match is-active=false;
      exclude is-window-cast-target=true;
      exclude app-id=r#"^(TmuxKenp|Tmux)$"#;
      exclude app-id=r#"^mpv$" #;
      exclude app-id=r#"^vlc$" #;
      exclude app-id=r#"^brave-youtube\.com__-Default$"#;
      exclude title=r#"^Picture-in-Picture$"#;
      exclude app-id=r#"^steam_app_\d+$"#;
      exclude app-id=r#"^com\.obsproject\.Studio$"#;
      opacity 0.95;
    }

    // Force Opaque for Casted Windows
    window-rule {
      match is-window-cast-target=true;
      opacity 1.0;
    }

    // Force Opaque for Tmux
    window-rule {
      match app-id=r#"^TmuxKenp$"#;
      opacity 1.0;
    }

    // ========================================================================
    // Layer Rules (DMS & Notifications)
    // ========================================================================
    
    layer-rule {
      match namespace=r#"^dms:blurwallpaper$"#;
      place-within-backdrop true;
    }

    layer-rule {
      match namespace=r#"^dms:(bar|dock|panel).*$"#;
      geometry-corner-radius 0;
    }

    layer-rule {
      match namespace=r#"^dms:(launcher|osd|popup).*$"#;
      shadow {
        on;
        color "#00000060";
        spread 2;
        softness 12;
      }
    }

    layer-rule {
      match namespace="^notifications$";
      geometry-corner-radius 12;
      block-out-from "screencast";
      block-out-from "screen-capture";
    }
  '';
}