# modules/home/cava/default.nix
# ==============================================================================
# Cava Audio Visualizer Configuration - Dynamic Catppuccin Theme
# ==============================================================================
{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.cava;
  
  # Automatic color extraction from Catppuccin module
  inherit (config.catppuccin) sources;
  
  # Colors from Palette JSON - dynamic flavor support
  colors = (lib.importJSON "${sources.palette}/palette.json").${config.catppuccin.flavor}.colors;
  
  # Dynamic Catppuccin gradient colors based on flavor
  gradientColors = {
    gradient_color_1 = colors.rosewater.hex;
    gradient_color_2 = colors.flamingo.hex;
    gradient_color_3 = colors.pink.hex;
    gradient_color_4 = colors.mauve.hex;
    gradient_color_5 = colors.red.hex;
    gradient_color_6 = colors.maroon.hex;
    gradient_color_7 = colors.peach.hex;
    gradient_color_8 = colors.yellow.hex;
  };
in
{
  options.my.user.cava = {
    enable = lib.mkEnableOption "Cava audio visualizer";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Program Configuration
    # =============================================================================
    programs.cava = {
      enable = lib.mkForce true;
      
      settings = {
        # =========================================================================
        # General Settings
        # =========================================================================
        general = {
          # Audio
          autosens = lib.mkForce 1;
          overshoot = lib.mkForce 0;
          sensitivity = lib.mkForce 100;
          
          # Bars
          bars = lib.mkForce 0;  # 0 = auto detect terminal width
          bar_width = lib.mkForce 2;
          bar_spacing = lib.mkForce 1;
          
          # Performance
          framerate = lib.mkForce 60;
          sleep_timer = lib.mkForce 1;
          
          # Input
          source = lib.mkForce "auto";  # auto, pulse, alsa, fifo, shmem
        };
        
        # =========================================================================
        # Input Settings
        # =========================================================================
        input = {
          method = lib.mkForce "pulse";
          source = lib.mkForce "auto";
        };
        
        # =========================================================================
        # Output Settings - FIXED: Use supported method
        # =========================================================================
        output = {
          method = lib.mkForce "ncurses";  # CHANGED: ncurses instead of terminal
          channels = lib.mkForce "stereo";  # mono, stereo
          mono_option = lib.mkForce "average";  # left, right, average
          reverse = lib.mkForce 0;
          # Remove terminal-specific options that don't work with ncurses
          # raw_target = lib.mkForce "/dev/stdout";
          # data_format = lib.mkForce "binary";
          # bit_format = lib.mkForce "16bit";
          # ascii_max_range = lib.mkForce 1000;
          # bar_delimiter = lib.mkForce 59;
          # frame_delimiter = lib.mkForce 10;
        };
        
        # =========================================================================
        # Color Theme - Dynamic Catppuccin ${lib.strings.toUpper config.catppuccin.flavor}
        # =========================================================================
        color = {
          # Enable gradient - USE mkForce to override Catppuccin module
          gradient = lib.mkForce 1;
          gradient_count = lib.mkForce 8;
          
          # Dynamic Catppuccin gradient colors
          gradient_color_1 = lib.mkForce "'${gradientColors.gradient_color_1}'";
          gradient_color_2 = lib.mkForce "'${gradientColors.gradient_color_2}'";
          gradient_color_3 = lib.mkForce "'${gradientColors.gradient_color_3}'";
          gradient_color_4 = lib.mkForce "'${gradientColors.gradient_color_4}'";
          gradient_color_5 = lib.mkForce "'${gradientColors.gradient_color_5}'";
          gradient_color_6 = lib.mkForce "'${gradientColors.gradient_color_6}'";
          gradient_color_7 = lib.mkForce "'${gradientColors.gradient_color_7}'";
          gradient_color_8 = lib.mkForce "'${gradientColors.gradient_color_8}'";
        };
        
        # =========================================================================
        # Smoothing Settings
        # =========================================================================
        smoothing = {
          # Noise reduction
          noise_reduction = lib.mkForce 0.77;
          
          # Integral smoothing
          integral = lib.mkForce 74;
          
          # Gravity
          gravity = lib.mkForce 100;
          
          # Ignore
          ignore = lib.mkForce 0;
        };
        
        # =========================================================================
        # Equalizer Settings
        # =========================================================================
        eq = {
          # Higher and lower cut off frequencies for frequencies to be displayed
          lower_cutoff_freq = lib.mkForce 50;
          higher_cutoff_freq = lib.mkForce 10000;
        };
      };
    };
    
    # =============================================================================
    # Shell Aliases
    # =============================================================================
    home.shellAliases = {
      cava-theme = "echo 'Current Cava Catppuccin flavor: ${config.catppuccin.flavor}'";
      cava-config = "cat ~/.config/cava/config | grep -A10 '\\[color\\]'";
    };
  };
}
