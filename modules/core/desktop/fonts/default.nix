# modules/core/desktop/fonts/default.nix
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
#
# Dependencies:
# - home-manager
# - nerd-fonts
# - noto-fonts
# - liberation-fonts
#
# Note: This configuration prioritizes readability and consistent rendering
# across different display types and resolutions.
#
# Author: Kenan Pelit
# Last Modified: 2024-01-27
# ==============================================================================

{ pkgs, username, ... }:
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
    # ==============================================================================
    packages = with pkgs; [
      nerd-fonts.hack        # Primary system font with icon support
      noto-fonts             # Universal font coverage
      noto-fonts-cjk-sans    # Chinese, Japanese, and Korean characters
      noto-fonts-emoji       # Full emoji support
      liberation_ttf         # Metric-compatible alternatives
      fira-code              # Programming font with ligatures
      fira-code-symbols      # Additional programming symbols
      cascadia-code          # Terminal and console fonts
      inter                  # Modern interface and statistics font
    ];

    # ==============================================================================
    # Font Configuration Settings
    # ==============================================================================
    fontconfig = {
      # Default Font Assignments
      # - Each category has multiple fallback options
      # - Ordered by preference and compatibility
      defaultFonts = {
        monospace = [ "Hack Nerd Font Mono" "Fira Code" "Liberation Mono" ];
        sansSerif = [ "Hack Nerd Font" "Liberation Sans" "Noto Sans" ];
        serif = [ "Hack Nerd Font" "Liberation Serif" "Noto Serif" ];
        emoji = [ "Noto Color Emoji" ];
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
      # Advanced Font Configuration
      # ==============================================================================
      # This section contains detailed font rendering rules including:
      # - Global rendering defaults
      # - Font-specific optimizations
      # - Size-specific adjustments
      # - Display-specific settings
      # ==============================================================================
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
          <!-- Global Font Rendering Settings -->
          <match target="font">
            <edit name="antialias" mode="assign">
              <bool>true</bool>
            </edit>
            <edit name="hinting" mode="assign">
              <bool>true</bool>
            </edit>
            <edit name="hintstyle" mode="assign">
              <const>hintslight</const>
            </edit>
            <edit name="rgba" mode="assign">
              <const>rgb</const>
            </edit>
            <edit name="lcdfilter" mode="assign">
              <const>lcddefault</const>
            </edit>
          </match>

          <!-- Hack Nerd Font Specific Settings -->
          <match target="font">
            <test name="family" compare="contains">
              <string>Hack Nerd Font</string>
            </test>
            <edit name="antialias" mode="assign">
              <bool>true</bool>
            </edit>
            <edit name="hintstyle" mode="assign">
              <const>hintslight</const>
            </edit>
          </match>

          <!-- Small Font Size Optimization -->
          <!-- Applies full hinting to small fonts for better readability -->
          <match target="font">
            <test name="size" compare="less">
              <double>10</double>
            </test>
            <edit name="hintstyle" mode="assign">
              <const>hintfull</const>
            </edit>
          </match>
        </fontconfig>
      '';
    };
    
    # Enable default font packages provided by Nixpkgs
    enableDefaultPackages = true;
  };

  # ==============================================================================
  # Environment Configuration
  # ==============================================================================
  environment = {
    variables = {
      # Set the font configuration path
      FONTCONFIG_PATH = "/etc/fonts";
    };
  };

  # ==============================================================================
  # Home Manager Configuration
  # ==============================================================================
  # Application-specific font settings managed through home-manager
  # - Configures fonts for notification daemon (dunst)
  # - Sets up application launcher (rofi) fonts
  # ==============================================================================
  home-manager.users.${username} = {
    home.stateVersion = "25.11";
    
    # Dunst notification daemon font configuration
    services.dunst.settings.global = {
      font = "Hack Nerd Font 13";
    };

    # Rofi application launcher settings
    programs.rofi = {
      font = "Hack Nerd Font 13";
      terminal = "${pkgs.kitty}/bin/kitty";
    };
  };
}

