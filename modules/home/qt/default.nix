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
  
  # Catppuccin Mocha Mauve color palette
  colors = {
    # Base colors
    base = "#1e1e2e";
    mantle = "#181825";
    crust = "#11111b";
    
    # Text colors
    text = "#cdd6f4";
    subtext0 = "#a6adc8";
    subtext1 = "#bac2de";
    
    # Surface colors
    surface0 = "#313244";
    surface1 = "#45475a";
    surface2 = "#585b70";
    
    # Accent - Mauve
    accent = "#cba6f7";
    accentHover = "#b4befe";
    
    # Overlay
    overlay0 = "#6c7086";
    overlay1 = "#7f849c";
    overlay2 = "#9399b2";
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
  # Qt Base Configuration - Catppuccin Mocha Mauve
  # =============================================================================
  qt = {
    enable = true;
    platformTheme = {
      name = "kvantum";
      package = pkgs.kdePackages.qtstyleplugin-kvantum;  # Qt6 için güncellendi
    };
    style = {
      name = "kvantum";
      package = pkgs.kdePackages.qtstyleplugin-kvantum;
    };
  };

  # =============================================================================
  # Session Variables - Wayland + Dark Theme
  # =============================================================================
  home.sessionVariables = {
    # Qt Platform Theme
    QT_QPA_PLATFORMTHEME = "kvantum";
    QT_STYLE_OVERRIDE = "kvantum";
    
    # Dark theme forcing
    QT_QPA_SYSTEMTRAY_DARK_MODE = "1";
    
    # Wayland optimizations
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_WAYLAND_FORCE_DPI = "96";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    
    # Font rendering - GTK ile uyumlu
    QT_FONT_DPI = "96";
    QT_ENABLE_HIGHDPI_SCALING = "1";
  };

  # =============================================================================
  # Configuration Files
  # =============================================================================
  xdg.configFile = {
    # ---------------------------------------------------------------------------
    # Kvantum Theme Configuration - Catppuccin Mocha Mauve
    # ---------------------------------------------------------------------------
    "Kvantum/kvantum.kvconfig".text = lib.generators.toINI {} {
      General = {
        theme = "catppuccin-mocha-mauve";
      };
      Applications = {
        # Qt uygulamaları için tema
        "dolphin,konqueror,gwenview,okular" = "catppuccin-mocha-mauve";
        "kate,kwrite,kdevelop" = "catppuccin-mocha-mauve";
        # Polkit agent için özel tema
        "polkit-kde-authentication-agent-1,hyprpolkitagent" = "catppuccin-mocha-mauve";
      };
    };

    # ---------------------------------------------------------------------------
    # Qt5 Configuration - Catppuccin Enhanced
    # ---------------------------------------------------------------------------
    "qt5ct/qt5ct.conf".text = lib.generators.toINI {} {
      Appearance = {
        icon_theme = "a-candy-beauty-icon-theme";
        style = "kvantum";
        custom_palette = true;  # Custom palette aktif
        standard_dialogs = "gtk3";
        color_scheme_path = "";
      };
      
      Fonts = {
        fixed = "${fonts.main.family},${toString fonts.sizes.sm},-1,5,400,0,0,0,0,0,Regular";
        general = "${fonts.main.family},${toString fonts.sizes.sm},-1,5,400,0,0,0,0,0,Regular";
      };
      
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
      
      # Catppuccin Mocha Mauve custom palette
      Palette = {
        active_colors = "${colors.text},${colors.surface0},${colors.surface2},${colors.surface1},${colors.surface0},${colors.overlay0},${colors.text},${colors.text},${colors.text},${colors.base},${colors.surface0},${colors.overlay1},${colors.accent},${colors.text},${colors.accent},${colors.accent},${colors.mantle},${colors.text},${colors.surface1},${colors.text},${colors.overlay0}";
        disabled_colors = "${colors.overlay1},${colors.surface0},${colors.surface2},${colors.surface1},${colors.surface0},${colors.overlay0},${colors.overlay1},${colors.overlay1},${colors.overlay1},${colors.base},${colors.surface0},${colors.overlay1},${colors.overlay0},${colors.overlay1},${colors.overlay0},${colors.overlay0},${colors.mantle},${colors.text},${colors.surface1},${colors.text},${colors.overlay0}";
        inactive_colors = "${colors.subtext0},${colors.surface0},${colors.surface2},${colors.surface1},${colors.surface0},${colors.overlay0},${colors.subtext0},${colors.subtext0},${colors.subtext0},${colors.base},${colors.surface0},${colors.overlay1},${colors.accentHover},${colors.subtext0},${colors.accentHover},${colors.accentHover},${colors.mantle},${colors.text},${colors.surface1},${colors.text},${colors.overlay0}";
      };
    };

    # ---------------------------------------------------------------------------
    # Qt6 Configuration - Catppuccin Enhanced
    # ---------------------------------------------------------------------------
    "qt6ct/qt6ct.conf".text = lib.generators.toINI {} {
      Appearance = {
        icon_theme = "a-candy-beauty-icon-theme";
        style = "kvantum";
        custom_palette = true;
        standard_dialogs = "gtk3";
        color_scheme_path = "";
      };
      
      Fonts = {
        fixed = "${fonts.main.family},${toString fonts.sizes.sm},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular";
        general = "${fonts.main.family},${toString fonts.sizes.sm},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular";
      };
      
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
      
      # Catppuccin Mocha Mauve custom palette
      Palette = {
        active_colors = "${colors.text},${colors.surface0},${colors.surface2},${colors.surface1},${colors.surface0},${colors.overlay0},${colors.text},${colors.text},${colors.text},${colors.base},${colors.surface0},${colors.overlay1},${colors.accent},${colors.text},${colors.accent},${colors.accent},${colors.mantle},${colors.text},${colors.surface1},${colors.text},${colors.overlay0}";
        disabled_colors = "${colors.overlay1},${colors.surface0},${colors.surface2},${colors.surface1},${colors.surface0},${colors.overlay0},${colors.overlay1},${colors.overlay1},${colors.overlay1},${colors.base},${colors.surface0},${colors.overlay1},${colors.overlay0},${colors.overlay1},${colors.overlay0},${colors.overlay0},${colors.mantle},${colors.text},${colors.surface1},${colors.text},${colors.overlay0}";
        inactive_colors = "${colors.subtext0},${colors.surface0},${colors.surface2},${colors.surface1},${colors.surface0},${colors.overlay0},${colors.subtext0},${colors.subtext0},${colors.subtext0},${colors.base},${colors.surface0},${colors.overlay1},${colors.accentHover},${colors.subtext0},${colors.accentHover},${colors.accentHover},${colors.mantle},${colors.text},${colors.surface1},${colors.text},${colors.overlay0}";
      };
    };

    # ---------------------------------------------------------------------------
    # Catppuccin Kvantum Enhanced Config
    # ---------------------------------------------------------------------------
    "Kvantum/catppuccin-mocha-mauve/catppuccin-mocha-mauve.kvconfig".text = ''
      [%General]
      author=Catppuccin
      comment=Catppuccin Mocha Mauve - Hyprland Optimized
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
      translucent_windows=true
      blurring=true
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
      
      [Hacks]
      transparent_dolphin_view=true
      transparent_ktitle_label=true
      transparent_menutitle=true
      respect_darkness=true
      kcapacitybar_as_progressbar=true
      force_size_grip=true
      iconless_pushbutton=false
      iconless_menu=false
      disabled_icon_opacity=70
      lxqtmainmenu_iconsize=22
      normal_default_pushbutton=true
      single_top_toolbar=true
      tint_on_mouseover=0
      transparent_pcmanfm_sidepane=true
      transparent_pcmanfm_view=false
      blur_translucent=true
      opaque_colors=false
      
      [PanelButtonCommand]
      frame=true
      frame.element=button
      frame.top=3
      frame.bottom=3
      frame.left=3
      frame.right=3
      interior=true
      interior.element=button
      indicator.size=8
      text.normal.color=${colors.text}
      text.focus.color=${colors.text}
      text.press.color=${colors.accent}
      text.toggle.color=${colors.accent}
      text.shadow=0
      text.margin=1
      text.iconspacing=4
      indicator.element=arrow
      text.margin.top=2
      text.margin.bottom=2
      text.margin.left=2
      text.margin.right=2
      frame.expansion=0
    '';
  };

  # =============================================================================
  # Additional Theme Files
  # =============================================================================
  home.file = {
    # Kvantum theme directory marker
    ".config/Kvantum/catppuccin-mocha-mauve/.directory".text = ''
      [Desktop Entry]
      Name=Catppuccin Mocha Mauve
      Comment=Catppuccin Mocha theme with Mauve accent - Hyprland optimized
    '';
  };
}
