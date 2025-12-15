# modules/home/yazi/default.nix
# ==============================================================================
# Home module for Yazi TUI file manager.
# Installs yazi and writes user config/theme via Home Manager.
# Keep yazi tweaks here instead of editing config manually.
# ==============================================================================

{ inputs, pkgs, lib, config, ... }:
let
  cfg = config.my.user.yazi;
in
{
  options.my.user.yazi = {
    enable = lib.mkEnableOption "Yazi file manager";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Program Configuration
    # =============================================================================
    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
      
      # ---------------------------------------------------------------------------
      # Manager Settings
      # ---------------------------------------------------------------------------
      settings = {
        mgr = {
          ratio = [1 3 4];
          linemode = "size";
          show_hidden = true;
          show_symlink = true;
          sort_by = "natural";
          sort_dir_first = true;
          sort_reverse = false;
          sort_sensitive = false;
        };
      };
      
      # ---------------------------------------------------------------------------
      # Plugin Configuration
      # ---------------------------------------------------------------------------
      plugins = {
        full-border = "${inputs.yazi-plugins}/full-border.yazi";
      };
    };
    
    # =============================================================================
    # Additional Configuration
    # =============================================================================
    xdg.configFile."yazi/init.lua".text = ''
      require("full-border"):setup()
    '';
  };
}
