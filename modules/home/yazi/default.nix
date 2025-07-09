# modules/home/yazi/default.nix
# ==============================================================================
# Yazi File Manager Configuration
# ==============================================================================
{ inputs, pkgs, ... }:
{
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
}
