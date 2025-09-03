# modules/core/sops/default.nix
# ==============================================================================
# SOPS (Secrets OPerationS) — Sistem Seviyesi Parola/Sır Yönetimi
# ==============================================================================
# NİYET (Ne ve Neden?):
# - Makine üzerinde *şifrelenmiş* sır dosyalarını güvenle versiyonlamak
#   (git’te tutmak) ve NixOS aktivasyonunda *şeffaf* şekilde çözmek.
# - Nix ekosistemine doğal entegre (sops-nix modülü) bir akış sağlamak.
#
# TASARIM:
# - Şifreleme mekanizması olarak **age** kullanıyoruz (GPG yok).
# - Varsayılan SOPS dosyası: `~/.nixosc/secrets/wireless-secrets.enc.yaml`
# - Age anahtarı:          `~/.config/sops/age/keys.txt`
# - NetworkManager gibi servislerin ihtiyaç duyduğu sırları **system-level**
#   nesnelere indiriyoruz (owner/grup/mode doğru ayarlanır).
# - Build safhasında “dosya yok” hatalarına düşmemek için **validate kapalı**;
#   dizin ve dosya varlığı aktivasyon anında kontrol edilir.
#
# ÖN KOŞUL (tek seferlik):
#   $ mkdir -p ~/.config/sops/age
#   $ age-keygen -o ~/.config/sops/age/keys.txt
#   (Public key’i .sops.yaml’da kullan; repo’deki .sops.yaml zaten ayarlıysa dokunma)
#
# DİKKAT:
# - `builtins.pathExists` çalışma makinesinin dosya sistemine bakar.
#   Sair sistemlerde repo farklı kullanıcı altında uygulanıyorsa path’leri
#   host’a göre güncellemen gerekir.
# - Burada sadece **kablosuz ağ parolaları** şifrelenmiş örnek olarak ele alındı.
#   SOPS nesnelerine **başka sırları** da rahatça ekleyebilirsin (SSH, API key vs.).
#
# Author: Kenan Pelit
# Last updated: 2025-09-03
# ==============================================================================

{ config, lib, pkgs, inputs, username, ... }:

