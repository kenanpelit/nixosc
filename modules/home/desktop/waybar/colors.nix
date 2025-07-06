# modules/home/desktop/waybar/colors.nix
{ config, ... }:

let
  # Ana tema konfigürasyonunu import et
  themeConfig = import ./../../../themes/default.nix;
  
  # Waybar temasını oluştur
  waybarTheme = import ./theme.nix {
    inherit (themeConfig) kenp effects fonts spacing;
  };
  
  # Utility fonksiyonları
  utils = {
    # Renk opacity'si için yardımcı fonksiyon
    withOpacity = color: opacity: 
      "rgba(${builtins.substring 1 2 color}${builtins.substring 3 2 color}${builtins.substring 5 2 color}, ${opacity})";
    
    # Hex to RGB dönüştürücü
    hexToRgb = hex:
      let
        r = builtins.substring 1 2 hex;
        g = builtins.substring 3 2 hex;
        b = builtins.substring 5 2 hex;
      in
      "${toString (builtins.fromTOML "r=0x${r}").r}, ${toString (builtins.fromTOML "g=0x${g}").g}, ${toString (builtins.fromTOML "b=0x${b}").b}";
    
    # CSS değişkeni oluşturucusu
    cssVar = name: value: "--${name}: ${value};";
    
    # Tema değişkenlerini CSS custom properties olarak export et
    exportCssVars = theme: builtins.concatStringsSep "\n" (
      builtins.attrValues (
        builtins.mapAttrs (name: value: utils.cssVar name value) theme
      )
    );
  };

