# modules/home/security/sops/default.nix
# SOPS (Secrets OPerationS) Configuration for Home Manager
# Manages encrypted secrets and secure file deployments
# ==============================================================================
{ username, inputs, ... }:
{
 # =============================================================================
 # Import SOPS Home Manager Module
 # Required for secrets management functionality
 # =============================================================================
 imports = [
   inputs.sops-nix.homeManagerModules.sops
 ];
 
 # =============================================================================
 # Core SOPS Configuration 
 # Defines default secret location and age key settings
 # =============================================================================
 sops = {
   # Default encrypted secrets file location
   defaultSopsFile = ./../../../../secrets/home-secrets.enc.yaml;
   # Age private key location for decryption
   age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
   # Disable strict file validation
   validateSopsFiles = false;
   # ---------------------------------------------------------------------------
   # Secrets Configuration
   # Defines individual secret files, their target paths and permissions
   # ---------------------------------------------------------------------------
   secrets = {
     # GitHub access token
     "github_token" = {
       path = "/home/${username}/.config/github/token";
     };
     # Nix configuration file
     "nix_conf" = {
       path = "/home/${username}/.config/nix/nix.conf";
       mode = "0600";
     };
     # GitHub Gist access token
     "gist_token" = {
       path = "/home/${username}/.gist";
       mode = "0600";
     };
     ## Subliminal subtitle downloader config
     #"subliminal_config" = {
     #  sopsFile = ./../../../../secrets/subliminal.enc.toml;
     #  mode = "0600";
     #  path = "/home/${username}/.config/subliminal/subliminal.toml";
     #};
     # Tmux configuration backup
     "tmux_backup_archive" = {
       path = "/home/${username}/.backup/tmux.tar.gz";
       mode = "0600";
       format = "binary";
       sopsFile = ./../../../../assets/tmux.enc.tar.gz;
     };
     # Oh-my-tmux configuration backup
     "oh-my-tmux_backup_archive" = {
       path = "/home/${username}/.backup/oh-my-tmux.tar.gz";
       mode = "0600";
       format = "binary";
       sopsFile = ./../../../../assets/oh-my-tmux.enc.tar.gz;
     };
     # MPV media player backup
     "mpv_backup_archive" = {
       path = "/home/${username}/.backup/mpv.tar.gz";
       mode = "0600";
       format = "binary";
       sopsFile = ./../../../../assets/mpv.enc.tar.gz;
     };
     # Dotfiles backup archive (currently disabled)
     # "dot_backup_archive" = {
     #   path = "/home/${username}/.backup/dot.tar.gz";
     #   mode = "0600";
     #   format = "binary";
     #   sopsFile = "/home/${username}/.nixosc/assets/dot.enc.tar.gz";
     # };
     
     # Ken_5 ağı parolası
     "wireless_ken_5_password" = {
       sopsFile = ./../../../../secrets/wireless-secrets.enc.yaml;
       key = "ken_5_password";
       # NetworkManager'ın erişebilmesi için
       owner = "root";
       group = "networkmanager";
       mode = "0640";
     };
     # Ken_2_4 ağı parolası
     "wireless_ken_2_4_password" = {
       sopsFile = ./../../../../secrets/wireless-secrets.enc.yaml;
       key = "ken_2_4_password";
       owner = "root";
       group = "networkmanager";
       mode = "0640";
     };
   };
 };
}

