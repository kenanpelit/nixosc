# modules/core/packages/default.nix
{ pkgs, ... }:
let
  # Python ortamı, ipython ve libtmux paketlerini içeren bir Python ortamı tanımlanıyor
  pythonWithLibtmux = pkgs.python3.withPackages (ps: with ps; [
    ipython
    libtmux
  ]);
in
{
  # Sistem genelinde kurulu olacak paketler listesi
  environment.systemPackages = with pkgs; [
    # Temel Sistem Araçları
    home-manager     # Kullanıcı ortamı yönetimi için home-manager CLI aracı
    catppuccin-grub
    blueman          # Bluetooth yönetimi için Blueman
    dconf            # Gnome yapılandırmalarını yönetmek için dconf
    dconf-editor     # Dconf editörü
    libnotify        # Bildirim desteği
    poweralertd      # Güç yönetimi araçları
    xdg-utils        # X11 masaüstü ortamı için araçlar
    gzip             # Veri sıkıştırma aracı
    gcc              # C derleyicisi
    gnumake          # Make komut dosyası aracı
    coreutils        # Temel sistem yardımcı programları
    libinput         # Giriş cihazları için kütüphane
    fusuma           # Dokunmatik hareket yönetimi
    touchegg         # Multi-touch hareket desteği

    # Terminal ve Shell Araçları
    curl             # URL verisi almak için kullanılan araç
    wget             # Dosya indirme aracı
    tmux             # Terminal çoklu oturum yöneticisi
    man-pages        # Manuel sayfalar
    socat            # Veri aktarımı için kullanılan araç

    # Python Ekosistemi
    pythonWithLibtmux # Özelleştirilmiş Python ortamı (ipython ve libtmux)

    # Sistem İzleme Araçları
    htop             # Sistemdeki kaynak kullanımını gösterir
    powertop         # Güç tüketimi izleme aracı
    sysstat          # Sistem istatistikleri
    procps           # Proses yönetim araçları

    # Ağ Yönetimi İçin Gerekli Paketler
    iptables         # Güvenlik duvarı yönetimi
    tcpdump          # Ağ trafiği analizi
    nethogs          # Ağ trafiği monitörü
    bind             # DNS araçları
    iwd              # Kablosuz ağ yönetimi
    impala           # TUI for managing wifi
    iwgtk            # iwgtk is a wireless networking GUI
    libnotify        # Masaüstü bildirimleri
    gawk             # Metin işleme
    iw               # Kablosuz araçları
    iftop            # Ağ bant genişliği monitörü
    mtr              # Ağ tanılama aracı
    nmap             # Ağ tarama aracı
    speedtest-cli    # İnternet hız testi
    iperf            # Ağ performans testi
    rsync            # Dosya senkronizasyon aracı

    # Güvenlik Araçları
    age              # Modern şifreleme aracı
    openssl          # Güvenli iletişim için SSL araçları
    sops             # Şifreli dosya yönetimi aracı

    # Geliştirme Araçları
    git              # Git sürüm kontrol aracı
    gdb              # Debugging aracı
    nvd              # Nix sürüm farklarını karşılaştırma aracı
    ncdu             # Disk kullanım analizi
    du-dust          # Modern disk kullanım analizi
    cachix           # Binary cache yönetimi
    nix-output-monitor # Nix derleme çıktılarının daha iyi izlenmesi

    # SSH ile İlgili Araçlar
    assh             # SSH anahtarlarını yönetme aracı
    openssh          # SSH istemcisi ve sunucusu

    # Sanallaştırma Araçları
    virt-manager     # Sanal makineleri yönetme aracı
    virt-viewer      # Sanal makineleri görsel olarak izleme aracı
    qemu             # Sanal makineler için donanım emülasyonu
    spice-gtk        # SPICE protokolü için GTK istemcisi
    win-virtio       # Windows için sanal cihaz sürücüler
    win-spice        # Windows için SPICE istemcisi
    swtpm            # Yazılım TPM (Trusted Platform Module) sanallaştırması
    podman           # Container yönetimi aracı

    # Güç Yönetimi Araçları
    upower           # Güç yönetimi CLI aracı
    acpi             # ACPI bilgilerini okuma aracı
    powertop         # Güç tüketimi izleme aracı

    # Masaüstü ve Portal Destek Paketleri
    flatpak          # Uygulama dağıtım aracı
    xdg-desktop-portal # Masaüstü portal desteği
    xdg-desktop-portal-gtk # GTK masaüstü portal desteği

    # MPD ile Alakalı Araçlar
    mpc-cli
    rmpc
    acl

    # Remote Desktop Araçları
    tigervnc

    gnupg 
    gcr
    gnome-keyring
    pinentry-gnome3
  ];
}

