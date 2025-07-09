# modules/home/swayosd/default.nix
# ==============================================================================
# SwayOSD On-Screen Display Configuration
# ==============================================================================
{ lib, pkgs, ... }:
let
  # Tokyo Night tema renkleri
  colors = {
    crust = "#1a1b26";
    text = "#c0caf5";
    surface1 = "#414868";
  };
in
{
  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = with pkgs; [ swayosd ];
  
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
  
  # =============================================================================
  # SwayOSD Styling
  # =============================================================================
  xdg.configFile."swayosd/style.css".text = ''
    /* Window Configuration */
    window {
        padding: 0px 10px;
        border-radius: 30px;
        border: 10px;
        background: alpha(${colors.crust}, 0.99);
    }
    
    /* Container Layout */
    #container {
        margin: 15px;
    }
    
    /* Basic Elements */
    image, label {
        color: ${colors.text};
    }
    
    /* Disabled States */
    progressbar:disabled,
    image:disabled {
        opacity: 0.95;
    }
    
    /* Progress Bar Styling */
    progressbar {
        min-height: 6px;
        border-radius: 999px;
        background: transparent;
        border: none;
    }
    
    trough {
        min-height: inherit;
        border-radius: inherit;
        border: none;
        background: alpha(${colors.surface1}, 0.1);
    }
    
    progress {
        min-height: inherit;
        border-radius: inherit;
        border: none;
        background: ${colors.text};
    }
  '';
}

