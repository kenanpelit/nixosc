# modules/home/hyprland/rules.nix
# ==============================================================================
# Hyprland Window & Layer Rules
#
# Organizes window behaviors by category: Core, Media, Communication,
# System, Workspace Assignments, and UI/Dialogs.
# Imported by default.nix
# ==============================================================================
{ }:

{
  # --- Core & Stability Rules ---
  coreRules = [
    {
      name = "suppress-maximize-events";
      "match:class" = ".*";
      suppress_event = "maximize";
    }
    {
      name = "fix-xwayland-drags";
      "match:class" = "^$";
      "match:title" = "^$";
      "match:xwayland" = true;
      "match:float" = true;
      "match:fullscreen" = false;
      "match:pin" = false;
      no_focus = true;
    }
    {
      name = "context-menu-noshadow";
      "match:class" = "^()$";
      "match:title" = "^()$";
      no_shadow = true;
    }
    {
      name = "context-menu-noblur";
      "match:class" = "^()$";
      "match:title" = "^()$";
      no_blur = true;
    }
    {
      name = "single-window-no-decos";
      "match:float" = false;
      "match:workspace" = "w[tv1]";
      border_size = 0;
      rounding = 0;
      no_shadow = true;
    }
    {
      name = "maximized-window-no-decos";
      "match:float" = false;
      "match:workspace" = "f[1]";
      border_size = 0;
      rounding = 0;
      no_shadow = true;
    }
  ];

  # --- Media & Graphics Rules ---
  mediaRules = [
    {
      name = "mpv-pip";
      "match:class" = "^(mpv)$";
      float = true;
      size = "(monitor_w*0.19) (monitor_h*0.19)";
      move = "(monitor_w*0.01) (monitor_h*0.77)";
      opacity = "1.0 override 1.0 override";
      pin = true;
      idle_inhibit = "focus";
    }
    {
      name = "vlc-workspace";
      "match:class" = "^(vlc)$";
      float = true;
      size = "800 1250";
      move = "1700 90";
      workspace = 6;
      pin = true;
    }
    {
      name = "imv-float";
      "match:class" = "^(imv)$";
      float = true;
      center = true;
      size = "1200 725";
    }
    {
      name = "imv-opacity";
      "match:title" = "^(.*imv.*)$";
      opacity = "1.0 override 1.0 override";
    }
    {
      name = "audacious-float";
      "match:class" = "^(audacious)$";
      float = true;
    }
    {
      name = "audacious-workspace";
      "match:class" = "^(Audacious)$";
      workspace = 5;
    }
    {
      name = "pip-window";
      "match:title" = "^(Picture-in-Picture)$";
      float = true;
      pin = true;
      opacity = "1.0 override 1.0 override";
    }
  ];

  # --- Communication & Social Rules ---
  communicationRules = [
    {
      name = "discord-workspace";
      "match:class" = "^(Discord)$";
      workspace = "5 silent";
    }
    {
      name = "webcord-workspace";
      "match:class" = "^(WebCord)$";
      workspace = 5;
    }
    {
      name = "discord-lowercase";
      "match:class" = "^(discord)$";
      workspace = "5 silent";
      tile = true;
    }
    {
      name = "webcord-link-warning";
      "match:class" = "^(WebCord)$";
      "match:title" = "^(Warning: Opening link in external app)$";
      float = true;
      center = true;
    }
    {
      name = "discord-blob";
      "match:title" = "^(blob:https://discord.com).*$";
      float = true;
      center = true;
      animation = "popin";
    }
    {
      name = "whatsapp-brave";
      "match:title" = "^(web.whatsapp.com)$";
      "match:class" = "^(Brave-browser)$";
      workspace = "9 silent";
    }
    {
      name = "whatsapp-title";
      "match:title" = "^(web.whatsapp.com)$";
      workspace = "9 silent";
    }
    {
      name = "ferdium-whatsapp";
      "match:class" = "^(Ferdium|ferdium)$";
      workspace = "9 silent";
    }
    {
      name = "google-meet";
      "match:title" = "^(Meet).*$";
      float = true;
      size = "918 558";
      workspace = 4;
      center = true;
    }
  ];

  # --- System & Utility Rules ---
  systemRules = [
    {
      name = "htop-float";
      "match:class" = "^(htop)$";
      float = true;
      size = "(monitor_w*0.80) (monitor_h*0.80)";
      center = true;
    }
    {
      name = "yazi-float";
      "match:class" = "^(yazi)$";
      float = true;
      center = true;
      size = "1920 1080";
    }
    {
      name = "vnc-float";
      "match:class" = "^(Vncviewer)$";
      float = true;
      center = true;
    }
    {
      name = "vnc-fullscreen";
      "match:class" = "^(Vncviewer)$";
      "match:title" = "^(.*TigerVNC)$";
      workspace = 6;
      fullscreen = true;
    }
    {
      name = "evince-workspace";
      "match:class" = "^(evince)$";
      workspace = 3;
      opacity = "1.0 override 1.0 override";
    }
    {
      name = "rofi-pin";
      "match:class" = "^(rofi)$";
      pin = true;
    }
    {
      name = "dropdown-terminal";
      "match:class" = "^(dropdown)$";
      float = true;
      size = "(monitor_w*0.99) (monitor_h*0.50)";
      move = "(monitor_w*0.005) (monitor_h*0.03)";
      workspace = "special:dropdown";
    }
    {
      name = "scratchpad-float";
      "match:class" = "^(scratchpad)$";
      float = true;
      center = true;
    }
    {
      name = "kitty-scratch-float";
      "match:class" = "^(kitty-scratch)$";
      float = true;
      size = "(monitor_w*0.75) (monitor_h*0.60)";
      center = true;
    }
  ];

  # --- Workspace Assignment Rules ---
  workspaceRules = [
    # Browsers
    {
      name = "brave-private";
      "match:title" = "^(New Private Tab - Brave)$";
      workspace = "6 silent";
    }
    {
      name = "kenp-workspace";
      "match:class" = "^(Kenp)$";
      workspace = "1 silent";
    }
    {
      name = "kenp-incognito";
      "match:title" = "^Kenp Browser (Inkognito)$";
      workspace = "6 silent";
    }
    {
      name = "brave-youtube";
      "match:class" = "^(brave-youtube.com__-Default)$";
      workspace = "7 silent";
    }
    {
      name = "brave-spotify";
      "match:class" = "^(Brave-browser)$";
      "match:title" = "^(Spotify - Web Player).*";
      workspace = "8 silent";
    }
    # Development
    {
      name = "tmux-workspace";
      "match:class" = "^(Tmux)$";
      "match:title" = "^(Tmux)$";
      workspace = "2 silent";
    }
    {
      name = "tmux-kenp";
      "match:class" = "^(TmuxKenp)$";
      workspace = "2 silent";
    }
    # AI / Docs / Work
    {
      name = "ai-workspace";
      "match:class" = "^(Ai)$";
      workspace = "3 silent";
    }
    {
      name = "compecta-class";
      "match:class" = "^(CompecTA)$";
      workspace = "4 silent";
    }
    {
      name = "compecta-title";
      "match:title" = "^(compecta)$";
      workspace = "4 silent";
    }
    # Communication
    {
      name = "telegram-workspace";
      "match:class" = "^(org.telegram.desktop)$";
      workspace = "6 silent";
    }
    {
      name = "zapzap-workspace";
      "match:class" = "^(com.rtosta.zapzap|zapzap)$";
      workspace = "9 silent";
    }
    {
      name = "remote-viewer-workspace";
      "match:class" = "^(remote-viewer)$";
      workspace = "6 silent";
    }
    # Security / Downloads
    {
      name = "keepassxc";
      "match:class" = "^(org.keepassxc.KeePassXC)$";
      workspace = "7 silent";
    }
    {
      name = "transmission";
      "match:class" = "^(com.transmissionbt.transmission.*)$";
      workspace = "7 silent";
    }
    {
      name = "transmission-float";
      "match:title" = "^(Transmission)$";
      float = true;
    }
    # Entertainment / VM
    {
      name = "spotify-app";
      "match:class" = "^(Spotify|spotify)$";
      workspace = "8 silent";
    }
    {
      name = "qemu-x86";
      "match:class" = "^(qemu-system-x86_64)$";
      workspace = "6 silent";
    }
    {
      name = "qemu-generic";
      "match:class" = "^(qemu)$";
      workspace = "6 silent";
    }
  ];

  # --- UI, Dialogs & Widgets Rules ---
  uiRules = [
    # Auth & Secrets
    {
      name = "ente-auth-float";
      "match:class" = "^(io.ente.auth)$";
      float = true;
      size = "400 900";
      center = true;
    }
    {
      name = "gcr-prompter";
      "match:class" = "^(gcr-prompter)$";
      float = true;
      center = true;
      pin = true;
      animation = "fade";
      opacity = "0.95 0.95";
    }
    # Audio / Network Controls
    {
      name = "volume-control-float";
      "match:title" = "^(Volume Control)$";
      float = true;
      size = "700 450";
      move = "40 55%";
    }
    {
      name = "pavucontrol-float";
      "match:class" = "^(org.pulseaudio.pavucontrol)$";
      float = true;
      size = "(monitor_w*0.60) (monitor_h*0.90)";
      animation = "popin";
    }
    {
      name = "nm-connection-editor";
      "match:class" = "^(nm-connection-editor)$";
      float = true;
      size = "1200 800";
      center = true;
    }
    {
      name = "nm-applet-float";
      "match:class" = "^(nm-applet)$";
      float = true;
      size = "360 440";
      center = true;
    }
    # Browser Specific
    {
      name = "firefox-sharing-indicator";
      "match:title" = "^(Firefox — Sharing Indicator)$";
      float = true;
      move = "0 0";
    }
    {
      name = "firefox-idle-inhibit";
      "match:class" = "^(firefox)$";
      "match:fullscreen" = true;
      idle_inhibit = "fullscreen";
    }
  ];

  # --- Generic Dialogs & Layout Rules ---
  dialogRules = [
    {
      name = "open-file-dialog";
      "match:title" = "^(Open File)$";
      float = true;
    }
    {
      name = "file-upload-dialog";
      "match:title" = "^(File Upload)$";
      float = true;
      size = "850 500";
    }
    {
      name = "replace-files-dialog";
      "match:title" = "^(Confirm to replace files)$";
      float = true;
    }
    {
      name = "file-operation-dialog";
      "match:title" = "^(File Operation Progress)$";
      float = true;
    }
    {
      name = "branch-dialog";
      "match:title" = "^(branchdialog)$";
      float = true;
    }
    {
      name = "file-progress-dialog";
      "match:class" = "^(file_progress)$";
      float = true;
    }
    {
      name = "confirm-dialog";
      "match:class" = "^(confirm)$";
      float = true;
    }
    {
      name = "dialog-generic";
      "match:class" = "^(dialog)$";
      float = true;
    }
    {
      name = "download-dialog";
      "match:class" = "^(download)$";
      float = true;
    }
    {
      name = "notification-dialog";
      "match:class" = "^(notification)$";
      float = true;
    }
    {
      name = "error-dialog";
      "match:class" = "^(error)$";
      float = true;
    }
    {
      name = "confirmreset-dialog";
      "match:class" = "^(confirmreset)$";
      float = true;
    }
    # Layout Defaults
    {
      name = "floating-border";
      "match:float" = true;
      "match:workspace" = "w[v2-99]s[false]";
      border_size = 2;
    }
    {
      name = "floating-rounding";
      "match:float" = true;
      "match:workspace" = "w[v2-99]s[false]";
      rounding = 10;
    }
  ];

  # --- Custom Tools (Clipboard, Notes) & Opacity Rules ---
  miscRules = [
    {
      name = "notes-float";
      "match:class" = "^(notes)$";
      float = true;
      size = "(monitor_w*0.70) (monitor_h*0.50)";
      center = true;
    }
    {
      name = "anote-float";
      "match:class" = "^(anote)$";
      float = true;
      center = true;
      size = "1152 864";
      animation = "slide";
      opacity = "0.95 0.95";
    }
    {
      name = "clipb-float";
      "match:class" = "^(clipb)$";
      float = true;
      center = true;
      size = "1536 864";
      animation = "slide";
    }
    {
      name = "copyq-float";
      "match:class" = "^(com.github.hluk.copyq)$";
      float = true;
      size = "(monitor_w*0.25) (monitor_h*0.80)";
      move = "(monitor_w*0.74) (monitor_h*0.10)";
      animation = "popin";
    }
    {
      name = "clipse-float";
      "match:class" = "^(clipse)$";
      float = true;
      size = "(monitor_w*0.25) (monitor_h*0.80)";
      move = "(monitor_w*0.74) (monitor_h*0.10)";
      animation = "popin";
    }
    # Opacity Overrides
    {
      name = "kitty-opacity";
      "match:class" = "^(kitty)$";
      opacity = "1.0 override 1.0 override";
    }
    {
      name = "brave-opacity";
      "match:class" = "^(Brave-browser)$";
      opacity = "1.0 override 1.0 override";
    }
    {
      name = "kenp-opacity";
      "match:class" = "^(Kenp)$";
      opacity = "1.0 override 1.0 override";
    }
  ];
}
