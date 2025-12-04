# modules/home/gtk/default.nix
# ==============================================================================
# GTK Theme and Configuration - Catppuccin Mocha
# ==============================================================================
{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.gtk;
  hmLib = lib.hm or config.lib;
  gvariant = hmLib.gvariant or config.lib.gvariant;
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
  options.my.user.gtk = {
    enable = lib.mkEnableOption "GTK theme configuration";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # DConf Settings - Minimal to avoid conflicts with GTK
    # =============================================================================
    dconf.settings = with gvariant; {
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
      # Theme Settings - Catppuccin Mocha (High priority to enforce dark theme)
      # ---------------------------------------------------------------------------
      theme = {
        name = lib.mkForce "catppuccin-mocha-mauve-standard+normal";
        package = lib.mkForce (pkgs.catppuccin-gtk.override {
          accents = [ "mauve" ];
          size = "standard";
          tweaks = [ "normal" ];
          variant = "mocha";
        });
      };
      
      # ---------------------------------------------------------------------------
      # Icon Theme Settings - BeautyLine
      # ---------------------------------------------------------------------------
      iconTheme = {
        name = lib.mkForce "a-candy-beauty-icon-theme";
        # BeautyLine paketi zaten modules/home/candy/default.nix'de tanımlı
      };

      # ---------------------------------------------------------------------------
      # GTK2 Specific Settings
      # ---------------------------------------------------------------------------
      gtk2 = {
        configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
        extraConfig = lib.mkForce ''
          gtk-icon-theme-name = "a-candy-beauty-icon-theme"
          gtk-theme-name = "catppuccin-mocha-mauve-standard+normal"
          gtk-font-name = "${fonts.main.family} ${toString fonts.sizes.sm}"
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
        gtk-theme-name = lib.mkForce "catppuccin-mocha-mauve-standard+normal";
        gtk-icon-theme-name = lib.mkForce "a-candy-beauty-icon-theme";
        gtk-font-name = lib.mkForce "${fonts.main.family} ${toString fonts.sizes.sm}";
        gtk-application-prefer-dark-theme = lib.mkForce 1;
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
        gtk-theme-name = lib.mkForce "catppuccin-mocha-mauve-standard+normal";
        gtk-icon-theme-name = lib.mkForce "a-candy-beauty-icon-theme";
        gtk-font-name = lib.mkForce "${fonts.main.family} ${toString fonts.sizes.sm}";
        gtk-application-prefer-dark-theme = lib.mkForce 1;
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
      # Environment Variables - Catppuccin Mocha (High priority)
      # ---------------------------------------------------------------------------
      sessionVariables = {
        GTK_THEME = lib.mkForce "catppuccin-mocha-mauve-standard+normal";
        GTK_USE_PORTAL = "1";
        GTK_APPLICATION_PREFER_DARK_THEME = "1";
        GDK_SCALE = "1";
      };

      # ---------------------------------------------------------------------------
      # Package Installation - GTK Theme and Fonts
      # ---------------------------------------------------------------------------
      packages = with pkgs; [
        # Catppuccin GTK Theme
        (catppuccin-gtk.override {
          accents = [ "mauve" ];
          size = "standard";
          tweaks = [ "normal" ];
          variant = "mocha";
        })
        
        # Fonts
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
        nerd-fonts.caskaydia-cove
        nerd-fonts.hack
        nerd-fonts.symbols-only
        twemoji-color-font
        noto-fonts-color-emoji
        maple-mono.NF
        font-awesome
      ];
    };
  };
}
