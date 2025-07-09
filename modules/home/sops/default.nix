# modules/home/sops/default.nix
# SOPS (Secrets OPerationS) Configuration for Home Manager
# ==============================================================================
{ username, inputs, config, lib, pkgs, ... }:
{
  # =============================================================================
  # Import SOPS Home Manager Module
  # =============================================================================
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];
  
  # =============================================================================
  # Core SOPS Configuration 
  # =============================================================================
  sops = {
    # Default encrypted secrets file location
    defaultSopsFile = /home/${username}/.nixosc/secrets/home-secrets.enc.yaml;
    
    # Age private key location for decryption
    age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
    
    # Disable strict file validation
    validateSopsFiles = false;
    
    # SOPS servisini zorla aktifleştir
    gnupg.sshKeyPaths = [];  # GPG kullanmıyoruz, sadece age
    
    # ---------------------------------------------------------------------------
    # Secrets Configuration - Sadece temel secrets ile test
    # ---------------------------------------------------------------------------
    secrets = {
      # Sadece temel GitHub token ile test edelim
      "github_token" = lib.mkIf (builtins.pathExists /home/${username}/.nixosc/secrets/home-secrets.enc.yaml) {
        path = "${config.home.homeDirectory}/.config/github/token";
        mode = "0600";
      };
      
      # Binary secrets - sadece varsa ekle
      "tmux_backup_archive" = lib.mkIf (builtins.pathExists /home/${username}/.nixosc/assets/tmux.enc.tar.gz) {
        path = "${config.home.homeDirectory}/.backup/tmux.tar.gz";
        mode = "0600";
        format = "binary";
        sopsFile = /home/${username}/.nixosc/assets/tmux.enc.tar.gz;
      };
      
      "oh-my-tmux_backup_archive" = lib.mkIf (builtins.pathExists /home/${username}/.nixosc/assets/oh-my-tmux.enc.tar.gz) {
        path = "${config.home.homeDirectory}/.backup/oh-my-tmux.tar.gz";
        mode = "0600";
        format = "binary";
        sopsFile = /home/${username}/.nixosc/assets/oh-my-tmux.enc.tar.gz;
      };
      
      "mpv_backup_archive" = lib.mkIf (builtins.pathExists /home/${username}/.nixosc/assets/mpv.enc.tar.gz) {
        path = "${config.home.homeDirectory}/.backup/mpv.tar.gz";
        mode = "0600";
        format = "binary";
        sopsFile = /home/${username}/.nixosc/assets/mpv.enc.tar.gz;
      };
    };
  };
  
  # Debug için SOPS servisini manuel tanımla
  systemd.user.services.sops-nix = lib.mkForce {
    Unit = {
      Description = "SOPS secrets installation";
      Before = [ "default.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScript "sops-install" ''
        echo "SOPS servisi çalışıyor..."
        # Age key dosyasının varlığını kontrol et
        if [ ! -f "/home/${username}/.config/sops/age/keys.txt" ]; then
          echo "Age key dosyası bulunamadı!"
          exit 1
        fi
        echo "SOPS servisi başarıyla tamamlandı."
      ''}";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}

