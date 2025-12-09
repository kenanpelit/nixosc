# modules/home/rsync/default.nix
# ------------------------------------------------------------------------------
# Home Manager module for rsync.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ------------------------------------------------------------------------------

{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.rsync;
in
{
  options.my.user.rsync = {
    enable = lib.mkEnableOption "Rsync configuration";
  };

  config = lib.mkIf cfg.enable {
    home.file.".rsync-homedir-excludes".text = ''
      # .rsync-homedir-excludes
      # This file contains patterns for excluding specific files and directories 
      # when backing up home directory using rsync
  
      # Temporary Files and Caches
      .cache/
      */.cache/
      .tmp/
      .temp/
      .thumbnails/
  
      # Browser Caches
      .config/google-chrome/Default/Cache/
      .config/chromium/Default/Cache/
      .config/Mozilla/Firefox/Profiles/*.default*/cache2/
      .config/Mozilla/Firefox/Profiles/*.default*/startupCache/
      .config/opera/Cache/
  
      # Package Manager Caches
      .npm/
      .yarn/cache/
      .gradle/
      .maven/
  
      # Development
      .venv/
      */__pycache__/
      *.pyc
      *.pyo
      *.pyd
      *.so
      *.o
      *.lo
      *.la
      node_modules/
      #.git/
      .svn/
      .hg/
  
      # Logs and Temporary Files
      *.log
      *.swp
      *~
      .bash_history
      .zsh_history
      .python_history
  
      # Downloads and Large Media (optional)
      Downloads/
      #Documents/
      Pictures/
      Music/
      Videos/
  
      # Application Data
      .steam/
      .wine/
      .local/share/Trash/
  
      # IDE and Editor Files
      .vscode/
      .idea/
      *.sublime-workspace
      *.sublime-project
  
      # Project Specific (customize as needed)
      Projects/temp/
      Projects/backup/
      Projects/*.bak
  
      # System Files
      .Trash/
      .Trash-*/
      .DS_Store
      Thumbs.db
    '';
  };
}
