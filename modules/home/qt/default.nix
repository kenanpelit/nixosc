# modules/home/qt/default.nix
# ==============================================================================
# Qt Theming and Configuration - Catppuccin Mocha
# ==============================================================================
{ lib, pkgs, ... }:
let
  # Font ayarları - GTK ile uyumlu
  fonts = {
    main = {
      family = "Maple Mono NF";  # GTK ile aynı font
    };
    sizes = {
      sm = 12;
    };
  };
in 
{
  # =============================================================================
  # Required Packages
  # =============================================================================
  home.packages = with pkgs; [
    # ---------------------------------------------------------------------------
    # Theme Packages - Catppuccin Mocha
    # ---------------------------------------------------------------------------
    (catppuccin-kvantum.override {
      accent = "mauve";  # GTK teması ile uyumlu accent
      variant = "mocha";
    })
    
    # ---------------------------------------------------------------------------
    # Qt Support Libraries
    # ---------------------------------------------------------------------------
    libsForQt5.qtstyleplugin-kvantum
    libsForQt5.qt5ct
    libsForQt5.qtstyleplugins
    
    # Qt6 desteği
    kdePackages.qtstyleplugin-kvantum
    qt6Packages.qt6ct
  ];

  # =============================================================================
  # Qt Base Configuration - FIXED for Catppuccin compatibility
  # =============================================================================
  qt = {
    enable = true;
    platformTheme = {
      name = "kvantum";  # CHANGED: gtk3 -> kvantum for Catppuccin compatibility
      package = pkgs.libsForQt5.qtstyleplugin-kvantum;
    };
    style = {
      name = "kvantum";
      package = pkgs.libsForQt5.qtstyleplugin-kvantum;
    };
  };

  # =============================================================================
  # Session Variables - Updated for Kvantum
  # =============================================================================
  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "kvantum";  # CHANGED: gtk3 -> kvantum
    QT_STYLE_OVERRIDE = "kvantum";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    # Wayland için ek ayarlar
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_FORCE_DPI = "96";
  };

  # =============================================================================
  # Configuration Files
  # =============================================================================
  xdg.configFile = {
    # ---------------------------------------------------------------------------
    # Kvantum Theme Configuration - Catppuccin Mocha
    # ---------------------------------------------------------------------------
    "Kvantum/kvantum.kvconfig".text = lib.generators.toINI {} {
      General = {
        theme = "catppuccin-mocha-mauve";  # Mauve accent ile uyumlu
      };
      Applications = {
        # Belirli uygulamalar için özel ayarlar
        "dolphin,konqueror,gwenview,okular" = "catppuccin-mocha-mauve";
        "kate,kwrite,kdevelop" = "catppuccin-mocha-mauve";
      };
    };

    # ---------------------------------------------------------------------------
    # Qt5 Configuration - Enhanced
    # ---------------------------------------------------------------------------
    "qt5ct/qt5ct.conf".text = lib.generators.toINI {} {
      # Appearance Settings
      Appearance = {
        icon_theme = "candy-icons";
        style = "kvantum";
        custom_palette = false;
        standard_dialogs = "gtk3";
        color_scheme_path = "";
      };
      
      # Font Configuration - Catppuccin optimized
      Fonts = {
        fixed = "${fonts.main.family},${toString fonts.sizes.sm},-1,5,400,0,0,0,0,0,Regular";
        general = "${fonts.main.family},${toString fonts.sizes.sm},-1,5,400,0,0,0,0,0,Regular";
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
        gui_effects = "General,AnimateMenu,AnimateCombo,AnimateTooltip,FadeTooltip,AnimateToolBox";
      };
      
      # PaletteEditor - Catppuccin Mocha colors
      PaletteEditor = {
        geometry = "@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\x2V\0\0\0\xb0\0\0\x4\x1\0\0\x2\x80\0\0\x2V\0\0\0\xb0\0\0\x4\x1\0\0\x2\x80\0\0\0\0\0\0\0\0\a\x80\0\0\x2V\0\0\0\xb0\0\0\x4\x1\0\0\x2\x80)";
      };
    };

    # ---------------------------------------------------------------------------
    # Qt6 Configuration - Enhanced
    # ---------------------------------------------------------------------------
    "qt6ct/qt6ct.conf".text = lib.generators.toINI {} {
      # Appearance Settings
      Appearance = {
        icon_theme = "candy-icons";
        style = "kvantum";
        custom_palette = false;
        standard_dialogs = "gtk3";
        color_scheme_path = "";
      };
      
      # Font Configuration
      Fonts = {
        fixed = "${fonts.main.family},${toString fonts.sizes.sm},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular";
        general = "${fonts.main.family},${toString fonts.sizes.sm},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular";
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
        gui_effects = "General,AnimateMenu,AnimateCombo,AnimateTooltip,FadeTooltip,AnimateToolBox";
      };
    };

    # ---------------------------------------------------------------------------
    # Catppuccin Kvantum Custom Config (Opsiyonel)
    # ---------------------------------------------------------------------------
    "Kvantum/catppuccin-mocha-mauve/catppuccin-mocha-mauve.kvconfig".text = ''
      [%General]
      author=Catppuccin
      comment=Catppuccin Mocha Mauve
      alt_mnemonic=true
      left_tabs=true
      attach_active_tab=false
      mirror_doc_tabs=true
      group_toolbar_buttons=false
      toolbar_item_spacing=0
      toolbar_interior_spacing=2
      spread_progressbar=true
      composite=true
      menu_shadow_depth=6
      tooltip_shadow_depth=2
      splitter_width=1
      scroll_width=12
      scroll_arrows=false
      scroll_min_extent=60
      slider_width=6
      slider_handle_width=16
      slider_handle_length=16
      center_toolbar_handle=true
      check_size=16
      textless_progressbar=false
      progressbar_thickness=4
      menubar_mouse_tracking=true
      toolbutton_style=1
      double_click=false
      translucent_windows=false
      blurring=false
      popup_blurring=true
      vertical_spin_indicators=false
      spin_button_width=16
      fill_rubberband=false
      merge_menubar_with_toolbar=true
      small_icon_size=16
      large_icon_size=32
      button_icon_size=16
      toolbar_icon_size=16
      combo_as_lineedit=true
      animate_states=true
      button_contents_shift=false
      combo_menu=true
      hide_combo_checkboxes=true
      combo_focus_rect=true
      groupbox_top_label=true
      inline_spin_indicators=true
      joined_inactive_tabs=false
    '';
  };

  # =============================================================================
  # Additional Theme Consistency
  # =============================================================================
  home.file = {
    # Ensure Kvantum finds our custom theme
    ".config/Kvantum/catppuccin-mocha-mauve/.directory".text = ''
      [Desktop Entry]
      Name=Catppuccin Mocha Mauve
      Comment=Catppuccin Mocha theme with Mauve accent
    '';
  };
}

