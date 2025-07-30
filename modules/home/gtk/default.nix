# modules/home/gtk/default.nix
# ==============================================================================
# GTK Theme and Configuration - Catppuccin Mocha
# ==============================================================================
{ config, lib, pkgs, ... }:
let
  # Font ayarları
  fonts = {
    main = {
      family = "Maple Mono NF";
    };
    sizes = {
      sm = 12;
    };
  };
in
{
  # =============================================================================
  # DConf Settings - Minimal to avoid conflicts with GTK
  # =============================================================================
  dconf.settings = with lib.hm.gvariant; {
    # ---------------------------------------------------------------------------
    # Desktop Interface Settings - Only non-conflicting settings
    # ---------------------------------------------------------------------------
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-animations = mkBoolean true;
      gtk-enable-primary-paste = mkBoolean true;
      overlay-scrolling = mkBoolean true;
      text-scaling-factor = mkDouble 1.0;
    };
    
    # ---------------------------------------------------------------------------
    # Window Manager Preferences
    # ---------------------------------------------------------------------------
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu";
    };
  };

  # =============================================================================
  # GTK Configuration
  # =============================================================================
  gtk = {
    enable = true;
    
    # ---------------------------------------------------------------------------
    # Font Settings
    # ---------------------------------------------------------------------------
    font = {
      name = fonts.main.family;
      size = fonts.sizes.sm;
    };
    
    # ---------------------------------------------------------------------------
    # Theme Settings - Catppuccin Mocha (Düzeltildi)
    # ---------------------------------------------------------------------------
    theme = {
      name = "catppuccin-mocha-mauve-standard+normal";  # Doğru tema adı
      package = pkgs.catppuccin-gtk.override {
        accents = [ "mauve" ];
        size = "standard";
        tweaks = [ "normal" ];
        variant = "mocha";
      };
    };
    
    # ---------------------------------------------------------------------------
    # Icon Theme Settings - BeautyLine (korundu)
    # ---------------------------------------------------------------------------
    iconTheme = {
      name = "a-candy-beauty-icon-theme";
      # BeautyLine paketi zaten modules/home/candy/default.nix'de tanımlı
    };
    
    # ---------------------------------------------------------------------------
    # Cursor Theme Settings - RE-ENABLED for Catppuccin compatibility
    # ---------------------------------------------------------------------------
    cursorTheme = {
      name = "catppuccin-mocha-mauve-cursors";  # CHANGED: dark -> mauve for consistency
      package = pkgs.catppuccin-cursors.mochaMauve;  # CHANGED: mochaDark -> mochaMauve
      size = 24;
    };

    # ---------------------------------------------------------------------------
    # GTK2 Specific Settings
    # ---------------------------------------------------------------------------
    gtk2 = {
      configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
      extraConfig = ''
        gtk-theme-name = "catppuccin-mocha-mauve-standard+normal"
        gtk-icon-theme-name = "a-candy-beauty-icon-theme"
        gtk-font-name = "${fonts.main.family} ${toString fonts.sizes.sm}"
        # gtk-cursor-theme-name = "catppuccin-mocha-dark-cursors"  # Disabled
        # gtk-cursor-theme-size = 24  # Disabled
        gtk-application-prefer-dark-theme = 1
        gtk-button-images = 1
        gtk-menu-images = 1
        gtk-enable-event-sounds = 0
        gtk-enable-input-feedback-sounds = 0
        gtk-xft-antialias = 1
        gtk-xft-hinting = 1
        gtk-xft-hintstyle = "hintslight"
        gtk-xft-rgba = "rgb"
        gtk-error-bell = 0
        gtk-decoration-layout = "appmenu"
      '';
    };
    
    # ---------------------------------------------------------------------------
    # GTK3 Specific Settings
    # ---------------------------------------------------------------------------
    gtk3.extraConfig = {
      gtk-theme-name = "catppuccin-mocha-mauve-standard+normal";
      gtk-icon-theme-name = "a-candy-beauty-icon-theme";
      gtk-font-name = "${fonts.main.family} ${toString fonts.sizes.sm}";
      # gtk-cursor-theme-name = "catppuccin-mocha-dark-cursors";  # Disabled
      # gtk-cursor-theme-size = 24;  # Disabled
      gtk-application-prefer-dark-theme = 1;
      gtk-button-images = 1;
      gtk-menu-images = 1;
      gtk-enable-event-sounds = 0;
      gtk-enable-input-feedback-sounds = 0;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
      gtk-decoration-layout = "appmenu";
    };
    
    # ---------------------------------------------------------------------------
    # GTK4 Specific Settings
    # ---------------------------------------------------------------------------
    gtk4.extraConfig = {
      gtk-theme-name = "catppuccin-mocha-mauve-standard+normal";
      gtk-icon-theme-name = "a-candy-beauty-icon-theme";
      gtk-font-name = "${fonts.main.family} ${toString fonts.sizes.sm}";
      # gtk-cursor-theme-name = "catppuccin-mocha-dark-cursors";  # Disabled
      # gtk-cursor-theme-size = 24;  # Disabled
      gtk-application-prefer-dark-theme = 1;
      gtk-button-images = 1;
      gtk-menu-images = 1;
      gtk-enable-event-sounds = 0;
      gtk-enable-input-feedback-sounds = 0;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
      gtk-decoration-layout = "appmenu";
    };
  };

  # =============================================================================
  # Home Manager Configuration
  # =============================================================================
  home = {
    # ---------------------------------------------------------------------------
    # Environment Variables - Catppuccin Mocha (Cursor variables disabled)
    # ---------------------------------------------------------------------------
    sessionVariables = {
      GTK_THEME = "catppuccin-mocha-mauve-standard+normal";  # Doğru tema adı
      GTK_USE_PORTAL = "1";
      GTK_APPLICATION_PREFER_DARK_THEME = "1";
      # XCURSOR_THEME = "catppuccin-mocha-dark-cursors";  # Disabled - handled by Catppuccin module
      # XCURSOR_SIZE = "24";  # Disabled - handled by Catppuccin module
      GDK_SCALE = "1";
      # Hyprland için ek ayarlar
      # QT_QPA_PLATFORMTHEME = "gtk3";  # DISABLED - handled by QT module to avoid conflicts
      GDK_BACKEND = "wayland,x11";
      QT_QPA_PLATFORM = "wayland;xcb";
      CLUTTER_BACKEND = "wayland";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
    };

    # ---------------------------------------------------------------------------
    # Package Installation - Catppuccin Mocha
    # ---------------------------------------------------------------------------
    packages = with pkgs; [
      # Catppuccin GTK Theme
      (catppuccin-gtk.override {
        accents = [ "mauve" ];
        size = "standard";
        tweaks = [ "normal" ];  # "default" yerine "normal" kullanıyoruz
        variant = "mocha";
      })
      
      # Catppuccin Cursors - moved to Catppuccin module
      # catppuccin-cursors
      
      # BeautyLine zaten modules/home/candy/default.nix'de tanımlı, burada tekrarlamıyoruz
      
      # Fonts (mevcut fontlarınız)
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.caskaydia-cove
      nerd-fonts.hack
      nerd-fonts.symbols-only
      twemoji-color-font
      noto-fonts-emoji
      maple-mono.NF
      font-awesome
    ];
    
    # ---------------------------------------------------------------------------
    # Pointer Cursor Configuration - RE-ENABLED with Mauve cursor
    # ---------------------------------------------------------------------------
    pointerCursor = {
      name = "catppuccin-mocha-mauve-cursors";  # CHANGED: dark -> mauve
      package = pkgs.catppuccin-cursors.mochaMauve;  # CHANGED: mochaDark -> mochaMauve
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
  };
}

