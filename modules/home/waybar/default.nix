# modules/home/waybar/default.nix
{ pkgs, config, ... }:
let
  # SEÇENEK 1: Catppuccin Mocha - Modern ve popüler
  catppuccin_mocha = {
    base = "#1e1e2e";
    mantle = "#181825";
    crust = "#11111b";
    surface0 = "#313244";
    surface1 = "#45475a";
    surface2 = "#585b70";
    overlay0 = "#6c7086";
    overlay1 = "#7f849c";
    overlay2 = "#9399b2";
    subtext0 = "#a6adc8";
    subtext1 = "#bac2de";
    text = "#cdd6f4";
    lavender = "#b4befe";
    blue = "#89b4fa";
    sapphire = "#74c7ec";
    sky = "#89dceb";
    teal = "#94e2d5";
    green = "#a6e3a1";
    yellow = "#f9e2af";
    peach = "#fab387";
    maroon = "#eba0ac";
    red = "#f38ba8";
    mauve = "#cba6f7";
    pink = "#f5c2e7";
    flamingo = "#f2cdcd";
    rosewater = "#f5e0dc";
  };

  # SEÇENEK 5: One Dark Pro - VS Code tarzı
  one_dark_pro = {
    bg = "#1e2127";
    bg_alt = "#282c34";
    bg_highlight = "#2c313c";
    bg_popup = "#31353f";
    bg_statusline = "#2c313c";
    fg = "#abb2bf";
    fg_alt = "#5c6370";
    base0 = "#1b2229";
    base1 = "#1c1f24";
    base2 = "#202328";
    base3 = "#23272e";
    base4 = "#3f444a";
    base5 = "#5b6268";
    base6 = "#73797e";
    base7 = "#9ca0a4";
    base8 = "#b1b1b1";
    red = "#e06c75";
    orange = "#da8548";
    green = "#98c379";
    teal = "#4db5bd";
    yellow = "#ecbe7b";
    blue = "#61afef";
    dark_blue = "#2257a0";
    magenta = "#c678dd";
    violet = "#a9a1e1";
    cyan = "#46d9ff";
    dark_cyan = "#5699af";
  };

  # SEÇENEK 6: Tokyo Night Storm - Original favori
  tokyo_night_storm = {
    bg = "#24283b";
    bg_dark = "#1f2335";
    bg_float = "#1d202f";
    bg_highlight = "#292e42";
    bg_popup = "#1d202f";
    bg_search = "#3d59a1";
    bg_sidebar = "#1d202f";
    bg_statusline = "#1d202f";
    bg_visual = "#283457";
    border = "#1d202f";
    border_highlight = "#27a1b9";
    comment = "#565f89";
    dark3 = "#545c7e";
    dark5 = "#737aa2";
    fg = "#c0caf5";
    fg_dark = "#a9b1d6";
    fg_gutter = "#3b4261";
    fg_sidebar = "#a9b1d6";
    gitSigns = {
      add = "#449dab";
      change = "#6183bb";
      delete = "#914c54";
    };
    git = {
      add = "#449dab";
      change = "#6183bb";
      delete = "#f7768e";
      ignore = "#545c7e";
    };
    blue = "#7aa2f7";
    blue0 = "#3d59a1";
    blue1 = "#2ac3de";
    blue2 = "#0db9d7";
    blue5 = "#89ddff";
    blue6 = "#b4f9f8";
    blue7 = "#394b70";
    cyan = "#7dcfff";
    green = "#9ece6a";
    green1 = "#73daca";
    green2 = "#41a6b5";
    magenta = "#bb9af7";
    magenta2 = "#ff007c";
    orange = "#ff9e64";
    purple = "#9d7cd8";
    red = "#f7768e";
    red1 = "#db4b4b";
    teal = "#1abc9c";
    terminal_black = "#414868";
    yellow = "#e0af68";
    # Compatibility aliases
    background = "#24283b";
    foreground = "#c0caf5";
    text = "#c0caf5";
    subtext1 = "#a9b1d6";
    subtext0 = "#9aa5ce";
    surface0 = "#363a4f";
    surface1 = "#414868";
    surface2 = "#565f89";
    crust = "#1a1b26";
    base = "#24283b";
    mantle = "#16161e";
  };

  # Seçtiğin tema - değiştirmek için bu satırı düzenle
  selected_theme = tokyo_night_storm;  # catppuccin_mocha, nord_theme, dracula_theme, gruvbox_material, one_dark_pro, tokyo_night_storm
  
  # Universal theme mapping - her tema için çalışır
  colors = {
    # Background layers (darkest to lightest)
    background_0 = selected_theme.crust or selected_theme.bg0 or selected_theme.nord0 or selected_theme.background or selected_theme.bg or selected_theme.bg_dark;
    background_1 = selected_theme.base or selected_theme.bg1 or selected_theme.nord1 or selected_theme.bg_alt or selected_theme.current_line or selected_theme.bg;
    background_2 = selected_theme.mantle or selected_theme.bg2 or selected_theme.nord2 or selected_theme.bg_highlight or selected_theme.current_line or selected_theme.bg_float;
    
    # Surface layers
    surface_0 = selected_theme.surface0 or selected_theme.bg3 or selected_theme.nord3 or selected_theme.bg_popup or selected_theme.current_line or selected_theme.bg_highlight;
    surface_1 = selected_theme.surface1 or selected_theme.bg4 or selected_theme.nord3 or selected_theme.bg_statusline or selected_theme.current_line or selected_theme.bg_statusline;
    surface_2 = selected_theme.surface2 or selected_theme.bg5 or selected_theme.nord3 or selected_theme.bg_statusline or selected_theme.current_line or selected_theme.comment;
    
    # Text colors
    text = selected_theme.text or selected_theme.fg0 or selected_theme.nord6 or selected_theme.foreground or selected_theme.fg;
    subtext1 = selected_theme.subtext1 or selected_theme.fg1 or selected_theme.nord5 or selected_theme.fg_alt or selected_theme.comment or selected_theme.fg_dark;
    subtext0 = selected_theme.subtext0 or selected_theme.gray or selected_theme.nord4 or selected_theme.fg_alt or selected_theme.comment or selected_theme.dark5;
    
    # Semantic colors - her tema için safe fallback'ler
    red = selected_theme.red;
    green = selected_theme.green or selected_theme.nord14;
    yellow = selected_theme.yellow or selected_theme.nord13;
    blue = selected_theme.blue or selected_theme.nord10 or selected_theme.purple;
    magenta = selected_theme.mauve or selected_theme.purple or selected_theme.magenta or selected_theme.violet or selected_theme.nord15;
    cyan = selected_theme.sky or selected_theme.cyan or selected_theme.aqua or selected_theme.teal or selected_theme.nord8;
    orange = selected_theme.peach or selected_theme.orange or selected_theme.nord12;
    pink = selected_theme.pink or selected_theme.magenta or selected_theme.mauve or selected_theme.purple or selected_theme.nord15;
    lavender = selected_theme.lavender or selected_theme.violet or selected_theme.purple or selected_theme.magenta or selected_theme.nord15;
    teal = selected_theme.teal or selected_theme.aqua or selected_theme.cyan or selected_theme.nord7;
  };
  
  # Waybar için optimize edilmiş ayarlar
  custom = {
    font = "JetBrainsMono Nerd Font";
    font_size = "15px";
    font_weight = "600";
    text_color = colors.text;
    subtext_color = colors.subtext1;
    background_0 = colors.background_0;
    background_1 = colors.background_1;
    background_2 = colors.background_2;
    surface_0 = colors.surface_0;
    surface_1 = colors.surface_1;
    surface_2 = colors.surface_2;
    border_color = "rgba(69, 71, 90, 0.8)";
    
    # Semantic colors
    red = colors.red;
    green = colors.green;
    yellow = colors.yellow;
    blue = colors.blue;
    magenta = colors.magenta;
    cyan = colors.cyan;
    orange = colors.orange;
    pink = colors.pink;
    lavender = colors.lavender;
    teal = colors.teal;
    
    # UI específicos
    opacity = "0.95";
    border_radius = "8px";
    inner_radius = "6px";
    
    # Accent colors for different states
    accent_primary = colors.blue;
    accent_secondary = colors.magenta;
    accent_success = colors.green;
    accent_warning = colors.yellow;
    accent_error = colors.red;
    accent_info = colors.cyan;
  };

  # Alternatif tema seçimi için fonksiyon
  # Bu fonksiyonu kullanarak farklı temaları kolayca değiştirebilirsin
  makeTheme = theme_colors: {
    font = "JetBrainsMono Nerd Font";
    font_size = "14px";
    font_weight = "600";
    text_color = theme_colors.text or theme_colors.fg or theme_colors.foreground;
    background_0 = theme_colors.crust or theme_colors.bg0 or theme_colors.background;
    background_1 = theme_colors.base or theme_colors.bg1 or theme_colors.bg_alt;
    # ... diğer mappings
  };

