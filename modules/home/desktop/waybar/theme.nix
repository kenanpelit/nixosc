# modules/home/desktop/waybar/theme.nix
{ kenp, effects, fonts, spacing }:

let
  # Tema varyantları için yardımcı fonksiyonlar
  withOpacity = color: opacity: "rgba(${builtins.substring 1 6 color}, ${opacity})";
  
  # Ana renkler
  colors = {
    # Temel renkler
    primary = kenp.blue;
    secondary = kenp.mauve;
    accent = kenp.sky;
    success = kenp.green;
    warning = kenp.yellow;
    error = kenp.red;
    info = kenp.teal;
    
    # Arka plan tonları
    bg = {
      primary = kenp.crust;
      secondary = kenp.base;
      tertiary = kenp.mantle;
      elevated = kenp.surface0;
      overlay = kenp.surface1;
    };
    
    # Metin renkleri
    text = {
      primary = kenp.text;
      secondary = kenp.subtext1;
      muted = kenp.subtext0;
      accent = kenp.lavender;
    };
    
    # Özel durumlar
    state = {
      hover = withOpacity kenp.blue "0.15";
      active = withOpacity kenp.mauve "0.15";
      focus = withOpacity kenp.sky "0.2";
      disabled = withOpacity kenp.surface2 "0.5";
    };
  };

  # Tipografi sistemi
  typography = {
    # Font aileleri
    families = {
      primary = fonts.main.family;
      ui = fonts.ui.family or fonts.main.family;
      mono = fonts.mono.family;
      system = "Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif";
    };
    
    # Font boyutları (px cinsinden)
    sizes = {
      xs = "${toString fonts.sizes.xs}px";
      sm = "${toString fonts.sizes.sm}px";
      base = "${toString fonts.sizes.base}px";
      md = "${toString fonts.sizes.md}px";
      lg = "${toString fonts.sizes.lg}px";
      xl = "${toString fonts.sizes.xl}px";
      "2xl" = "${toString fonts.sizes."2xl"}px";
      "3xl" = "${toString fonts.sizes."3xl"}px";
    };
    
    # Font ağırlıkları
    weights = {
      light = "300";
      normal = "400";
      medium = "500";
      semibold = "600";
      bold = "700";
    };
    
    # Satır yükseklikleri
    lineHeights = {
      tight = "1.2";
      normal = "1.4";
      relaxed = "1.6";
    };
  };

  # Animasyon ve geçiş efektleri
  animations = {
    durations = {
      fast = "150ms";
      normal = "250ms";
      slow = "400ms";
    };
    
    easings = {
      default = "cubic-bezier(0.4, 0, 0.2, 1)";
      easeIn = "cubic-bezier(0.4, 0, 1, 1)";
      easeOut = "cubic-bezier(0, 0, 0.2, 1)";
      bounce = "cubic-bezier(0.68, -0.55, 0.265, 1.55)";
    };
    
    # Standart geçiş
    transition = "all ${animations.durations.normal} ${animations.easings.default}";
  };

  # Gölge efektleri
  shadows = {
    sm = "0 1px 2px rgba(0, 0, 0, 0.05)";
    base = "0 2px 4px rgba(0, 0, 0, 0.1)";
    md = "0 4px 6px rgba(0, 0, 0, 0.1)";
    lg = "0 8px 15px rgba(0, 0, 0, 0.15)";
    xl = "0 20px 25px rgba(0, 0, 0, 0.2)";
    glow = "0 0 20px rgba(122, 162, 247, 0.3)";
  };

  # Boyutlandırma sistemi
  dimensions = {
    # Waybar boyutları
    bar = {
      height = "36px";
      padding = spacing.md;
      margin = spacing.sm;
    };
    
    # Modül boyutları
    module = {
      minHeight = "28px";
      minWidth = "32px";
      padding = {
        x = spacing.md;
        y = spacing.xs;
      };
      margin = spacing.xs;
    };
    
    # Border radius
    radius = {
      sm = "4px";
      base = effects.radius or "8px";
      md = "10px";
      lg = "12px";
      xl = "16px";
      full = "50%";
    };
    
    # Border kalınlıkları
    borders = {
      thin = "1px";
      base = "2px";
      thick = "3px";
    };
  };

  # Workspace ikonları
  workspaceIcons = {
    browser = "󰖟";
    terminal = "󰆍";
    documents = "󰈙";
    design = "󰑴";
    communication = "󰙯";
    entertainment = "󰊖";
    security = "󰒓";
    music = "󰎆";
    chat = "󰍹";
    development = "󰅨";
    
    # Durum ikonları
    states = {
      urgent = "";
      focused = "";
      default = "";
      special = "";
      empty = "";
    };
  };

  # Sistem ikonları
  systemIcons = {
    audio = {
      high = "󰕾";
      medium = "󰖀";
      low = "󰕿";
      muted = "󰝟";
      microphone = "󰍬";
      microphoneMuted = "󰍭";
    };
    
    network = {
      wifi = "󰤨";
      ethernet = "󰤥";
      disconnected = "󰤭";
      vpn = "󰖂";
    };
    
    battery = {
      levels = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂"];
      charging = "󰂄";
      full = "󰁹";
    };
    
    system = {
      cpu = "󰻠";
      memory = "󰍛";
      disk = "󰋊";
      temperature = "󱃃";
      bluetooth = "󰂯";
      notification = "󰂚";
      firewall = "󰕥";
      power = "⏻";
    };
  };

