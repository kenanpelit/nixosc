# modules/home/swayosd/default.nix
# ==============================================================================
# SwayOSD On-Screen Display Configuration with Dynamic Catppuccin
# ==============================================================================
{ config, lib, pkgs, ... }:
let
  # Catppuccin dinamik renk sistemi - ultra safe fallback
  catppuccinEnabled = config ? catppuccin && config.catppuccin ? enable && config.catppuccin.enable;
  catppuccinLibEnabled = config ? lib && config.lib ? catppuccin;
  
  flavor = if catppuccinEnabled then config.catppuccin.flavor else "mocha";
  accent = if catppuccinEnabled then config.catppuccin.accent else "mauve";
  
  # Completely safe color system
  colors = if (catppuccinEnabled && catppuccinLibEnabled)
    then config.lib.catppuccin.mkColors flavor
    else {
      # Static Mocha colors - no dynamic access
      crust = { hex = "#11111b"; };
      text = { hex = "#cdd6f4"; };
      surface1 = { hex = "#45475a"; };
      surface0 = { hex = "#313244"; };
      overlay0 = { hex = "#6c7086"; };
      lavender = { hex = "#b4befe"; };
      yellow = { hex = "#f9e2af"; };
      peach = { hex = "#fab387"; };
      red = { hex = "#f38ba8"; };
      green = { hex = "#a6e3a1"; };
      blue = { hex = "#89b4fa"; };
      mauve = { hex = "#cba6f7"; };
    };
    
  # Safe accent color access
  accentColor = if (catppuccinEnabled && catppuccinLibEnabled && colors ? ${accent})
    then colors.${accent}
    else colors.mauve;
in
{
  # =============================================================================
  # Hyprland Integration
  # =============================================================================
  wayland.windowManager.hyprland = {
    settings = {
      # ---------------------------------------------------------------------------
      # Startup Configuration
      # ---------------------------------------------------------------------------
      exec-once = [ "swayosd-server" ];
      
      # ---------------------------------------------------------------------------
      # Basic Volume Control
      # ---------------------------------------------------------------------------
      bind = [ 
        ",XF86AudioMute, exec, swayosd-client --output-volume mute-toggle" 
      ];
      
      # ---------------------------------------------------------------------------
      # Brightness Control (Lock Screen Compatible)
      # ---------------------------------------------------------------------------
      bindl = [
        ",XF86MonBrightnessUp, exec, swayosd-client --brightness raise 5%+"
        ",XF86MonBrightnessDown, exec, swayosd-client --brightness lower 5%-"
        "$mainMod, XF86MonBrightnessUp, exec, brightnessctl set 100%"
        "$mainMod, XF86MonBrightnessDown, exec, brightnessctl set 0%"
      ];
      
      # ---------------------------------------------------------------------------
      # Volume Control (Hold)
      # ---------------------------------------------------------------------------
      bindle = [
        ",XF86AudioRaiseVolume, exec, swayosd-client --output-volume +2 --max-volume=100"
        ",XF86AudioLowerVolume, exec, swayosd-client --output-volume -2"
        "$mainMod, f12, exec, swayosd-client --output-volume +2 --max-volume=100"
        "$mainMod, f11, exec, swayosd-client --output-volume -2"
      ];
      
      # ---------------------------------------------------------------------------
      # Lock Keys
      # ---------------------------------------------------------------------------
      bindr = [
        "CAPS,Caps_Lock,exec,swayosd-client --caps-lock"
        ",Scroll_Lock,exec,swayosd-client --scroll-lock"
        ",Num_Lock,exec,swayosd-client --num-lock"
      ];
    };
  };

  # SwayOSD binary for volume/brightness keybindings
  home.packages = [ pkgs.swayosd ];
  
  # =============================================================================
  # SwayOSD Dynamic Catppuccin Styling
  # =============================================================================
  xdg.configFile."swayosd/style.css".text = ''
    /* 
     * SwayOSD Dynamic Catppuccin ${lib.strings.toUpper (lib.substring 0 1 flavor)}${lib.substring 1 (-1) flavor} Theme
     * Accent: ${lib.strings.toUpper (lib.substring 0 1 accent)}${lib.substring 1 (-1) accent}
     * Catppuccin Enabled: ${lib.boolToString catppuccinEnabled}
     */
    
    /* Window Configuration */
    window {
        padding: 0px 10px;
        border-radius: 30px;
        border: 10px;
        background: alpha(${colors.crust.hex}, 0.99);
        /* Subtle accent border */
        box-shadow: inset 0 0 0 2px alpha(${accentColor.hex}, 0.3);
    }
    
    /* Container Layout */
    #container {
        margin: 15px;
    }
    
    /* Basic Elements */
    image, label {
        color: ${colors.text.hex};
    }
    
    /* Icon coloring based on accent */
    image {
        -gtk-icon-style: symbolic;
        color: ${accentColor.hex};
    }
    
    /* Label styling */
    label {
        font-weight: 500;
        text-shadow: 0 1px 2px alpha(${colors.crust.hex}, 0.5);
    }
    
    /* Disabled States */
    progressbar:disabled,
    image:disabled {
        opacity: 0.5;
        color: ${colors.overlay0.hex};
    }
    
    /* Progress Bar Styling */
    progressbar {
        min-height: 8px;
        border-radius: 999px;
        background: transparent;
        border: none;
        box-shadow: 0 2px 4px alpha(${colors.crust.hex}, 0.3);
    }
    
    /* Progress Bar Track */
    trough {
        min-height: inherit;
        border-radius: inherit;
        border: none;
        background: alpha(${colors.surface1.hex}, 0.3);
        box-shadow: inset 0 1px 2px alpha(${colors.crust.hex}, 0.4);
    }
    
    /* Progress Bar Fill - Static Accent Color */
    progress {
        min-height: inherit;
        border-radius: inherit;
        border: none;
        background: linear-gradient(90deg, 
                    ${accentColor.hex}, 
                    alpha(${accentColor.hex}, 0.8));
        box-shadow: 0 1px 3px alpha(${accentColor.hex}, 0.4);
        transition: all 0.2s ease;
    }
    
    /* Volume/Brightness specific styling */
    progressbar.volume progress {
        background: linear-gradient(90deg, 
                    ${accentColor.hex}, 
                    ${colors.lavender.hex});
    }
    
    progressbar.brightness progress {
        background: linear-gradient(90deg, 
                    ${colors.yellow.hex}, 
                    ${colors.peach.hex});
    }
    
    /* Caps Lock indicator */
    .caps-lock {
        color: ${colors.red.hex};
        font-weight: bold;
    }
    
    /* Num Lock indicator */
    .num-lock {
        color: ${colors.green.hex};
        font-weight: bold;
    }
    
    /* Scroll Lock indicator */
    .scroll-lock {
        color: ${colors.blue.hex};
        font-weight: bold;
    }
    
    /* Muted state */
    .muted {
        color: ${colors.overlay0.hex};
        opacity: 0.7;
    }
    
    /* Animation for state changes */
    window {
        transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    }
    
    progress {
        transition: background 0.3s ease, box-shadow 0.2s ease;
    }
    
    /* High contrast mode support */
    @media (prefers-contrast: high) {
        window {
            border: 2px solid ${accentColor.hex};
        }
        
        progress {
            background: ${accentColor.hex};
        }
        
        trough {
            background: ${colors.surface0.hex};
        }
    }
    
    /* Reduced motion support */
    @media (prefers-reduced-motion: reduce) {
        * {
            transition: none !important;
            animation: none !important;
        }
    }
  '';
}
