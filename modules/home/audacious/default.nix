# modules/home/audacious/default.nix
# ==============================================================================
# Home module for Audacious audio player.
# Installs player and keeps user config/hooks managed by Home Manager.
# Tweak plugins/themes here instead of editing upstream dotfiles manually.
# ==============================================================================

{ pkgs, username, lib, config, ... }:
let
  cfg = config.my.user.audacious;
in
{
  options.my.user.audacious = {
    enable = lib.mkEnableOption "Audacious music player";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Player Configuration
    # =============================================================================
    xdg.configFile."audacious/config".text = ''
      # ============================================================================
      # Core Settings
      # ============================================================================
      [audacious]
      equalizer_active=TRUE
      equalizer_bands=-1,1,2,2,1,0,0,-1,-1,-1
      soft_clipping=TRUE
      # ============================================================================
      # GUI Settings
      # ============================================================================
      [audgui]
      filesel_path=/home/${username}/Music
      # ============================================================================
      # Qt Interface Settings
      # ============================================================================
      [audqt]
      icon_theme=audacious-flat-dark
      theme=dark
      # ============================================================================
      # Audio Settings
      # ============================================================================
      [pipewire]
      volume_left=35
      volume_right=35
      # ============================================================================
      # UI Layout Settings
      # ============================================================================
      [qtui]
      column_widths=25,25,275,175,50,175,175,25,100,28,75,275,275,275,75,275,175
      menu_visible=FALSE
      player_height=581
      player_width=941
      playlist_headers=FALSE
      playlist_headers_bold=TRUE
    '';
  };
}
