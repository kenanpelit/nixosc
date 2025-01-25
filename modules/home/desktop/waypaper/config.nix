# modules/home/desktop/waypaper/default.nix
# ==============================================================================
# Waypaper Wallpaper Manager Configuration
# ==============================================================================
{ pkgs, ... }:
{
 # =============================================================================
 # Package Installation
 # =============================================================================
 home.packages = (with pkgs; [ waypaper ]);
 
 # =============================================================================
 # Configuration
 # =============================================================================
 xdg.configFile."waypaper/config.ini".text = ''
   [Settings]
   # Monitor Settings
   language = en
   folder_eDP-1 = ~/Pictures/wallpapers/others
   folder_DP-5 = ~/Pictures/wallpapers/others
   monitors = Specific
   
   # Display Settings
   backend = swww
   fill = fill
   sort = random
   color = #ffffff
   
   # Dynamic Wallpaper Settings
   change_mode = time
   change_time = 5
   
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
