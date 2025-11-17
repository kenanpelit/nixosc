# modules/home/packages/default.nix
# ==============================================================================
# User Home Packages Configuration
# ==============================================================================
#
# Kullanıcı seviyesinde paket yapılandırması:
# - Geliştirme araçları ve yardımcı programlar
# - Medya uygulamaları ve editörler
# - Terminal ve shell araçları
# - Masaüstü uygulamaları
# - Dosya yönetimi araçları
#
# Author: Kenan Pelit
# Updated: 2025-11-15
# ==============================================================================

{ inputs, pkgs, ... }:

let
  # Python Ortamı (Kullanıcı için)
  customPython = pkgs.python3.withPackages (ps: with ps; [
    ipython        # Gelişmiş Python shell
    libtmux        # Tmux için Python API
    pip            # Paket yükleyici
    pipx           # İzole ortam yükleyici
    #subliminal     # Altyazı indirici
  ]);
in
{
  home.packages = with pkgs; [
    # ==============================================================================
    # Dosya Yönetimi ve Navigasyon
    # ==============================================================================
    caligula      # Vim benzeri dosya yöneticisi
    duf           # Modern disk kullanım gösterici
    eza           # Modern ls alternatifi
    fd            # Hızlı dosya bulucu
    file          # Dosya türü tanımlayıcı
    gtrash        # GNOME çöp kutusu yönetimi
    lsd           # Renkli ls alternatifi
    ncdu          # İnteraktif disk kullanım analizi
    tree          # Dizin ağacı görüntüleyici
    trash-cli     # Çöp kutusu CLI
    unzip         # ZIP arşiv açıcı
    fdupes        # Yinelenen dosya bulucu
    czkawka       # Gelişmiş temizlik aracı GUI
    tdf           # Terminal dosya yöneticisi
    mlocate       # Hızlı dosya konumlandırıcı
    detox         # Dosya adı temizleyici
    atool         # Evrensel arşiv aracı
    p7zip         # 7-Zip sıkıştırma
    lftp          # FTP istemcisi
    scrcpy        # Android ekran yansıtma
    starship      # Minimal, blazing fast, and extremely customizable prompt for any shell

    # ==============================================================================
    # Geliştirme Araçları
    # ==============================================================================
    # Version Control
    git           # Versiyon kontrol sistemi
    lazygit       # Terminal Git GUI
    tig           # Git metin arayüzü
    
    # Language Servers & Formatters
    lua-language-server    # Lua LSP
    nixd                   # Nix LSP
    nixfmt-rfc-style       # Nix kod biçimlendirici
    nil                    # Nix dil araçları
    shellcheck            # Shell script analizi
    shfmt                 # Shell biçimlendirici
    stylua                # Lua biçimlendirici
    treefmt               # Çoklu dil biçimlendirici
    inputs.alejandra.defaultPackage.${pkgs.stdenv.hostPlatform.system} # Nix biçimlendirici
    
    # Binary Analysis & Debugging
    binsider               # İkili dosya analizci
    bitwise                # Bit manipülasyon aracı
    hexdump                # Hex görüntüleyici
    xxd                   # Hex editör
    programmer-calculator  # Programcı hesap makinesi
    psmisc                 # Süreç yönetim araçları
    strace                # Sistem çağrı izleyici
    gdb                   # GNU hata ayıklayıcı
    
    # Development Tools
    tree-sitter           # Parser üreteci
    nix-search-tv         # Nix paket arayıcı
    gist                  # GitHub gist CLI
    
    # Nix Development
    nvd                # Nix versiyon karşılaştırma
    cachix             # İkili önbellek servisi
    nix-output-monitor # Nix build monitörü
    
    # Programming Languages
    go_1_25                 # Go programlama dili
    customPython       # Özelleştirilmiş Python
    
    # AI/ML Tools
    ollama             # Lokal LLM çalıştırıcı

    # ==============================================================================
    # Terminal Araçları
    # ==============================================================================
    # Terminal Management
    tmux            # Terminal çoklayıcı
    wezterm         # Modern terminal emülatörü
    
    # Text Processing
    bc              # Hesap makinesi
    jq              # JSON işlemci
    yq              # YAML/JSON işlemci
    gawk            # Metin işleme aracı
    bat             # Sözdizimi vurgulu cat
    ripgrep         # Hızlı metin arama
    most            # Sayfalayıcı
    glow            # Markdown görüntüleyici
    
    # System Utilities
    killall         # İsme göre süreç sonlandırma
    entr            # Dosya değişiklik izleyici
    pv              # Pipe progress görüntüleyici
    pwgen           # Parola üreteci
    tldr            # Basitleştirilmiş man sayfaları
    mimeo           # MIME işleyici
    
    # Navigation & Session
    zoxide          # Akıllı dizin atlayıcı
    sesh            # Terminal oturum yöneticisi
    
    # Clipboard & Utilities
    wl-clipboard    # Wayland pano araçları
    docfd           # Belge bulucu
    translate-shell # Çeviri aracı
    wmctrl          # Pencere yönetimi
    
    # Network & Download
    curl            # URL transfer aracı
    wget            # Web dosya indirici
    dig             # DNS sorgu aracı
    
    # Security Tools
    age             # Modern şifreleme aracı

    # ==============================================================================
    # Medya Araçları
    # ==============================================================================
    # Video/Audio Players
    open-in-mpv     # mpv browser eklentisi
    mpv             # Minimal medya oynatıcı
    vlc             # Çok amaçlı medya oynatıcı
    
    # Image Viewers
    imv             # Minimal resim görüntüleyici
    qview           # Hızlı resim görüntüleyici
    
    # Audio Control
    #pamixer         # PulseAudio CLI mixer
    pavucontrol     # PulseAudio ses kontrolü
    playerctl       # MPRIS medya kontrolü
    
    # Media Processing
    ffmpeg          # Medya dönüştürme araçları
    gifsicle        # GIF optimizasyon
    imagemagick     # Resim işleme araçları
    yt-dlp          # YouTube/video indirici
    pipe-viewer     # A lightweight YouTube client
    
    # Screenshot Tools
    satty           # Ekran görüntüsü annotasyon
    swappy          # Wayland ekran görüntüsü editörü
    
    # Music & Entertainment
    spotify         # Müzik streaming
    spotify-cli-linux # Spotify CLI kontrolü
    ani-cli         # Anime streaming CLI
    rmpc            # Modern MPD istemcisi
    mpc             # Minimal MPD istemcisi
    #radiotray-ng    # İnternet radyo oynatıcı
    soundwireserver # Ses streaming sunucusu
    
    # Torrent
    transmission_4   # BitTorrent istemcisi
    pirate-get       # Pirate Bay CLI

    # ==============================================================================
    # Sistem İzleme ve Performans
    # ==============================================================================
    # System Monitors
    atop            # Gelişmiş sistem monitörü
    glances         # Cross-platform sistem monitörü
    resources       # GNOME sistem kaynakları
    nmon            # Performans monitörü
    iotop           # I/O kullanım monitörü
    dool            # Sistem istatistikleri (dstat fork)
    stress-ng       # Sistem stres test aracı
    s-tui           # Terminal stres monitörü
    htop            # İnteraktif process viewer
    procs           # Modern process lister (ps alternatifi)
    hyperfine       # Command-line benchmarking tool
    
    # Process Management
    cpulimit        # CPU kullanım sınırlayıcı
    lsof            # Açık dosya listeleyici
    
    # Hardware Info
    lshw            # Detaylı donanım bilgisi
    pciutils        # PCI aygıt araçları
    inxi            # Sistem bilgi özeti
    
    # System Info Display
    neofetch        # Sistem bilgi banner
    nitch           # Minimal sistem bilgisi
    onefetch        # Git repo bilgisi

    # ==============================================================================
    # Ağ Araçları
    # ==============================================================================
    # Network Monitoring
    bmon            # Bant genişliği monitörü
    iptraf-ng       # IP trafik monitörü
    vnstat          # Ağ kullanım istatistikleri
    tcpdump         # Paket yakalama aracı
    nethogs         # Süreç bazlı bant genişliği
    iftop           # Ağ arayüzü monitörü
    
    # Network Analysis & Testing
    mtr             # Traceroute + ping kombini
    nmap            # Ağ keşif ve güvenlik tarama
    speedtest-cli   # İnternet hız testi
    iperf           # Ağ performans testi
    fping           # Paralel ping aracı
    traceroute      # Ağ yolu izleme
    
    # Network Tools
    aria2           # Çoklu protokol indirme
    ethtool         # Ethernet arayüz kontrolü
    
    # Remote Access
    assh            # SSH wrapper ve manager
    pssh            # Paralel SSH
    tigervnc        # VNC istemci/sunucu
    anydesk         # Uzak masaüstü
    
    # Network Management
    rofi-network-manager  # Rofi NetworkManager GUI
    
    # Input Tools
    fusuma          # Çoklu dokunma hareketi
    touchegg        # Dokunmatik hareket tanıma

    # ==============================================================================
    # Masaüstü Uygulamaları
    # ==============================================================================
    # Office & Productivity
    libreoffice      # Ofis paketi
    libqalculate     # Gelişmiş hesap makinesi kütüphanesi
    qalculate-gtk    # Bilimsel hesap makinesi
    calcurse         # Terminal takvim
    
    # PDF & Image Tools
    pdftk            # PDF araç seti
    zathura          # Minimal PDF görüntüleyici
    evince           # GNOME belge görüntüleyici
    poppler-utils    # PDF komut satırı araçları
    img2pdf          # Resim → PDF dönüştürücü
    
    # Communication
    discord          # Oyuncu sohbet platformu
    catppuccin-discord # Discord Catppuccin teması
    #whatsie          # WhatsApp masaüstü - qtwebengine-5
    wasistlos        # Alternatif WhatsApp
    ferdium          # Çoklu servis yöneticisi
    
    # Security & Authentication
    ente-auth        # 2FA kimlik doğrulama
    keepassxc        # Parola yöneticisi
    gopass           # CLI parola yöneticisi
    
    # System Management
    bleachbit        # Sistem temizleyici
    gparted          # Disk bölümleme GUI
    flatpak          # Uygulama sandboxing
    ventoy           # Çoklu ISO USB aracı
    efibootmgr       # EFI boot manager
    gnome-monitor-config # GNOME monitor yapılandırma yardımcısı
    wayland-utils    # Wayland yardımcı araçları

    # Clipboard Management
    xclip            # X11 pano aracı
    cliphist         # Wayland pano geçmişi
    clipman          # Pano yöneticisi

    # ==============================================================================
    # Hyprland & Wayland Araçları
    # ==============================================================================
    # Window Management
    sway             # i3 uyumlu Wayland WM
    pyprland         # Hyprland Python araçları
    woomer           # Pencere büyütme aracı
    
    # System Control
    hyprsunset       # Ekran renk sıcaklığı
    hypridle         # Boşta kalma yöneticisi
    brightnessctl    # Ekran parlaklığı kontrolü
    hyprshade        # Hyprland shader yönetimi
    
    # Display & Input
    wl-gammactl      # Wayland gamma kontrolü
    wl-gammarelay-applet # Gamma relay applet
    waynergy         # Synergy alternatifi (Wayland)
    input-leap       # Klavye/mouse paylaşımı
    
    # Wallpaper & Themes
    wpaperd          # Wayland duvar kağıdı daemon
    hyprpaper        # Hyprland duvar kağıdı daemon
    # candy-icons removed - using custom candy-beauty from modules/home/candy
    beauty-line-icon-theme # Alternatif simge seti
    
    # Input Simulation
    wtype            # Wayland klavye simülatörü
    ydotool          # Evrensel input simülatörü
    
    # Media Control
    waybar-mpris     # Waybar MPRIS entegrasyonu
    
    # Dialogs & Notifications
    zenity           # GTK dialog kutuları
    
    # Extensions
    gnomeExtensions.gsconnect # Telefon entegrasyonu
    gnome-screenshot

    # ==============================================================================
    # Tarayıcılar
    # ==============================================================================
    # Text Browsers
    browsh          # Modern text browser with graphics
    lynx            # Klasik metin tarayıcı
    links2          # Gelişmiş metin tarayıcı
    elinks          # Özellikli metin tarayıcı
    w3m             # Inline görüntü destekli

    # ==============================================================================
    # Önizleme Araçları (LF için)
    # ==============================================================================
    # Document Conversion
    odt2txt        # ODT metin dönüştürücü
    catdoc         # DOC metin çıkarıcı
    #gnumeric       # Hesap tablosu görüntüleyici
    
    # Media Information
    exiftool       # Metadata okuyucu
    chafa          # Terminal resim görüntüleyici
    mediainfo      # Medya dosyası bilgileri
    ffmpegthumbnailer # Video küçük resim üretici
   
    # CD/DVD Tools
    libcdio        # CD/DVD erişim kütüphanesi

    # ==============================================================================
    # VPN Araçları
    # ==============================================================================
    #gpauth                    # GlobalProtect authenticator - qtwebengine-5
    #globalprotect-openconnect # GlobalProtect VPN istemcisi - qtwebengine-5
    openvpn                   # OpenVPN istemcisi
    openconnect               # Cisco AnyConnect uyumlu
    openfortivpn              # Fortinet VPN istemcisi
    mullvad                   # Mullvad VPN GUI
    mullvad-closest           # Mullvad servers with the lowest latency
    wireguard-tools           # WireGuard CLI araçları
 
    # ==============================================================================
    # Üretkenlik ve Zaman Yönetimi
    # ==============================================================================
    gtt               # Grafik zaman takibi
    todo              # Görev yöneticisi
    toipe             # Terminal yazma pratiği
    ttyper            # Yazma hızı oyunu
    localsend         # Lokal ağ dosya transferi
 
    # ==============================================================================
    # Eğlence ve Terminal Oyunları
    # ==============================================================================
    cbonsai          # ASCII bonsai ağacı
    cmatrix          # Matrix yağmur efekti
    figlet           # ASCII banner üretici
    pipes            # Boru animasyonu
    sl               # Tren animasyonu
    toilet           # Renkli ASCII sanatı
    tty-clock        # Terminal saati
    ytfzf            # YouTube terminal arayüzü
 
    # ==============================================================================
    # Commented Out / Optional Packages
    # ==============================================================================
    # python312Packages.subliminal # Altyazı indirici
    # walker            # Uygulama başlatıcı
    # iwgtk            # Kablosuz yapılandırma GUI
    # intel-undervolt  # CPU undervolting (Meteor Lake uyumsuz)
  ];
}
