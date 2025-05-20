# modules/core/user/packages/default.nix
# ==============================================================================
# System Core Packages Configuration
# ==============================================================================
#
# Sistem seviyesinde gerekli temel paketlerin yapılandırması:
# - Sistem yönetimi ve temel araçlar
# - Sistem güvenliği ve servisler
# - Donanım ve sürücü yönetimi
# - Ağ altyapısı ve güvenliği
# - Sanallaştırma ve container
# - Sistem entegrasyonu
#
# Bu paketler sistem genelinde kurulur ve tüm kullanıcılar tarafından erişilebilir.
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, ... }:

let
 # ==============================================================================
 # Python Ortam Yapılandırması
 # ==============================================================================
 customPython = pkgs.python3.withPackages (ps: with ps; [
   ipython        # Gelişmiş Python shell
   libtmux        # Tmux için Python API
   pip            # Paket yükleyici
   pipx           # İzole ortam yükleyici
   subliminal
 ]);
in
{
 environment.systemPackages = with pkgs; [
   # ==============================================================================
   # Temel Sistem Araçları
   # ==============================================================================
   home-manager        # Kullanıcı ortam yönetimi
   catppuccin-grub    # GRUB teması
   dconf              # Yapılandırma sistemi
   dconf-editor       # dconf editörü
   libnotify          # Masaüstü bildirim
   poweralertd        # Güç yönetimi bildirimleri
   xdg-utils          # Masaüstü entegrasyonu
   gzip               # Sıkıştırma
   gcc                # GNU derleyici
   gnumake            # İnşa otomasyon
   coreutils          # GNU temel araçları
   libinput           # Giriş aygıtı yönetimi
   fusuma             # Çoklu dokunma
   touchegg           # Hareket tanıma
   procps             # Süreç izleme
   sysstat            # Sistem performans
   acl                # Erişim kontrol
   lsb-release        # Dağıtım bilgisi
   man-pages          # Sistem kılavuzları
   ventoy             # New bootable USB solution
   # Boot ve Sistem Temel Paketleri
   grub2                     # GRUB bootloader
   perl                      # Temel Perl kurulumu
   perlPackages.FilePath     # File::Path modülü (rmtree için)

   # ==============================================================================
   # Tmux ve Terminal Araçları
   # ==============================================================================
   tmux               # Terminal çoklayıcı
   gnutar             # Arşivleyici
   yq                 # YAML/JSON işlemci
   gawk               # Metin işleme

   # ==============================================================================
   # Sistem Güvenliği
   # ==============================================================================
   age                # Şifreleme
   openssl            # SSL/TLS araçları
   sops               # Gizli yönetimi
   hblock             # Reklam engelleyici
   gnupg              # GNU Privacy Guard
   gcr                # GNOME kriptografi
   gnome-keyring      # Parola yönetimi
   pinentry-gnome3    # PIN girişi

   # ==============================================================================
   # Ağ Altyapısı
   # ==============================================================================
   iptables           # Güvenlik duvarı
   tcpdump            # Paket analizi
   nethogs            # Bant genişliği izleme
   bind               # DNS araçları
   iwd                # Kablosuz daemon
   impala             # Ağ sorgu motoru
   #iwgtk              # Kablosuz yapılandırma
   networkmanagerapplet
   iw                 # Kablosuz araçları
   iftop              # Ağ kullanım izleme
   mtr                # Ağ teşhis
   nmap               # Ağ keşif
   speedtest-cli      # İnternet hız testi
   iperf              # Ağ performans
   rsync              # Dosya senkronizasyon
   curl               # URL veri transfer
   wget               # Ağ dosya indirme
   socat              # Çok amaçlı relay
   at                 # job scheduling command

   # ==============================================================================
   # Sanallaştırma ve Container
   # ==============================================================================
   virt-manager       # VM yönetim GUI
   virt-viewer        # VM görüntüleyici
   qemu               # Makine emülatörü
   spice-gtk          # Uzak görüntüleme
   win-virtio         # Windows sürücüleri
   win-spice          # Windows konuk araçları
   swtpm              # TPM emülatörü
   podman             # Container motoru
   
   # ==============================================================================
   # Güç Yönetimi
   # ==============================================================================
   upower             # Güç yönetim servisi
   acpi               # ACPI araçları
   powertop           # Güç izleme
   ddcutil            # Monitor settings
   fwupd

   # ==============================================================================
   # Sistem Entegrasyonu
   # ==============================================================================
   flatpak             # Uygulama sanal ortam
   xdg-desktop-portal  # Masaüstü entegrasyon
   xdg-desktop-portal-gtk # GTK arka uç
   libdrm              # Direct Rendering Manager library and headers

   # ==============================================================================
   # SSH ve Uzak Erişim
   # ==============================================================================
   assh                # SSH yapılandırma
   openssh             # SSH istemci/sunucu
   tigervnc            # VNC uygulaması

   # ==============================================================================
   # Temel Geliştirme Araçları
   # ==============================================================================
   git                 # Versiyon kontrol
   gdb                 # GNU hata ayıklayıcı
   nvd                 # Nix versiyon diff
   cachix              # İkili önbellek
   nix-output-monitor  # Nix inşa izleyici
   go                  # Go çalışma zamanı
   ollama              # LLM çalıştırıcı

   # ==============================================================================
   # Python Ortamı
   # ==============================================================================
   customPython        # Özel Python kurulumu
 ];
}

