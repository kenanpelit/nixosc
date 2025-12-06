# modules/home/waypaper/default.nix
# ==============================================================================
# Waypaper Wallpaper Manager Configuration
# ==============================================================================
{ pkgs, config, lib, ... }:
let
  cfg = config.my.user.waypaper;
in
lib.mkIf cfg.enable {
  # =============================================================================
  # Configuration
  # =============================================================================
  xdg.configFile."waypaper/config.ini".text = ''
    [Settings]
    # Basic Settings
    language = en
    folder = ~/Pictures/wallpapers/others
    monitors = All
    wallpaper = ~/Pictures/wallpapers/nixos/nixos.png
    
    # Display Settings
    backend = swww
    fill = fill
    sort = name
    color = #ffffff
    
    # Folder Settings
    subfolders = False
    show_hidden = False
    show_gifs_only = False
    
    # UI Settings
    number_of_columns = 3
    
    # SWWW Settings
    swww_transition_type = any
    swww_transition_step = 90
    swww_transition_angle = 0
    swww_transition_duration = 2
    swww_transition_fps = 60
    
    # Additional Settings
    post_command = pkill .waypaper-wrapp
    use_xdg_state = False
  '';
}
