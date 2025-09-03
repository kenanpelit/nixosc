# modules/core/security/default.nix
# ==============================================================================
# AMAÇ:
# - Güvenlik ile ilgili *her şeyi* tek dosyada toplamak: Firewall, PAM/Polkit,
#   AppArmor, Audit, SSH, Transmission portları **ve** hBlock (domain engelleme).
# - Yönetilebilirlik: “Açık port nerede?” → **Burada**. “iptables sertleştirme?”
#   → **Burada**. “Kullanıcı bazlı host alias (hBlock)?” → **Burada**.
#
# TASARIM İLKELERİ:
# 1) **Tek otorite**: Firewall portları başka modüllerde tekrar _tanımlanmaz_.
# 2) **İptables muhafazası**: nftables varsayılan olsa da, senin stabilize ettiğin
#    iptables kurallarını *bilinçli olarak* koruyoruz.
# 3) **Koşullu kurallar**: Mullvad/WireGuard gibi tüneller `systemd` durumu ile
#    koşullu kabul edilir; açık değilse sessiz geçilir.
# 4) **hBlock entegre**: Kullanıcı başına `~/.config/hblock/hosts` yazılır,
#    `$HOSTALIASES` skel’e eklenir; böylece `ssh foo` gibi komutlarda alias çözümü
#    ek “/etc/hosts” kirletmeden kullanıcı-yerel çalışır.
#
# DEĞİŞTİRİLEBİLİR ALANLAR:
# - Aşağıdaki `let` bloğunda Transmission portlarını tek yerden düzenleyin.
# - hBlock’u açmak için `services.hblock.enable = true;` yeterlidir.
#
# Author: Kenan Pelit
# Last merged: 2025-09-03
# ==============================================================================

{ lib, pkgs, config, ... }:

