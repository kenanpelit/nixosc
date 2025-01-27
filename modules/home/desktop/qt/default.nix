# modules/home/desktop/qt/default.nix
# ==============================================================================
# Qt Theming and Configuration
# ==============================================================================
{ lib, pkgs, ... }:
let
  colors = import ./../../../themes/default.nix;
in 
{
  # =============================================================================
  # Required Packages
  # =============================================================================
  home.packages = with pkgs; [
    # ---------------------------------------------------------------------------
    # Theme Packages
    # ---------------------------------------------------------------------------
    (catppuccin-kvantum.override {
      accent = "blue";
      variant = "mocha";
    })
    
    # ---------------------------------------------------------------------------
    # Qt Support Libraries
    # ---------------------------------------------------------------------------
    libsForQt5.qtstyleplugin-kvantum
    libsForQt5.qt5ct
    libsForQt5.qtstyleplugins
  ];

  # =============================================================================
  # Qt Base Configuration
  # =============================================================================
  qt = {
    enable = true;
    platformTheme = {
      name = "gtk3";
      package = pkgs.libsForQt5.qtstyleplugins;
    };
    style = {
      name = "kvantum";
      package = pkgs.libsForQt5.qtstyleplugin-kvantum;
    };
  };

  # =============================================================================
  # Session Variables
  # =============================================================================
  systemd.user.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "gtk3";
    QT_STYLE_OVERRIDE = "kvantum";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
  };

  # =============================================================================
  # Configuration Files
  # =============================================================================
  xdg.configFile = {
    # ---------------------------------------------------------------------------
    # Kvantum Theme Configuration
    # ---------------------------------------------------------------------------
    kvantum = {
      target = "Kvantum/kvantum.kvconfig";
      text = lib.generators.toINI { } { 
        General = {
          theme = "catppuccin-mocha-blue";
        }; 
      };
    };

    # ---------------------------------------------------------------------------
    # Qt5 Configuration
    # ---------------------------------------------------------------------------
    qt5ct = {
      target = "qt5ct/qt5ct.conf";
      text = lib.generators.toINI { } {
        # Appearance Settings
        Appearance = {
          icon_theme = "a-candy-beauty-icon-theme";
          style = "kvantum";
          custom_palette = false;
          standard_dialogs = "gtk3";
        };
        # Font Configuration
        Fonts = {
          fixed = "${colors.fonts.main.family},${lib.strings.removeSuffix "px" colors.fonts.sizes.sm},-1,5,50,0,0,0,0,0";
          general = "${colors.fonts.main.family},${lib.strings.removeSuffix "px" colors.fonts.sizes.sm},-1,5,50,0,0,0,0,0";
        };
        # Interface Behavior
        Interface = {
          buttonbox_layout = 0;
          cursor_flash_time = 1000;
          dialog_buttons_have_icons = true;
          double_click_interval = 400;
          keyboard_scheme = 2;
          menus_have_icons = true;
          show_shortcuts_in_context_menus = true;
          stylesheets = "@Invalid()";
          toolbutton_style = 4;
          underline_shortcut = 1;
          wheel_scroll_lines = 3;
          gui_effects = "animation";
        };
      };
    };

    # ---------------------------------------------------------------------------
    # Qt6 Configuration
    # ---------------------------------------------------------------------------
    qt6ct = {
      target = "qt6ct/qt6ct.conf";
      text = lib.generators.toINI { } {
        # Appearance Settings
        Appearance = {
          icon_theme = "a-candy-beauty-icon-theme";
          style = "kvantum";
          custom_palette = false;
          standard_dialogs = "gtk3";
        };
        # Font Configuration
        Fonts = {
          fixed = "${colors.fonts.main.family},${lib.strings.removeSuffix "px" colors.fonts.sizes.sm},-1,5,50,0,0,0,0,0";
          general = "${colors.fonts.main.family},${lib.strings.removeSuffix "px" colors.fonts.sizes.sm},-1,5,50,0,0,0,0,0";
        };
        # Interface Behavior
        Interface = {
          buttonbox_layout = 0;
          cursor_flash_time = 1000;
          dialog_buttons_have_icons = true;
          double_click_interval = 400;
          keyboard_scheme = 2;
          menus_have_icons = true;
          show_shortcuts_in_context_menus = true;
          stylesheets = "@Invalid()";
          toolbutton_style = 4;
          underline_shortcut = 1;
          wheel_scroll_lines = 3;
          gui_effects = "animation";
        };
      };
    };
  };
}