in
{
  # Ana tema konfigürasyonu
  custom = {
    # Temel ayarlar
    font = typography.families.primary;
    font_size = typography.sizes."2xl";
    font_weight = typography.weights.semibold;
    
    # Ana renkler (geriye dönük uyumluluk için)
    text_color = colors.text.primary;
    background_0 = colors.bg.primary;
    background_1 = colors.bg.secondary;
    border_color = colors.bg.overlay;
    
    # Renk paleti
    red = colors.error;
    green = colors.success;
    yellow = colors.warning;
    blue = colors.primary;
    magenta = colors.secondary;
    cyan = colors.accent;
    orange = kenp.peach;
    orange_bright = kenp.flamingo;
    
    # Efektler
    opacity = effects.opacity;
    blur = effects.blur;
    shadow = shadows.base;
    transition = animations.transition;
    
    # Boyutlar
    indicator_height = "3px";
    border_radius = dimensions.radius.base;
    bar_height = dimensions.bar.height;
    module_padding = dimensions.module.padding.x;
  };

  # Gelişmiş tema sistemi
  theme = {
    inherit colors typography animations shadows dimensions;
    inherit workspaceIcons systemIcons;
    
    # Modül stilleri
    modules = {
      # Workspace modülü
      workspace = {
        button = {
          padding = "${dimensions.module.padding.y} ${dimensions.module.padding.x}";
          margin = "0 ${spacing.xs}";
          borderRadius = dimensions.radius.sm;
          transition = animations.transition;
          minWidth = dimensions.module.minWidth;
          fontSize = typography.sizes.lg;
        };
        
        states = {
          normal = {
            color = colors.text.secondary;
            background = colors.bg.elevated;
            border = "1px solid ${colors.bg.overlay}";
          };
          
          active = {
            color = colors.secondary;
            background = colors.state.active;
            border = "1px solid ${colors.secondary}";
            boxShadow = "0 2px 8px ${withOpacity colors.secondary "0.2"}";
          };
          
          urgent = {
            color = colors.error;
            background = withOpacity colors.error "0.15";
            border = "1px solid ${colors.error}";
            animation = "workspace_urgent 1s ease-in-out infinite";
          };
          
          hover = {
            color = colors.accent;
            background = colors.state.hover;
            border = "1px solid ${colors.accent}";
          };
        };
      };
      
      # Sistem modülleri için temel stil
      system = {
        base = {
          padding = "${dimensions.module.padding.y} ${dimensions.module.padding.x}";
          margin = "${spacing.xs}";
          background = colors.bg.secondary;
          border = "1px solid ${colors.bg.overlay}";
          borderRadius = dimensions.radius.base;
          boxShadow = shadows.sm;
          transition = animations.transition;
          fontSize = typography.sizes.base;
          fontWeight = typography.weights.medium;
        };
        
        hover = {
          background = colors.state.hover;
          border = "1px solid ${colors.primary}";
          boxShadow = shadows.md;
        };
      };
      
      # Özel modül renkleri
      colors = {
        bluetooth = colors.accent;
        network = colors.primary;
        battery = colors.secondary;
        audio = colors.secondary;
        cpu = colors.success;
        memory = colors.secondary;
        disk = colors.warning;
        temperature = colors.success;
        clock = colors.accent;
        vpn = colors.success;
        weather = colors.primary;
        notification = colors.warning;
        firewall = colors.success;
        power = colors.error;
      };
    };
    
    # Animasyonlar
    keyframes = {
      blink_critical = ''
        @keyframes blink-critical {
          0%, 50% { 
            background-color: ${colors.error}; 
            color: ${colors.bg.primary}; 
          }
          51%, 100% { 
            background-color: ${withOpacity colors.error "0.2"}; 
            color: ${colors.error}; 
          }
        }
      '';
      
      workspace_urgent = ''
        @keyframes workspace_urgent {
          0% { box-shadow: 0 0 5px ${withOpacity colors.error "0.3"}; }
          50% { box-shadow: 0 0 15px ${withOpacity colors.error "0.6"}; }
          100% { box-shadow: 0 0 5px ${withOpacity colors.error "0.3"}; }
        }
      '';
      
      pulse = ''
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.7; }
        }
      '';
    };
  };
}

