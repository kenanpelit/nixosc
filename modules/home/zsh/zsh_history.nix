# modules/home/zsh/zsh_history
# ==============================================================================
# ZSH History Management
# Author: Kenan Pelit
# Description: History file configuration and example command management
# ==============================================================================
{ config, lib, pkgs, ... }:

let
  hmLib = lib.hm or config.lib;
  dag = hmLib.dag or config.lib.dag;
  # History file paths
  historyFile = "${config.home.homeDirectory}/.config/zsh/history";
  exampleHistory = ./history;

  # User info
  user = config.home.username;
  group = "users";
in
{
  home.activation = {
    # =============================================================================
    # History File Management
    # =============================================================================
    appendZshHistory = dag.entryAfter ["writeBoundary"] ''
      # Ensure proper file permissions
      $DRY_RUN_CMD install -m 644 -o ${user} -g ${group} /dev/null "${historyFile}" 2>/dev/null || true
      
      # Ensure directory exists with correct permissions
      $DRY_RUN_CMD mkdir -p "$(dirname "${historyFile}")"
      $DRY_RUN_CMD chmod 755 "$(dirname "${historyFile}")"
      
      # Append new commands from example history
      while IFS= read -r cmd; do
        # Skip empty lines and comments
        [[ -z "$cmd" || "$cmd" =~ ^[[:space:]]*# ]] && continue
        
        # Check if command already exists in history
        if ! grep -Fxq "$cmd" "${historyFile}" 2>/dev/null; then
          # Append non-duplicate command
          echo "$cmd" >> "${historyFile}"
        fi
      done < "${exampleHistory}"
      
      # Final permission check
      $DRY_RUN_CMD chmod 644 "${historyFile}"
      $DRY_RUN_CMD chown ${user}:${group} "${historyFile}"
    '';
  };
}
