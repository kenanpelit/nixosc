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
#
# Author: Kenan Pelit
# Last Modified: 2025-07-18
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
    # - Emoji Fonts: Full color emoji support across all applications
    # ==============================================================================
    packages = with pkgs; [
      nerd-fonts.hack        # Primary system font with icon support
      noto-fonts             # Universal font coverage
      noto-fonts-cjk-sans    # Chinese, Japanese, and Korean characters
      noto-fonts-emoji       # Full color emoji support
      liberation_ttf         # Metric-compatible alternatives
      fira-code              # Programming font with ligatures
      fira-code-symbols      # Additional programming symbols
      cascadia-code          # Terminal and console fonts
      inter                  # Modern interface and statistics font
      font-awesome           # Icon font for web and applications
    ];

    # ==============================================================================
    # Font Configuration Settings
    # ==============================================================================
    fontconfig = {
      # Default Font Assignments
      # - Each category has multiple fallback options with emoji support
      # - Ordered by preference and compatibility
      # - Emoji fonts automatically added as fallback for all categories
      defaultFonts = {
        monospace = [ "Hack Nerd Font Mono" "Fira Code" "Liberation Mono" "Noto Color Emoji" ];
        sansSerif = [ "Hack Nerd Font" "Liberation Sans" "Noto Sans" "Noto Color Emoji" ];
        serif = [ "Hack Nerd Font" "Liberation Serif" "Noto Serif" "Noto Color Emoji" ];
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
      # Advanced Font Configuration with Emoji Support
      # ==============================================================================
      # This section contains detailed font rendering rules including:
      # - Global rendering defaults optimized for modern displays
      # - Font-specific optimizations for better readability
      # - Size-specific adjustments for different font sizes
      # - Comprehensive emoji support and color rendering
      # - Unicode range mapping for proper emoji display
      # - Fallback mechanisms for missing glyphs
      # ==============================================================================
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
          <!-- Global Font Rendering Settings -->
          <!-- Optimized for modern LCD displays with subpixel rendering -->
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
          <!-- Ensures optimal rendering for primary system font -->
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

          <!-- Emoji Support Configuration -->
          <!-- Enables color emoji rendering and proper bitmap handling -->
          <match target="font">
            <test name="family" compare="contains">
              <string>Emoji</string>
            </test>
            <edit name="color" mode="assign">
              <bool>true</bool>
            </edit>
            <edit name="bitmap" mode="assign">
              <bool>true</bool>
            </edit>
          </match>

          <!-- Emoji Font Fallback for Monospace -->
          <!-- Ensures emoji display in terminal and code editors -->
          <match target="pattern">
            <test qual="any" name="family">
              <string>monospace</string>
            </test>
            <edit name="family" mode="append" binding="weak">
              <string>Noto Color Emoji</string>
            </edit>
          </match>
          
          <!-- Emoji Font Fallback for Sans-Serif -->
          <!-- Ensures emoji display in UI elements and web content -->
          <match target="pattern">
            <test qual="any" name="family">
              <string>sans-serif</string>
            </test>
            <edit name="family" mode="append" binding="weak">
              <string>Noto Color Emoji</string>
            </edit>
          </match>

          <!-- Emoji Font Fallback for Serif -->
          <!-- Ensures emoji display in documents and reading applications -->
          <match target="pattern">
            <test qual="any" name="family">
              <string>serif</string>
            </test>
            <edit name="family" mode="append" binding="weak">
              <string>Noto Color Emoji</string>
            </edit>
          </match>

          <!-- Unicode Emoji Range Mapping -->
          <!-- Ensures proper emoji font selection for Unicode emoji sequences -->
          <match target="pattern">
            <test name="lang">
              <string>und-zsye</string>
            </test>
            <edit name="family" mode="prepend" binding="strong">
              <string>Noto Color Emoji</string>
            </edit>
          </match>

          <!-- Emoji Presentation Selector Support -->
          <!-- Forces emoji presentation for Unicode characters with dual forms -->
          <match target="pattern">
            <test name="family" compare="contains">
              <string>emoji</string>
            </test>
            <edit name="family" mode="prepend" binding="strong">
              <string>Noto Color Emoji</string>
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
      # Set the font configuration path for system-wide font access
      FONTCONFIG_PATH = "/etc/fonts";
      # Enable UTF-8 locale support for proper emoji rendering
      LC_ALL = "en_US.UTF-8";
    };
  };

  # ==============================================================================
  # Home Manager Configuration
  # ==============================================================================
  # Application-specific font settings managed through home-manager
  # - Configures fonts for notification daemon (dunst) with emoji support
  # - Sets up application launcher (rofi) fonts with icon support
  # - Ensures consistent font usage across all user applications
  # ==============================================================================
  home-manager.users.${username} = {
    home.stateVersion = "25.11";
    
    # Dunst notification daemon font configuration
    # Uses Hack Nerd Font for consistent system-wide appearance
    services.dunst.settings.global = {
      font = "Hack Nerd Font 13";
      # Enable markup for emoji and formatting support
      markup = "full";
    };

    # Rofi application launcher settings
    # Configured with Hack Nerd Font for icon and emoji support
    programs.rofi = {
      font = "Hack Nerd Font 13";
      terminal = "${pkgs.kitty}/bin/kitty";
    };

    # Additional font utilities for user session
    home.shellAliases = {
      "font-list" = "fc-list";
      "font-emoji" = "fc-list | grep -i emoji";
      "font-nerd" = "fc-list | grep -i 'nerd\\|hack'";
      "font-reload" = "fc-cache -f -v";
      "font-test" = "echo 'Font Test: Hack Nerd Font with ★ ♪ ● ⚡ ▲ symbols and emoji support'";
      "emoji-test" = "echo '🎵 📱 💬 🔥 ⭐ 🚀 - Color emoji test'";
    };

    # Session variables for enhanced font and emoji support
    home.sessionVariables = {
      # Ensure proper Unicode and emoji handling
      LC_ALL = "en_US.UTF-8";
      # Font configuration for applications
      FONTCONFIG_FILE = "${pkgs.fontconfig.out}/etc/fonts/fonts.conf";
    };
  };
}

