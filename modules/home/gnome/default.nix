# modules/home/gnome/default.nix
# ==============================================================================
# MINIMAL GNOME Configuration - Packages, Themes, Fonts Only
# Settings will be applied via external script
# ==============================================================================
{ config, lib, pkgs, ... }:

with lib;

let
  # Font ayarları
  fonts = {
    main = {
      family = "Maple Mono";
    };
    editor = {
      family = "Maple Mono";
    };
    terminal = {
      family = "Hack Nerd Font";
    };
    sizes = {
      sm = 12;
      md = 13;
      xl = 15;
    };
  };

  # Catppuccin dinamik renk sistemi
  inherit (config.catppuccin) flavor accent;
  colors = config.lib.catppuccin.mkColors flavor;
  
  # Dinamik tema isimlendirmesi
  themeNames = {
    gtk = "catppuccin-${flavor}-${accent}-standard+normal";
    shell = "catppuccin-${flavor}-${accent}-standard+normal";
    icon = "a-candy-beauty-icon-theme";
    cursor = "catppuccin-${flavor}-dark-cursors";
  };
  
  cfg = config.modules.desktop.gnome or {};
  
  # Wallpaper paths - will be symlinked from 54.jpg
  wallpaperPath = "${config.home.homeDirectory}/Pictures/wallpapers/others/54.jpg";
  lockscreenPath = "${config.home.homeDirectory}/Pictures/wallpapers/others/54.jpg";
  