let
  inherit (lib) mkEnableOption mkIf mkAfter;

  # ----------------------------- Ayarlanabilirler -----------------------------
  # Transmission Web UI portu (varsayılan: 9091)
  transmissionWebPort = 9091;

  # Transmission peer portu (TCP/UDP; varsayılan: 51413)
  transmissionPeerPort = 51413;

  # hBlock update script — orijinal mantık korunarak taşındı.
  # NEDEN BU YAPI?
  # - /etc/hosts’ı globale bozmadan kullanıcı-bazlı alias dosyası üretir.
  # - $HOSTALIASES ile bash/glibc resolver, hosts aliaslarını otomatik kullanır.
  # - Günlük timer ile listeler taze kalır.
  hblockUpdateScript = pkgs.writeShellScript "hblock-update" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    for USER_HOME in /home/*; do
      if [ -d "$USER_HOME" ]; then
        USER=$(basename "$USER_HOME")
        CONFIG_DIR="$USER_HOME/.config/hblock"
        HOSTS_FILE="$CONFIG_DIR/hosts"
        mkdir -p "$CONFIG_DIR"
        {
          echo "# Base entries"
          echo "localhost 127.0.0.1"
          echo "hay 127.0.0.2"
          echo "# hBlock entries (Updated: $(date))"
          # hblock çıktısından alan adı yakala → iki sütunlu alias satırı yaz
          ${pkgs.hblock}/bin/hblock -O - | while read DOMAIN; do
            if [[ $DOMAIN =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+(.+)$ ]]; then
              echo "''${BASH_REMATCH[1]} ''${BASH_REMATCH[1]}"
            fi
          done
        } > "$HOSTS_FILE"
        chown "$USER:users" "$HOSTS_FILE"
        chmod 644 "$HOSTS_FILE"
      fi
    done
  '';
in
{
  # =============================================================================
  # hBlock opsiyonu (toggle)
  # =============================================================================
  options.services.hblock.enable = mkEnableOption
    "hBlock per-user HOSTALIASES + daily auto-update (keeps /etc/hosts clean)";

  # =============================================================================
  # Asıl yapılandırma
  # =============================================================================
  config = {
    # ===========================================================================
    # Network Security — Firewall (TEK OTORİTE)
    # ===========================================================================
    networking.firewall = {
      enable = true;

      # Ping kapalı — aktif keşfe karşı yüzey alanı azaltımı
      allowPing = false;

      # Fail-closed yaklaşımı ve asimetrik routing esnekliği
      rejectPackets = true;
      logReversePathDrops = true;
      checkReversePath = "loose";

      # Tünelleri güvenilir say (WireGuard/OpenVPN): wg*, tun*
      trustedInterfaces = [ "wg+" "tun+" ];

      # -------------------------- Açık TCP/UDP portları ------------------------
      # NOT: Portları yalnızca burada yönetin (başka modüllerde tekrar etmeyin).
      allowedTCPPorts = [
        53                    # DNS (lokal resolver veya captive portal durumları)
        1401                  # Senin özel servis
        transmissionWebPort   # Transmission Web UI
      ];

      allowedUDPPorts = [
        53                    # DNS
        1194 1195 1196        # OpenVPN örnek portları
        1401                  # Özel servis
        51820                 # WireGuard
      ];

      # Transmission peer portu (TCP/UDP tek port aralığı)
      allowedTCPPortRanges = [{ from = transmissionPeerPort; to = transmissionPeerPort; }];
      allowedUDPPortRanges = [{ from = transmissionPeerPort; to = transmissionPeerPort; }];

      # -------------------------- Ek iptables kuralları ------------------------
      # NEDEN iptables? Mevcut kurulumun *çalıştığı kanıtlı* ve stabilize;
      # nftables’a geçiş ayrı bir çalışma gerektirir. Şimdilik “dokunma”.
      extraCommands = ''
        # Default Policies — fail-closed
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT ACCEPT

        # Temel izinler
        iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        iptables -A INPUT -i lo -j ACCEPT

        # Basit DoS azaltımı
        iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
        # Eşzamanlı bağlantı üst limiti (15 üzeri reddet)
        iptables -A INPUT -p tcp --syn -m connlimit --connlimit-above 15 -j REJECT

        # Port tarama anomalilerini düşür
        iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
        iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
        iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
        iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

        # ICMP rate limit (ping flood’a karşı)
        iptables -A INPUT -p icmp -m limit --limit 1/s --limit-burst 1 -j ACCEPT

        # Mullvad aktifse tünel arayüzlerine izin ver + DNS
        if systemctl is-active mullvad-daemon; then
          iptables -A OUTPUT -o wg0-mullvad -j ACCEPT
          iptables -A INPUT  -i wg0-mullvad -j ACCEPT
          iptables -A OUTPUT -o tun0 -j ACCEPT
          iptables -A INPUT  -i tun0 -j ACCEPT
          iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
          iptables -A INPUT  -p udp --sport 53 -j ACCEPT
        fi
      '';
    };

    # ===========================================================================
    # System Security (Servisler, AppArmor, Audit, Kernel Koruması)
    # ===========================================================================
    security = {
      # Ses yığını (PipeWire) ve düşük gecikme için rtkit
      rtkit.enable = true;

      # Yetki yükseltme ve grafik yetkilendirme
      sudo.enable = true;
      polkit.enable = true;

      # Zorlayıcı profil setleri
      apparmor = {
        enable = true;
        packages = with pkgs; [ apparmor-profiles apparmor-utils ];
      };

      # Olay kaydı
      auditd.enable = true;

      # Kernel sertleştirme
      allowUserNamespaces = true;
      protectKernelImage = true;

      # PAM: GNOME Keyring ile entegrasyon
      pam.services = {
        login.enableGnomeKeyring = true;
        swaylock.enableGnomeKeyring = true;  # Sway
        hyprlock.enableGnomeKeyring = true;  # Hyprland
        sudo.enableGnomeKeyring = true;
        polkit-1.enableGnomeKeyring = true;
      };
    };

    # ===========================================================================
    # SSH (İstemci)
    # ===========================================================================
    programs.ssh = {
      # GPG agent kullandığın için ssh-agent başlatma
      startAgent = false;
      # GUI password prompt kapalı (terminal üzerinden)
      enableAskPassword = false;

      extraConfig = ''
        Host *
          ServerAliveInterval 60
          ServerAliveCountMax 2
          TCPKeepAlive yes
          # assh proxy (isteğe bağlı)
          ProxyCommand ${pkgs.assh}/bin/assh connect --port=%p %h
      '';
    };

    # ===========================================================================
    # hBlock Entegrasyonu (enable olduğunda aktifleşir)
    # ===========================================================================
    environment = {
      # skel’e HOSTALIASES ekleyerek yeni kullanıcılar için varsayılan davranışı sağlar
      etc."skel/.bashrc".text = mkAfter ''
        export HOSTALIASES="$HOME/.config/hblock/hosts"
      '';

      # Sistem araçları
      systemPackages = with pkgs; [
        polkit_gnome  # GNOME PolicyKit agent (grafik diyaloglar)
        assh          # Gelişmiş SSH config yöneticisi
        hblock        # hBlock CLI — update script bunu çağırır
      ];

      # Kısayollar
      shellAliases = {
        assh      = "${pkgs.assh}/bin/assh";
        sshconfig = "${pkgs.assh}/bin/assh config build > ~/.ssh/config";
        sshtest   = "ssh -o ConnectTimeout=5 -o BatchMode=yes";
        # hBlock’u manuel tetiklemek için:
        hblock-update-now = "${hblockUpdateScript}";
      };

      # Ortam değişkenleri
      variables = {
        ASSH_CONFIG = "$HOME/.ssh/assh.yml";
      };
    };

    # hBlock servis & timer — sadece enable=true iken kurulsun
    systemd = mkIf config.services.hblock.enable {
      services.hblock = {
        description = "hBlock - Update user hosts files";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = hblockUpdateScript;
          RemainAfterExit = true;
        };
      };
      timers.hblock = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";        # Günlük güncelle
          RandomizedDelaySec = 3600;   # 0-3600 sn gecikme (burst önleme)
          Persistent = true;           # missed runs telafi
        };
      };
    };
  };

  # =============================================================================
  # İPUÇLARI
  # =============================================================================
  # - Transmission portlarını değiştirmek için yukarıdaki let’teki
  #   `transmissionWebPort` ve `transmissionPeerPort`’u güncelleyin.
  # - Firewall portlarını başka modüllerde TANIMLAMAYIN (çakışma riski).
  # - hBlock kapatmak için: `services.hblock.enable = false;`
  # - Mullvad/WireGuard arayüz adlarınız farklıysa (wg0-mullvad/tun0), iptables
  #   kurallarındaki isimleri uygun şekilde değiştirin.
}
