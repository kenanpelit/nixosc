# modules/home/zotfiles/default.nix
# ==============================================================================
# Dotfiles Management Module - Encrypted Configuration Files Handler
# ==============================================================================
{ config, lib, pkgs, ... }:
with lib;
{
  # =============================================================================
  # Core Module Configuration Options
  # =============================================================================
  options.modules.zotfiles = {
    enable = lib.mkEnableOption "Encrypted dotfiles extraction and management";
  };
  
  # =============================================================================
  # Module Implementation Details
  # =============================================================================
  config = lib.mkIf config.modules.zotfiles.enable {
    # ---------------------------------------------------------------------------
    # Automated Extraction Service Configuration
    # ---------------------------------------------------------------------------
    systemd.user.services.extract-dotfiles = {
      Unit = {
        Description = "Automated encrypted dotfiles extraction service";
        # Ensure SOPS decryption is available before starting
        Requires = [ "sops-nix.service" ];
        After = [ "sops-nix.service" ];
      };
      
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = let
          # Shell script for handling the extraction process
          extractScript = pkgs.writeShellScript "extract-dotfiles" ''
            # Path to the encrypted dotfiles archive
            DOTFILES_PATH="/home/${config.home.username}/.nixosc/hay/dotfiles.enc.tar.gz"
            
            # Verify encrypted archive exists
            if [ ! -f "$DOTFILES_PATH" ]; then
              echo "[ERROR] Encrypted dotfiles archive not found at: $DOTFILES_PATH"
              exit 1
            fi
            
            echo "[INFO] Beginning extraction of encrypted dotfiles..."
            ${pkgs.gnutar}/bin/tar --no-same-owner -xzf "$DOTFILES_PATH" -C $HOME
            
            # Verify extraction success
            if [ $? -eq 0 ]; then
              echo "[SUCCESS] Dotfiles successfully extracted to home directory"
            else
              echo "[ERROR] Failed to extract dotfiles - check permissions and file integrity"
              exit 1
            fi
          '';
        in "${extractScript}";
      };
      
      # ---------------------------------------------------------------------------
      # Service Installation Configuration
      # ---------------------------------------------------------------------------
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