in
{
  # =============================================================================
  # Options
  # =============================================================================
  options.modules.desktop.gnome = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable GNOME desktop environment configuration";
    };
  };

  config = mkIf (cfg.enable or true) {
    # ==========================================================================
    # Package Installation
    # ==========================================================================
    home.packages = with pkgs; [
      # GNOME core applications
      evince                      # PDF viewer
      file-roller                 # Archive manager
      gnome-text-editor          # Text editor
      nautilus                    # File manager
      gnome-terminal             # Terminal
      gnome-calculator           # Calculator
      gnome-calendar             # Calendar
      gnome-contacts             # Contacts
      gnome-weather              # Weather
      gnome-clocks               # Clocks
      eog                        # Image viewer
      gnome-font-viewer          # Font viewer
      gnome-system-monitor       # System monitor
      gnome-disk-utility         # Disk utility
      gnome-screenshot           # Screenshot tool
      
      # GNOME utilities
      gnome-tweaks               # Advanced settings
      dconf-editor               # Configuration editor
      
      # Additional applications
      cheese                     # Webcam
      totem                      # Video player
      snapshot                   # Camera
      loupe                      # Image viewer
      
      # Extra tools for keybindings
      copyq                      # Clipboard manager
      kitty                      # Terminal
      nemo                       # File manager alternative
      
      # Theme support
      gtk3
      gtk4
      
      # Workspace management tools
      wmctrl                     # Window/workspace control
      xdotool                    # X automation
    ];

    # ==========================================================================
    # GTK Configuration
    # ==========================================================================
    gtk = {
      enable = true;
      
      theme = {
        name = themeNames.gtk;
        package = null;
      };
      
      iconTheme = {
        name = themeNames.icon;
        package = null;
      };
      
      cursorTheme = {
        name = themeNames.cursor;
        size = 24;
        package = null;
      };

      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-cursor-theme-name = themeNames.cursor;
        gtk-cursor-theme-size = 24;
        gtk-font-name = "${fonts.main.family} ${toString fonts.sizes.sm}";
        gtk-icon-theme-name = themeNames.icon;
        gtk-theme-name = themeNames.gtk;
      };

      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-cursor-theme-name = themeNames.cursor;
        gtk-cursor-theme-size = 24;
        gtk-font-name = "${fonts.main.family} ${toString fonts.sizes.sm}";
        gtk-icon-theme-name = themeNames.icon;
        gtk-theme-name = themeNames.gtk;
      };
    };

    # ==========================================================================
    # XDG Settings
    # ==========================================================================
    xdg = {
      enable = true;
      
      mimeApps = {
        enable = true;
        defaultApplications = {
          "text/plain" = "org.gnome.TextEditor.desktop";
          "text/html" = "brave-browser.desktop";
          "application/pdf" = "org.gnome.Evince.desktop";
          "image/jpeg" = "org.gnome.eog.desktop";
          "image/png" = "org.gnome.eog.desktop";
          "video/mp4" = "org.gnome.Totem.desktop";
          "audio/mpeg" = "org.gnome.Music.desktop";
          "inode/directory" = "org.gnome.Nautilus.desktop";
        };
      };
      
      userDirs = {
        enable = true;
        createDirectories = true;
      };
    };

    # ==========================================================================
    # Session Variables
    # ==========================================================================
    home.sessionVariables = {
      GNOME_SESSION = "1";
      
      # Catppuccin Theme
      CATPPUCCIN_THEME = flavor;
      CATPPUCCIN_ACCENT = accent;
      GTK_THEME = themeNames.gtk;
      XCURSOR_THEME = themeNames.cursor;
      XCURSOR_SIZE = "24";
      
      # HiDPI support
      GDK_SCALE = mkDefault "1";
      GDK_DPI_SCALE = mkDefault "1";
      
      # System variables
      EDITOR = "nvim";
      VISUAL = "nvim";
      TERMINAL = "kitty";
      TERM = "xterm-256color";
      BROWSER = "brave";
    };

    # ==========================================================================
    # GTK CSS Files (Dynamic Catppuccin)
    # ==========================================================================
    home.file.".config/gtk-3.0/gtk.css".text = ''
      /* Catppuccin ${lib.strings.toUpper (lib.substring 0 1 flavor)}${lib.substring 1 (-1) flavor} GTK3 */
      .nemo-window {
          background-color: ${colors.base.hex};
          color: ${colors.text.hex};
      }

      .nemo-window .toolbar {
          background-color: ${colors.mantle.hex};
          border-bottom: 1px solid ${colors.surface0.hex};
      }

      .nemo-window .sidebar {
          background-color: ${colors.mantle.hex};
          border-right: 1px solid ${colors.surface0.hex};
      }

      .nemo-window .view {
          background-color: ${colors.base.hex};
          color: ${colors.text.hex};
      }

      .nemo-window .view:selected {
          background-color: ${colors.${accent}.hex};
          color: ${colors.base.hex};
      }

      window {
          background-color: ${colors.base.hex};
          color: ${colors.text.hex};
      }

      .titlebar {
          background-color: ${colors.mantle.hex};
          color: ${colors.text.hex};
      }

      button {
          background-color: ${colors.surface0.hex};
          color: ${colors.text.hex};
          border: 1px solid ${colors.surface1.hex};
      }

      button:hover {
          background-color: ${colors.surface1.hex};
      }

      button:active {
          background-color: ${colors.${accent}.hex};
          color: ${colors.base.hex};
      }

      entry {
          background-color: ${colors.surface0.hex};
          color: ${colors.text.hex};
          border: 1px solid ${colors.surface1.hex};
      }

      entry:focus {
          border-color: ${colors.${accent}.hex};
      }

      .sidebar {
          background-color: ${colors.mantle.hex};
          color: ${colors.text.hex};
      }

      .sidebar:selected {
          background-color: ${colors.${accent}.hex};
          color: ${colors.base.hex};
      }
    '';

    home.file.".config/gtk-4.0/gtk.css".text = ''
      /* Catppuccin ${lib.strings.toUpper (lib.substring 0 1 flavor)}${lib.substring 1 (-1) flavor} GTK4 */
      window {
          background-color: ${colors.base.hex};
          color: ${colors.text.hex};
      }

      .titlebar {
          background-color: ${colors.mantle.hex};
          color: ${colors.text.hex};
      }

      button {
          background-color: ${colors.surface0.hex};
          color: ${colors.text.hex};
      }

      button:hover {
          background-color: ${colors.surface1.hex};
      }

      button:active {
          background-color: ${colors.${accent}.hex};
          color: ${colors.base.hex};
      }

      entry {
          background-color: ${colors.surface0.hex};
          color: ${colors.text.hex};
      }

      entry:focus {
          border-color: ${colors.${accent}.hex};
      }
    '';

  };
}

