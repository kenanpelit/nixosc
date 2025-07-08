# modules/home/desktop/gtk/default.nix
# ==============================================================================
# GTK Theme and Configuration
# ==============================================================================
{ config, lib, pkgs, ... }:
let
  # Font ayarları
  fonts = {
    main = {
      family = "Maple Mono";
    };
    sizes = {
      sm = 12;
    };
  };
in
{
  # =============================================================================
  # DConf Settings
  # =============================================================================
  dconf.settings = with lib.hm.gvariant; {
    # ---------------------------------------------------------------------------
    # Desktop Interface Settings
    # ---------------------------------------------------------------------------
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      cursor-size = 24;
      cursor-theme = "catppuccin-mocha-lavender-cursors";
      gtk-theme = "catppuccin-mocha-blue-standard";
      icon-theme = "a-candy-beauty-icon-theme";
      font-name = "${fonts.main.family} ${toString fonts.sizes.sm}";
      text-scaling-factor = 1.0;
      enable-animations = true;
      gtk-enable-primary-paste = true;
      overlay-scrolling = true;
    };
    
    # ---------------------------------------------------------------------------
    # Window Manager Preferences
    # ---------------------------------------------------------------------------
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu";
      theme = "catppuccin-mocha-blue-standard";
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
    # Theme Settings
    # ---------------------------------------------------------------------------
    theme = {
      name = "catppuccin-mocha-blue-standard";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "blue" ];
        size = "standard";
        variant = "mocha";
      };
    };
    
    # ---------------------------------------------------------------------------
    # Icon Theme Settings
    # ---------------------------------------------------------------------------
    iconTheme = {
      name = "a-candy-beauty-icon-theme";
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "mocha";
        accent = "blue";
      };
    };
    
    # ---------------------------------------------------------------------------
    # Cursor Theme Settings
    # ---------------------------------------------------------------------------
    cursorTheme = {
      name = "catppuccin-mocha-lavender-cursors";
      package = pkgs.catppuccin-cursors.mochaLavender;
      size = 24;
    };

    # ---------------------------------------------------------------------------
    # GTK2 Specific Settings
    # ---------------------------------------------------------------------------
    gtk2 = {
      configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
      extraConfig = ''
        gtk-theme-name = "catppuccin-mocha-blue-standard"
        gtk-icon-theme-name = "a-candy-beauty-icon-theme"
        gtk-font-name = "${fonts.main.family} ${toString fonts.sizes.sm}"
        gtk-cursor-theme-name = "catppuccin-mocha-lavender-cursors"
        gtk-cursor-theme-size = 24
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
      gtk-theme-name = "catppuccin-mocha-blue-standard";
      gtk-icon-theme-name = "a-candy-beauty-icon-theme";
      gtk-font-name = "${fonts.main.family} ${toString fonts.sizes.sm}";
      gtk-cursor-theme-name = "catppuccin-mocha-lavender-cursors";
      gtk-cursor-theme-size = 24;
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
      gtk-theme-name = "catppuccin-mocha-blue-standard";
      gtk-icon-theme-name = "a-candy-beauty-icon-theme";
      gtk-font-name = "${fonts.main.family} ${toString fonts.sizes.sm}";
      gtk-cursor-theme-name = "catppuccin-mocha-lavender-cursors";
      gtk-cursor-theme-size = 24;
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
    # Environment Variables
    # ---------------------------------------------------------------------------
    sessionVariables = {
      GTK_THEME = "catppuccin-mocha-blue-standard";
      GTK_USE_PORTAL = "1";
      GTK_APPLICATION_PREFER_DARK_THEME = "1";
      XCURSOR_THEME = "catppuccin-mocha-lavender-cursors";
      XCURSOR_SIZE = "24";
    };

    # ---------------------------------------------------------------------------
    # Package Installation
    # ---------------------------------------------------------------------------
    packages = with pkgs; [
      papirus-folders
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
    # Pointer Cursor Configuration
    # ---------------------------------------------------------------------------
    pointerCursor = {
      name = "catppuccin-mocha-lavender-cursors";
      package = pkgs.catppuccin-cursors.mochaLavender;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
  };
}