in
{
  # Geriye dönük uyumluluk için mevcut custom objesi
  inherit (waybarTheme) custom;
  
  # Gelişmiş tema sistemi
  inherit (waybarTheme) theme;
  
  # Utility fonksiyonları
  inherit utils;
  
  # CSS değişkenleri string'i
  cssVariables = ''
    :root {
      /* Ana renkler */
      --color-primary: ${waybarTheme.theme.colors.primary};
      --color-secondary: ${waybarTheme.theme.colors.secondary};
      --color-accent: ${waybarTheme.theme.colors.accent};
      --color-success: ${waybarTheme.theme.colors.success};
      --color-warning: ${waybarTheme.theme.colors.warning};
      --color-error: ${waybarTheme.theme.colors.error};
      --color-info: ${waybarTheme.theme.colors.info};
      
      /* Arka plan renkleri */
      --bg-primary: ${waybarTheme.theme.colors.bg.primary};
      --bg-secondary: ${waybarTheme.theme.colors.bg.secondary};
      --bg-tertiary: ${waybarTheme.theme.colors.bg.tertiary};
      --bg-elevated: ${waybarTheme.theme.colors.bg.elevated};
      --bg-overlay: ${waybarTheme.theme.colors.bg.overlay};
      
      /* Metin renkleri */
      --text-primary: ${waybarTheme.theme.colors.text.primary};
      --text-secondary: ${waybarTheme.theme.colors.text.secondary};
      --text-muted: ${waybarTheme.theme.colors.text.muted};
      --text-accent: ${waybarTheme.theme.colors.text.accent};
      
      /* Durum renkleri */
      --state-hover: ${waybarTheme.theme.colors.state.hover};
      --state-active: ${waybarTheme.theme.colors.state.active};
      --state-focus: ${waybarTheme.theme.colors.state.focus};
      --state-disabled: ${waybarTheme.theme.colors.state.disabled};
      
      /* Tipografi */
      --font-primary: ${waybarTheme.theme.typography.families.primary};
      --font-ui: ${waybarTheme.theme.typography.families.ui};
      --font-mono: ${waybarTheme.theme.typography.families.mono};
      --font-system: ${waybarTheme.theme.typography.families.system};
      
      /* Font boyutları */
      --font-size-xs: ${waybarTheme.theme.typography.sizes.xs};
      --font-size-sm: ${waybarTheme.theme.typography.sizes.sm};
      --font-size-base: ${waybarTheme.theme.typography.sizes.base};
      --font-size-md: ${waybarTheme.theme.typography.sizes.md};
      --font-size-lg: ${waybarTheme.theme.typography.sizes.lg};
      --font-size-xl: ${waybarTheme.theme.typography.sizes.xl};
      --font-size-2xl: ${waybarTheme.theme.typography.sizes."2xl"};
      --font-size-3xl: ${waybarTheme.theme.typography.sizes."3xl"};
      
      /* Font ağırlıkları */
      --font-weight-light: ${waybarTheme.theme.typography.weights.light};
      --font-weight-normal: ${waybarTheme.theme.typography.weights.normal};
      --font-weight-medium: ${waybarTheme.theme.typography.weights.medium};
      --font-weight-semibold: ${waybarTheme.theme.typography.weights.semibold};
      --font-weight-bold: ${waybarTheme.theme.typography.weights.bold};
      
      /* Animasyonlar */
      --duration-fast: ${waybarTheme.theme.animations.durations.fast};
      --duration-normal: ${waybarTheme.theme.animations.durations.normal};
      --duration-slow: ${waybarTheme.theme.animations.durations.slow};
      
      --easing-default: ${waybarTheme.theme.animations.easings.default};
      --easing-ease-in: ${waybarTheme.theme.animations.easings.easeIn};
      --easing-ease-out: ${waybarTheme.theme.animations.easings.easeOut};
      --easing-bounce: ${waybarTheme.theme.animations.easings.bounce};
      
      --transition: ${waybarTheme.theme.animations.transition};
      
      /* Gölgeler */
      --shadow-sm: ${waybarTheme.theme.shadows.sm};
      --shadow-base: ${waybarTheme.theme.shadows.base};
      --shadow-md: ${waybarTheme.theme.shadows.md};
      --shadow-lg: ${waybarTheme.theme.shadows.lg};
      --shadow-xl: ${waybarTheme.theme.shadows.xl};
      --shadow-glow: ${waybarTheme.theme.shadows.glow};
      
      /* Boyutlar */
      --radius-sm: ${waybarTheme.theme.dimensions.radius.sm};
      --radius-base: ${waybarTheme.theme.dimensions.radius.base};
      --radius-md: ${waybarTheme.theme.dimensions.radius.md};
      --radius-lg: ${waybarTheme.theme.dimensions.radius.lg};
      --radius-xl: ${waybarTheme.theme.dimensions.radius.xl};
      --radius-full: ${waybarTheme.theme.dimensions.radius.full};
      
      --border-thin: ${waybarTheme.theme.dimensions.borders.thin};
      --border-base: ${waybarTheme.theme.dimensions.borders.base};
      --border-thick: ${waybarTheme.theme.dimensions.borders.thick};
      
      /* Bar boyutları */
      --bar-height: ${waybarTheme.theme.dimensions.bar.height};
      --module-min-height: ${waybarTheme.theme.dimensions.module.minHeight};
      --module-min-width: ${waybarTheme.theme.dimensions.module.minWidth};
    }
  '';
  
  # Tema varyantları için fonksiyonlar
  variants = {
    # Koyu tema (varsayılan)
    dark = waybarTheme;
    
    # Açık tema için renk değişiklikleri
    light = waybarTheme // {
      custom = waybarTheme.custom // {
        background_0 = "#f8f9fa";
        background_1 = "#ffffff";
        text_color = "#2e3440";
        border_color = "#e9ecef";
      };
    };
    
    # Yüksek kontrast tema
    highContrast = waybarTheme // {
      custom = waybarTheme.custom // {
        background_0 = "#000000";
        background_1 = "#1a1a1a";
        text_color = "#ffffff";
        border_color = "#444444";
      };
    };
  };
  
  # Responsive ayarlar
  responsive = {
    mobile = {
      bar_height = "40px";
      font_size = "14px";
      module_padding = "6px";
    };
    
    tablet = {
      bar_height = "38px";
      font_size = "15px";
      module_padding = "8px";
    };
    
    desktop = waybarTheme.custom;
  };
}


