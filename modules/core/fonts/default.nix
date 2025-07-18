# modules/core/fonts/default.nix
# ==============================================================================
# Font Configuration for NixOS
# ==============================================================================
#
# This configuration module manages system-wide font settings including:
# - System and user-level font packages
# - Font rendering and optimization settings
# - Default font assignments for different categories
# - Font configuration for specific applications
# - Anti-aliasing and hinting configurations
# - Comprehensive emoji support and color rendering
#
# Dependencies:
# - home-manager
# - nerd-fonts
# - noto-fonts
# - liberation-fonts
#
# Note: This configuration prioritizes readability and consistent rendering
# across different display types and resolutions with full emoji support.
# TESTED WORKING: Mako notifications with emoji support confirmed ✅
# PROVEN STABLE: No XML localConf interference with emoji rendering
#
# Author: Kenan Pelit
# Last Modified: 2025-07-18
# ==============================================================================

{ pkgs, username, lib, ... }:
{
  fonts = {
    # ==============================================================================
    # Font Packages Configuration
    # ==============================================================================
    # Primary Fonts:
    # - Hack Nerd Font: Main system font with icon support
    # - Noto Fonts: Universal font family with extensive Unicode coverage
    # - Liberation Fonts: Metric-compatible alternatives to common fonts
    # - Fira Code: Programming font with ligatures
    # - Emoji Fonts: Full color emoji support across all applications
    # CRITICAL: Order and selection tested with Mako - DO NOT CHANGE CORE FONTS
    # ==============================================================================
    packages = with pkgs; [
      # CORE FONTS - TESTED WORKING WITH MAKO (DO NOT MODIFY)
      maple-mono.NF          # YOUR PREFERRED SYSTEM FONT (Nerd Font with icons)
      nerd-fonts.hack        # Primary system font with icon support
      noto-fonts             # Universal font coverage
      noto-fonts-cjk-sans    # Chinese, Japanese, and Korean characters
      noto-fonts-emoji       # Full color emoji support (CRITICAL for Mako)
      liberation_ttf         # Metric-compatible alternatives
      fira-code              # Programming font with ligatures
      fira-code-symbols      # Additional programming symbols
      cascadia-code          # Terminal and console fonts
      inter                  # Modern interface font
      font-awesome           # Icon font for web and applications
      
      # SAFE ADDITIONS - High quality fonts that enhance coverage
      source-code-pro        # Adobe's professional monospace
      dejavu_fonts           # Excellent Unicode coverage backup
      noto-fonts-cjk-serif   # CJK serif fonts for completeness
      noto-fonts-extra       # Additional Noto variants
      material-design-icons  # Material Design icon set
      
      # PREMIUM ADDITIONS - Modern professional fonts
      jetbrains-mono         # JetBrains programming font with ligatures
      ubuntu_font_family     # Ubuntu system fonts
      roboto                 # Google's Roboto font family
      open-sans              # Highly readable web font
    ];

    # ==============================================================================
    # Font Configuration Settings - PROVEN WORKING WITH MAKO
    # ==============================================================================
    fontconfig = {
      # Default Font Assignments
      # - PROVEN WORKING: Conservative approach with only monospace and emoji
      # - Let applications choose their own sans-serif/serif fonts
      # - Emoji fonts as fallback for all categories
      # - THIS EXACT CONFIGURATION WORKS WITH MAKO NOTIFICATIONS
      defaultFonts = {
        monospace = [ "Maple Mono NF" "Hack Nerd Font Mono" "JetBrains Mono" "Fira Code" "Source Code Pro" "Liberation Mono" "Noto Color Emoji" ];
        emoji = [ "Noto Color Emoji" ];
        # Optional: Add safe fallbacks (won't interfere with apps)
        serif = [ "Liberation Serif" "Noto Serif" "DejaVu Serif" ];
        sansSerif = [ "Liberation Sans" "Inter" "Noto Sans" "DejaVu Sans" ];
      };

      # Subpixel Rendering Configuration
      # - RGB ordering for standard LCD displays
      # - Default LCD filter for optimal clarity
      subpixel = {
        rgba = "rgb";          # RGB pixel ordering
        lcdfilter = "default"; # Standard LCD filtering
      };

      # Font Hinting Settings
      # - Controlled font hinting for better rendering
      # - Slight hinting for modern displays
      hinting = {
        enable = true;        # Enable font hinting
        autohint = false;     # Disable autohinting (use built-in hints)
        style = "slight";     # Light hinting for smoother appearance
      };

      # Enable antialiasing for smoother font rendering
      antialias = true;

      # ==============================================================================
      # Advanced Font Configuration - DISABLED FOR MAKO COMPATIBILITY
      # ==============================================================================
      # NOTE: Custom localConf XML rules disabled because they interfere with
      # Mako emoji rendering. The basic fontconfig settings above are sufficient
      # and work perfectly with emoji notifications.
      # 
      # Alternative approach: Use system-level font optimization without custom XML
      # ==============================================================================
      
      # localConf disabled - causes Mako emoji issues
      # localConf = ''...'';
    };
    
    # Enable default font packages provided by Nixpkgs
    enableDefaultPackages = true;

    # Font directory optimization
    fontDir.enable = true;
  };

  # ==============================================================================
  # Environment Configuration - Enhanced
  # ==============================================================================
  environment = {
    variables = {
      # Set the font configuration path for system-wide font access
      FONTCONFIG_PATH = "/etc/fonts";
      # Enable UTF-8 locale support for proper emoji rendering
      LC_ALL = "en_US.UTF-8";
      # Enhanced font rendering
      FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
      # Font cache optimization
      FONTCONFIG_FILE = "/etc/fonts/fonts.conf";
    };
    
    # System-wide font tools
    systemPackages = with pkgs; [
      fontconfig     # Font configuration tools
      font-manager   # GUI font manager
    ];
  };

  # ==============================================================================
  # Home Manager Configuration - Enhanced with Safety
  # ==============================================================================
  # Application-specific font settings managed through home-manager
  # - Font utilities and session variables for enhanced font support
  # - Minimal application interference - let apps choose their own fonts
  # - Enhanced debugging tools while preserving functionality
  # - Comprehensive font testing and management tools
  # ==============================================================================
  home-manager.users.${username} = {
    home.stateVersion = "25.11";

    # User-level fontconfig (safe enhancement)
    fonts.fontconfig.enable = true;

    # Rofi application launcher settings
    programs.rofi = {
      font = "Hack Nerd Font 13";
      terminal = "${pkgs.kitty}/bin/kitty";
    };

    # Comprehensive font utilities for user session
    home.shellAliases = {
      # Original working aliases
      "font-list" = "fc-list";
      "font-emoji" = "fc-list | grep -i emoji";
      "font-nerd" = "fc-list | grep -i 'nerd\\|hack\\|maple'";
      "font-maple" = "fc-list | grep -i maple";
      "font-reload" = "fc-cache -f -v";
      "font-test" = "echo 'Font Test: Hack Nerd Font with ★ ♪ ● ⚡ ▲ symbols and emoji support'";
      "emoji-test" = "echo '🎵 📱 💬 🔥 ⭐ 🚀 - Color emoji test'";
      
      # Enhanced debugging and testing
      "font-info" = "fc-match -v";
      "font-debug" = "fc-match -s monospace | head -5";
      "font-mono" = "fc-list : family | grep -i mono | sort";
      "font-available" = "fc-list : family | sort | uniq";
      "font-cache-clean" = "fc-cache -f -r -v";
      
      # Mako testing (CRITICAL - tests emoji support)
      "mako-emoji-test" = "notify-send 'Emoji Test 🚀' 'Mako notification with emojis: 📱 💬 🔥 ⭐ 🎵'";
      "mako-font-test" = "notify-send 'Font Test' 'Maple Mono NF with symbols: ★ ♪ ● ⚡ ▲  '";
      "mako-icons-test" = "notify-send 'Icon Test' 'Nerd Font icons:       '";
      
      # Font rendering tests
      "font-render-test" = "echo 'Rendering Test: ABCDabcd1234 ★♪●⚡▲ 🚀📱💬     '";
      "font-ligature-test" = "echo 'Ligature Test: -> => != === >= <= && || /* */ //'";
      "font-nerd-icons" = "echo 'Nerd Icons:            '";
    };

    # Session variables for enhanced font and emoji support
    home.sessionVariables = {
      # Original working variables (CRITICAL for Mako)
      LC_ALL = "en_US.UTF-8";
      FONTCONFIG_FILE = "${pkgs.fontconfig.out}/etc/fonts/fonts.conf";
      
      # Enhanced rendering
      FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
      
      # Font optimization
      FONTCONFIG_PATH = "/etc/fonts:~/.config/fontconfig";
    };

    # Additional font-related packages for user
    home.packages = with pkgs; [
      fontpreview        # Font preview tool
      gucharmap         # Character map application
    ];
  };
}