{
  # ============================================================================
  # Modül import’u — sops-nix NixOS modülü
  # ============================================================================
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # ============================================================================
  # SOPS Global Yapılandırması
  # ============================================================================
  sops = {
    # Varsayılan SOPS dosyası (tek dosyada çok anahtar saklayabilirsin)
    defaultSopsFile = "/home/${username}/.nixosc/secrets/wireless-secrets.enc.yaml";

    # GPG yerine age kullanıyoruz; age key dosyasının yolu:
    age.keyFile = "/home/${username}/.config/sops/age/keys.txt";

    # Build anında şifreli dosyanın *varlığını* doğrulama (false = daha esnek)
    # NEDEN: İlk kurulumda dosyalar henüz yokken build başarısız olmasın.
    validateSopsFiles = false;

    # GPG kullanılmadığı için ek SSH anahtar yolu tanımlamıyoruz
    gnupg.sshKeyPaths = [ ];

    # --------------------------------------------------------------------------
    # System-level secrets
    # --------------------------------------------------------------------------
    # NOT: `mkIf (pathExists …)` ile sır dosyası yoksa bu blok tamamen devre dışı kalır.
    # Böylece “ilk kurulumda” dosya yoksa build kırılmaz.
    secrets = lib.mkIf (builtins.pathExists /home/${username}/.nixosc/secrets/wireless-secrets.enc.yaml) {

      # ÖRNEK 1 — Ken_5 SSID parolası
      # - “key” alanı şifreli YAML dosyasındaki yol/anahtardır.
      # - NM servis grubuna veriyoruz ki sadece NetworkManager erişsin.
      "wireless_ken_5_password" = {
        sopsFile = "/home/${username}/.nixosc/secrets/wireless-secrets.enc.yaml";
        key      = "ken_5_password";
        owner    = "root";
        group    = "networkmanager";
        mode     = "0640";
        # Sır değişirse NM’yi yeniden başlat (aktif ilişkili servisi tazelemek için)
        restartUnits = [ "NetworkManager.service" ];
      };

      # ÖRNEK 2 — Ken_2_4 SSID parolası
      "wireless_ken_2_4_password" = {
        sopsFile = "/home/${username}/.nixosc/secrets/wireless-secrets.enc.yaml";
        key      = "ken_2_4_password";
        owner    = "root";
        group    = "networkmanager";
        mode     = "0640";
        restartUnits = [ "NetworkManager.service" ];
      };

      # İPUCU:
      # - Başka sır eklerken: key adını şifreli YAML içindeki hiyerarşine göre ver.
      # - İlgili servisi restartUnits ile bağlarsan değişiklikler atomik olur.
    };
  };

  # ============================================================================
  # Dizin Yapısı ve İzinler — İlk kurulum dostu
  # ============================================================================
  # Aktivasyon sırasında gerekli dizinlerin var olduğundan emin ol, izinleri düzelt.
  systemd.tmpfiles.rules = [
    "d /home/${username}/.nixosc 0755 ${username} users -"
    "d /home/${username}/.nixosc/secrets 0750 ${username} users -"
    "d /home/${username}/.config 0755 ${username} users -"
    "d /home/${username}/.config/sops 0750 ${username} users -"
    "d /home/${username}/.config/sops/age 0700 ${username} users -"
  ];

  # ============================================================================
  # Yardımcı Paketler — age ve sops CLI’ları sistemde bulunsun
  # ============================================================================
  environment.systemPackages = with pkgs; [
    age
    sops
  ];

  # ============================================================================
  # Sistem Servisi — Aktivasyon esnasında yönlendirici kontroller
  # ============================================================================
  # Not: sops-nix kendi aktivasyonunu zaten yapar; bu servis “rehber/diagnostic”
  # amaçlıdır. Anahtar/dizin varlığı ile ilgili *yardımcı uyarılar* üretir.
  systemd.services.sops-nix = {
    description = "SOPS secrets activation (system helper)";
    wantedBy = [ "multi-user.target" ];
    after    = [ "local-fs.target" ];

    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      User            = "root";
      Group           = "root";
    };

    script = ''
      # Dizinleri garanti altına al
      mkdir -p /home/${username}/.config/sops/age
      chown ${username}:users /home/${username}/.config/sops/age
      chmod 700 /home/${username}/.config/sops/age

      # Age anahtarı var mı?
      if [ ! -f "/home/${username}/.config/sops/age/keys.txt" ]; then
        echo "[SOPS] Age key not found at ~/.config/sops/age/keys.txt"
        echo "[SOPS] Generate one:  age-keygen -o ~/.config/sops/age/keys.txt"
      else
        echo "[SOPS] Age key found — system-level SOPS ready."
      fi
    '';
  };

  # ============================================================================
  # Kullanıcı Servisi — Home-Manager bağımlılıkları için “hazır” sinyali
  # ============================================================================
  # NEDEN: Bazı HM servislerini sırların hazır olmasına bağlamak isteyebilirsin.
  # Bu küçük user-service basit bir “ready” sinyali üretir (opsiyonel).
  systemd.user.services.sops-nix = {
    description = "SOPS secrets activation (user-level helper)";
    wantedBy = [ "default.target" ];
    after    = [ "graphical-session.target" ];

    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      mkdir -p /home/${username}/.config/sops/age

      if [ -f "/home/${username}/.config/sops/age/keys.txt" ]; then
        echo "[SOPS][user] Age key present — user-level SOPS ready."
      else
        echo "[SOPS][user] Warning: no age key at ~/.config/sops/age/keys.txt"
      fi

      # HM tarafında istersen bu dosyaya PartOf/Requires ile bağlanabilirsin
      touch /tmp/sops-user-ready
    '';
  };
}


