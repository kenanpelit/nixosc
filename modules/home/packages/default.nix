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
# ==============================================================================

{ inputs, pkgs, ... }:
{
  home.packages = with pkgs; [
    # ==============================================================================
    # Dosya Yönetimi ve Navigasyon
    # ==============================================================================
    caligula      # Vim benzeri dosya yöneticisi
    duf           # Disk kullanım analizi (modern df)
    eza           # Modern ls alternatifi
    fd            # Hızlı dosya bulucu (find alternatifi)
    file          # Dosya türü tanımlayıcı
    gtrash        # GNOME çöp yöneticisi
    lsd           # Renkli ls alternatifi
    ncdu          # Disk kullanım analizi (interactive)
    tree          # Dizin ağacı görüntüleyici
    trash-cli     # Çöp CLI yöneticisi
    unzip         # Arşiv açıcı
    fdupes        # Yinelenen dosya bulucu
    czkawka       # Yinelenen dosya bulucu GUI
    tdf           # Dosya yöneticisi
    mlocate       # Dosya konumlandırıcı
    detox         # Dosya adı temizleyici
    atool         # Arşiv aracı
    p7zip         # Sıkıştırma
    lftp          # FTP clients
    scrcpy        # Android devices over USB or TCP/IP

    # ==============================================================================
    # Geliştirme Araçları
    # ==============================================================================
    # Version Control
    git           # Versiyon kontrol
    lazygit       # Git TUI
    tig           # Git metin arayüzü
    
    # Language Servers & Formatters
    lua-language-server    # Lua LSP
    nixd                   # Nix LSP
    nixfmt-rfc-style       # Nix biçimlendirici
    nil                    # Nix dil araçları
    shellcheck            # Kabuk analizci
    shfmt                 # Kabuk biçimlendirici
    stylua                # Lua biçimlendirici
    treefmt               # Çoklu dil biçimlendirici
    inputs.alejandra.defaultPackage.${pkgs.system} # Nix biçimlendirici
    
    # Binary Analysis & Debugging
    binsider               # İkili analizci
    bitwise                # Bit manipülasyonu
    hexdump                # Hex görüntüleyici
    xxd                   # Hex editör
    programmer-calculator  # Geliştirici hesap makinesi
    psmisc                 # Süreç araçları
    strace                # Sistem çağrı izleyici
    gdb                   # GNU hata ayıklayıcı
    
    # Development Tools
    tree-sitter           # Parser üreteci
    nix-search-tv         # Nix paket arayıcı
    gist                  # GitHub gist aracı
    
    # Nix Development Tools
    nvd                # Nix versiyon diff
    cachix             # İkili önbellek
    nix-output-monitor # Nix inşa izleyici
    
    # Programming Languages & Runtimes
    go                 # Go çalışma zamanı
    
    # AI/ML Tools
    ollama             # LLM çalıştırıcı

    # ==============================================================================
    # Terminal Araçları
    # ==============================================================================
    # Terminal Management
    tmux            # Terminal çoklayıcı
    
    # Text Processing
    bc              # Hesap makinesi
    jq              # JSON işlemci
    yq              # YAML/JSON işlemci
    gawk            # Metin işleme
    bat             # Gelişmiş cat
    ripgrep         # Metin arama (grep alternatifi)
    most            # Sayfalayıcı
    glow            # Markdown görüntüleyici
    
    # System Utilities
    killall         # Süreç sonlandırıcı
    entr            # Dosya izleyici
    pv              # Boru görüntüleyici
    pwgen           # Password generator
    tldr            # Basit man sayfaları
    mimeo           # MIME işleyici
    
    # Navigation & Session
    zoxide          # Dizin atlayıcı
    sesh            # Oturum yöneticisi
    wezterm         # Terminal emülatörü
    
    # Clipboard & Utilities
    wl-clipboard    # Wayland pano
    docfd           # Belge bulucu
    translate-shell # Çeviri aracı
    wmctrl
    
    # Network & Download Tools
    curl            # URL veri transfer
    wget            # Ağ dosya indirme
    
    # User Security Tools
    age             # Şifreleme

    # ==============================================================================
    # Medya Araçları
    # ==============================================================================
    # Video/Audio Players
    mpv             # Medya oynatıcı
    vlc             # Medya oynatıcı
    
    # Image Viewers
    imv             # Resim görüntüleyici
    qview           # Hızlı görüntüleyici
    
    # Audio Control
    pamixer         # Ses karıştırıcı
    pavucontrol     # Ses kontrolü
    playerctl       # Medya kontrolü
    
    # Media Processing
    ffmpeg          # Medya dönüştürücü
    gifsicle       # GIF editör
    imagemagick     # Image manager
    yt-dlp          # Video indirici
    
    # Screenshot Tools
    satty           # Ekran görüntüsü
    swappy          # Ekran görüntüsü editörü
    
    # Music & Entertainment
    spotify         # Müzik servisi  
    spotify-cli-linux # Command line interface to Spotify
    ani-cli         # Anime CLI
    rmpc            # Zengin MPD istemcisi
    mpc-cli         # MPD istemcisi
    #radiotray-ng    # İnternet radyosu
    soundwireserver # Ses akışı
    
    # Torrent
    transmission_4   # Torrent istemcisi
    pirate-get       # Torrent arama

    # ==============================================================================
    # Sistem İzleme ve Performans
    # ==============================================================================
    # System Monitors
    atop            # Sistem monitörü
    glances         # Sistem monitörü
    resources       # Kaynak monitörü
    nmon            # Performans monitörü
    iotop           # I/O monitörü
    dool            # Sistem istatistikleri
    
    # Process Management
    cpulimit        # CPU sınırlayıcı
    lsof            # Açık dosya listeleyici
    
    # Hardware Info
    lshw            # Donanım listeleyici
    pciutils        # PCI araçları
    inxi            # Sistem bilgisi
    
    # System Info
    neofetch        # Sistem bilgisi
    nitch           # Sistem bilgisi
    onefetch        # Git repo bilgisi

    # ==============================================================================
    # Ağ Araçları
    # ==============================================================================
    # Network Monitoring
    bmon            # Bant genişliği monitörü
    iptraf-ng       # IP trafik monitörü
    vnstat          # Ağ monitörü
    
    # Network Analysis & Testing
    mtr             # Ağ teşhis
    nmap            # Ağ keşif
    speedtest-cli   # İnternet hız testi
    iperf           # Ağ performans
    fping           # Hızlı ping
    traceroute      # Ağ izleyici
    
    # Network Tools
    aria2           # İndirme yöneticisi
    ethtool         # Ethernet aracı
    
    # Remote Access & SSH
    assh            # SSH yapılandırma
    pssh            # Paralel SSH
    tigervnc        # VNC uygulaması
    anydesk         # Uzak masaüstü
    
    # Network Management
    rofi-network-manager

    # ==============================================================================
    # Masaüstü Uygulamaları
    # ==============================================================================
    # Office & Productivity
    libreoffice      # Ofis paketi
    libqalculate     # Gelişmiş hesap makinesi kitaplığı
    qalculate-gtk    # Hesap makinesi
    calcurse        # Takvim
    
    # PDF Tools
    pdftk            # PDF araçları
    zathura          # PDF görüntüleyici
    evince           # PDF görüntüleyici
    poppler_utils    # PDF araçları
    
    # Communication
    discord          # Sohbet platformu
    whatsie          # WhatsApp
    whatsapp-for-linux # WhatsApp
    ferdium          # Services in one place
    
    # Security & Authentication
    ente-auth        # Kimlik doğrulama
    keepassxc        # Parola yöneticisi
    gopass           # Parola CLI
    
    # System Management
    bleachbit        # Sistem temizleyici
    gparted           # Disk bölümü editörü
    
    # Clipboard Management
    copyq            # Pano yöneticisi
    xclip
    cliphist         # Pano yöneticisi
    clipman          # Pano yöneticisi

    # ==============================================================================
    # Hyprland & Wayland Araçları
    # ==============================================================================
    # Window Management
    sway             # Pencere yöneticisi
    pyprland         # Hyprland araçları
    woomer           # Pencere yöneticisi
    
    # System Control
    hyprsunset       # Renk sıcaklığı
    hypridle         # Boşta yöneticisi
    brightnessctl    # Parlaklık kontrolü
    
    # Wallpaper & Themes
    wpaperd          # Duvar kağıdı 
    candy-icons      # Simge teması
    beauty-line-icon-theme # Simgeler
    
    # Input Simulation
    wtype            # Tuş simülatörü
    ydotool          # Tuş simülatörü
    
    # Media Control
    waybar-mpris     # Medya kontrolü
    
    # Dialogs & Notifications
    zenity           # GTK diyalogları
    
    # Extensions
    gnomeExtensions.gsconnect # KDE Connect

    # ==============================================================================
    # Tarayıcılar
    # ==============================================================================
    # Text Browsers
    lynx            # Metin tarayıcı
    links2          # Metin tarayıcı
    elinks          # Metin tarayıcı
    w3m             # Metin tarayıcı

    # ==============================================================================
    # Önizleme Araçları
    # ==============================================================================
    # Text & Code Preview
    jq             # JSON aracı
    bat            # Kod görüntüleyici
    glow           # Markdown görüntüleyici
    eza            # Dosya listeleyici
    
    # Document Conversion
    odt2txt        # ODT dönüştürücü
    catdoc         # DOC görüntüleyici
    #gnumeric       # Hesap tablosu
    
    # Media Information
    exiftool       # Meta veri aracı
    chafa          # Resim görüntüleyici
    mediainfo      # Medya bilgisi
    ffmpegthumbnailer # Küçük resimler
    
    # CD/DVD Tools
    libcdio        # CD/DVD aracı

    # ==============================================================================
    # VPN Araçları
    # ==============================================================================
    gpauth                    # GlobalProtect
    globalprotect-openconnect # VPN istemcisi
    openvpn                   # VPN istemcisi
    openconnect               # VPN istemcisi
    openfortivpn              # VPN istemcisi

    # ==============================================================================
    # Üretkenlik ve Zaman Yönetimi
    # ==============================================================================
    gtt               # Zaman takibi
    todo              # Yapılacaklar yöneticisi
    toipe             # Yazma öğretici
    ttyper            # Yazma oyunu

    # ==============================================================================
    # Eğlence ve Terminal Oyunları
    # ==============================================================================
    cbonsai          # Bonsai ağacı
    cmatrix          # Matrix efekti
    figlet           # ASCII sanatı
    pipes            # Borular ekran koruyucu
    sl               # Buhar lokomotifi
    toilet           # ASCII sanatı
    tty-clock        # Terminal saati

    # ==============================================================================
    # Commented Out / Optional Packages
    # ==============================================================================
    # python312Packages.subliminal # Altyazı indirici
    # walker           # Uygulama başlatıcı
  ];
}

