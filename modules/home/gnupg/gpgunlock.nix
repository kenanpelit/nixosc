# modules/home/gnupg/gpgunlock.nix
# ==============================================================================
# GPG Auto-Unlock Service
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  # =============================================================================
  # Systemd Service Configuration
  # =============================================================================
  systemd.user.services.gpg-unlock = {
    Unit = {
      Description = "GPG Key Unlock Service";
      After = [ "graphical-session.target" "gpg-agent.service" ];
      PartOf = [ "graphical-session.target" ];
      Requires = [ "gpg-agent.service" ];
    };

    Service = {
      Type = "simple";
      Environment = "GNUPGHOME=%h/.gnupg";
      
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
      
      ExecStart = toString (pkgs.writeShellScript "gpg-agent-restart" ''
        # Mevcut agent'ı temizle ve yeniden başlat
        ${pkgs.gnupg}/bin/gpgconf --kill gpg-agent
        ${pkgs.gnupg}/bin/gpg-connect-agent /bye
        
        # Terminal ayarlarını güncelle
        ${pkgs.gnupg}/bin/gpg-connect-agent updatestartuptty /bye
        
        # Agent'ın hazır olduğunu kontrol et
        ${pkgs.gnupg}/bin/gpg-connect-agent "KILLAGENT" /bye
        ${pkgs.gnupg}/bin/gpg-connect-agent /bye
      '');

      # Hata durumunda yeniden başlatma ayarları
      Restart = "on-failure";
      RestartSec = "10s";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
