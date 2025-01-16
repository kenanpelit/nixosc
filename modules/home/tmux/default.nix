# modules/home/tmux/default.nix
# ==============================================================================
# Tmux Terminal Multiplexer Configuration
# ==============================================================================
{ config, lib, pkgs, ... }:
with lib;
{
 # =============================================================================
 # Module Options
 # =============================================================================
 options.modules.tmux = {
   enable = lib.mkEnableOption "tmux configuration";
 };
 
 # =============================================================================
 # Module Implementation
 # =============================================================================
 config = lib.mkIf config.modules.tmux.enable {
   # ---------------------------------------------------------------------------
   # Required Packages
   # ---------------------------------------------------------------------------
   home.packages = with pkgs; [
     tmux      # Terminal multiplexer
     gnutar    # Archive handling
     gzip      # Compression
     coreutils # Core utilities
     yq-go     # YAML processor
   ];

   # ---------------------------------------------------------------------------
   # Configuration Extraction Service
   # ---------------------------------------------------------------------------
   systemd.user.services.extract-tmux-config = {
     Unit = {
       Description = "Extract tmux configuration";
       Requires = [ "sops-nix.service" ];
       After = [ "sops-nix.service" ];
     };
     
     Service = {
       Type = "oneshot";
       RemainAfterExit = true;
       ExecStart = let
         extractScript = pkgs.writeShellScript "extract-tmux-config" ''
           # Check for backup file
           if [ ! -f "/home/${config.home.username}/.backup/tmux.tar.gz" ]; then
             echo "Tar dosyası henüz hazır değil..."
             exit 1
           fi
           
           echo "Temizleniyor..."
           rm -rf $HOME/.config/tmux $HOME/.config/oh-my-tmux
           
           echo "Dizinler oluşturuluyor..."
           mkdir -p $HOME/.config/tmux $HOME/.config/oh-my-tmux
           
           echo "Tar dosyası açılıyor..."
           ${pkgs.gnutar}/bin/tar --no-same-owner -xzf /home/${config.home.username}/.backup/tmux.tar.gz -C $HOME/.config/
         '';
       in "${extractScript}";
     };
     
     Install = {
       WantedBy = [ "default.target" ];
     };
   };
 };
}