in
{
  # Waybar program yapılandırması
  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oa: {
      mesonFlags = (oa.mesonFlags or [ ]) ++ [ 
        "-Dexperimental=true" 
        "-Dcava=enabled"
        "-Dmpris=enabled" 
      ];
    });
    
    # Ayarları dahil et
    settings = import ./settings.nix { inherit custom; };
    
    # Stilleri dahil et
    style = import ./style.nix { inherit custom; };
  };

  # Systemd servis
  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar - Modern Wayland bar";
      Documentation = "https://github.com/Alexays/Waybar/wiki";
      After = ["hyprland-session.target" "graphical-session.target"];
      PartOf = ["hyprland-session.target"];
      Wants = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.waybar}/bin/waybar --log-level error";
      ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
      Restart = "on-failure";
      RestartSec = "2s";
      KillMode = "mixed";
      Environment = [
        "XDG_CURRENT_DESKTOP=Hyprland"
        "XDG_SESSION_TYPE=wayland"
      ];
    };
    Install = {
      WantedBy = ["hyprland-session.target"];
    };
  };
}

# TEMATİK SEÇENEKLER:
#
# 1. Catppuccin Mocha - Modern, popüler, mükemmel contrast
# 2. One Dark Pro - VS Code tarzı, developer friendly
# 3. Tokyo Night Storm (varsayılan) - Senin favorin! 🌙
#
# Tema değiştirmek için sadece `selected_theme = tokyo_night_storm;` satırını
# başka bir tema ile değiştir!

