# modules/home/packages/default.nix
# ==============================================================================
# Merkezi Paket Yönetimi
# Bu modül, tüm sistem paketlerini merkezi olarak yönetir ve kategorize eder.
# Her kategori kendi içinde mantıksal olarak gruplandırılmıştır.
# ==============================================================================
{ inputs, pkgs, ... }:

let
  # ==============================================================================
  # Dosya Yönetimi ve Gezinme Araçları
  # Dosya sistemi operasyonları, dosya yönetimi ve gezinme için gerekli araçlar
  # ==============================================================================
  fileManagement = with pkgs; [
    caligula       # Gelişmiş dosya yöneticisi - vim benzeri arayüz
    duf            # Disk kullanımı analizi - modern df alternatifi
    eza            # Modern ls alternatifi - renk ve ikonlarla zenginleştirilmiş
    fd             # Hızlı dosya bulucu - find alternatifi
    file           # Dosya türü tanımlayıcı
    gtrash         # GNOME çöp kutusu yöneticisi
    lsd            # Renkli ls alternatifi
    ncdu           # Disk kullanım analizi - ncurses tabanlı
    tree           # Dizin ağacı görüntüleyici
    trash-cli      # Çöp kutusu yönetim CLI'ı
    unzip          # Arşiv açıcı
  ];

  # ==============================================================================
  # Geliştirme Araçları
  # Programlama, kod analizi ve geliştirme için gerekli araçlar
  # ==============================================================================
  devTools = with pkgs; [
    binsider               # İkili dosya analizi
    bitwise                # Bit manipülasyonu ve hesaplama
    hexdump                # Hex görüntüleyici
    lazygit                # Git terminal arayüzü
    lua-language-server    # Lua dil sunucusu
    nixd                   # Nix dil sunucusu
    nixfmt-rfc-style       # Nix kod formatlayıcı
    nil                    # Nix dil araçları
    programmer-calculator  # Programcı hesap makinesi
    psmisc                 # A package of small utilities
    shellcheck            # Kabuk betik analizi
    shfmt                 # Kabuk betik formatlayıcı
    stylua                # Lua kod formatlayıcı
    tree-sitter           # Evrensel parser
    treefmt2              # Çoklu dil formatlayıcı
    xxd                   # Hex düzenleyici
    inputs.alejandra.defaultPackage.${pkgs.system} # Modern Nix formatlayıcı
  ];

  # ==============================================================================
  # Terminal Yardımcı Programları
  # Günlük terminal kullanımı için gerekli araçlar
  # ==============================================================================
  terminalUtils = with pkgs; [
    bc              # Gelişmiş hesap makinesi
    docfd           # Doküman arama
    entr            # Dosya değişikliği izleme
    jq              # JSON işleme
    killall         # Süreç sonlandırma
    mimeo          # MIME işleme
    most            # Gelişmiş sayfalayıcı
    ripgrep         # Hızlı metin arama - grep alternatifi
    sesh            # Oturum yöneticisi
    tldr            # Basitleştirilmiş man sayfaları
    wezterm         # Modern terminal emülatörü
    zoxide          # Akıllı dizin gezinme
    wl-clipboard    # Wayland pano yöneticisi
    bat             # Gelişmiş cat alternatifi
    detox           # Dosya adı temizleyici
    pv              # Pipe görselleştirici
    gist            # GitHub gist yükleme
    python312Packages.subliminal  # Search and download subtitles
    python312Packages.googletrans # Googletrans
    translate-shell
  ];

  # ==============================================================================
  # Medya Araçları
  # Ses, video ve görüntü işleme araçları
  # ==============================================================================
  mediaTools = with pkgs; [
    ani-cli         # Anime izleme CLI
    ffmpeg          # Çoklu medya dönüştürücü
    gifsicle       # GIF düzenleyici
    imv             # Hafif resim görüntüleyici
    qview           # Hızlı resim görüntüleyici
    mpv             # Modern medya oynatıcı
    pamixer         # Pulse ses kontrolü
    pavucontrol     # Pulse ses ayarları
    playerctl       # MPRIS medya kontrolü
    satty           # Ekran görüntüsü aracı
    soundwireserver # Ses streaming sunucusu
    swappy          # Ekran görüntüsü düzenleyici
    tdf             # Terminal dosya yöneticisi
    vlc             # Çoklu medya oynatıcı
    yt-dlp          # Video indirici
  ];

  # ==============================================================================
  # Sistem İzleme ve Tanılama Araçları
  # Sistem performansı, donanım bilgisi ve sistem durumu izleme araçları
  # ==============================================================================
  systemTools = with pkgs; [
    atop            # Gelişmiş sistem monitörü - süreç ve sistem kaynakları izleme
    cpulimit        # CPU kullanım sınırlayıcı
    dool            # Çok yönlü sistem istatistikleri toplayıcı
    glances         # Python tabanlı sistem monitörü
    iotop           # I/O kullanımı monitörü
    lshw            # Detaylı donanım listesi
    lsof            # Açık dosya listeleyici
    nmon            # Performans monitörü
    pciutils        # PCI aygıt yönetimi
    strace          # Sistem çağrıları izleyici
    inxi            # Sistem bilgi toplayıcı
    neofetch        # Sistem bilgi görüntüleyici
    nitch           # Minimal sistem bilgi görüntüleyici
    onefetch        # Git deposu bilgi görüntüleyici
    resources       # Kaynak monitörü
    mlocate         # locate/updatedb implementation
  ];

  # ==============================================================================
  # Ağ Araçları
  # Ağ izleme, analiz ve yönetim araçları
  # ==============================================================================
  networkTools = with pkgs; [
    aria2           # Çok protokollü indirme yöneticisi
    bmon            # Bant genişliği monitörü
    ethtool         # Ethernet kartı yönetimi
    fping           # Paralel ping aracı
    iptraf-ng       # IP trafik monitörü
    pssh            # Paralel SSH istemcisi
    traceroute      # Ağ yolu izleyici
    vnstat          # Ağ trafik monitörü
    dig             # DNS sorgulama aracı
  ];

  # ==============================================================================
  # Masaüstü ve Üretkenlik Araçları
  # Günlük kullanım ve üretkenlik için masaüstü uygulamaları
  # ==============================================================================
  desktopTools = with pkgs; [
    bleachbit        # Sistem temizleyici
    discord          # Sesli ve yazılı iletişim platformu
    ente-auth        # Kimlik doğrulama aracı
    hyprsunset       # Renk sıcaklığı ayarlayıcı
    hypridle         # Boşta kalma yöneticisi
    brightnessctl    # Ekran parlaklığı kontrolü
    libreoffice      # Ofis paketi
    pyprland         # Hyprland araçları
    qalculate-gtk    # Gelişmiş hesap makinesi
    woomer           # Pencere yöneticisi
    zenity           # GTK+ dialog oluşturucu
    copyq            # Gelişmiş pano yöneticisi
    keepassxc        # Şifre yöneticisi
    gopass           # Terminal şifre yöneticisi
    pdftk            # PDF araç seti
    zathura          # Minimal PDF görüntüleyici
    evince          # GNOME PDF görüntüleyici
    candy-icons     # Simge teması
    wpaperd         # Modern duvar kağıdı yöneticisi
    sway            # i3 uyumlu Wayland pencere yöneticisi
    beauty-line-icon-theme # Modern simge teması
    gnomeExtensions.gsconnect # Connect implementation
    wtype           # Xdotool type for wayland
    whatsie
    whatsapp-for-linux
  ];

  # ==============================================================================
  # Sistem Entegrasyonu
  # Sistem servisleri ve masaüstü entegrasyonu araçları
  # ==============================================================================
  systemIntegration = with pkgs; [
    gnome-keyring      # GNOME anahtar deposu
    polkit_gnome       # Yetkilendirme çerçevesi
    blueman            # Bluetooth yöneticisi
    seahorse           # GNOME anahtar ve şifre yöneticisi
  ];

  # ==============================================================================
  # Tarayıcılar
  # Terminal tabanlı web tarayıcıları
  # ==============================================================================
  browsers = with pkgs; [
    lynx                # Metin tabanlı web tarayıcısı
    links2              # Gelişmiş metin tabanlı tarayıcı
    elinks              # Özelleştirilebilir metin tabanlı tarayıcı
  ];

  # ==============================================================================
  # Uzak Masaüstü
  # Uzak bağlantı ve masaüstü paylaşım araçları
  # ==============================================================================
  remoteDesktop = with pkgs; [
    anydesk         # Uzak masaüstü bağlantı aracı
  ];

  # ==============================================================================
  # Waybar Uzantıları
  # Waybar için ek özellikler ve araçlar
  # ==============================================================================
  waybarExtensions = with pkgs; [
    waybar-mpris    # Medya kontrolü modülü
  ];

  # ==============================================================================
  # NixOS Araçları
  # NixOS-spesifik yönetim ve geliştirme araçları
  # ==============================================================================
  nixTools = with pkgs; [
    nix-prefetch-git # Git kaynak kodu önbelleği
    nix-prefetch-github # GitHub kaynak kodu önbelleği

  ];

  # ==============================================================================
  # Tmux Bağımlılıkları
  # Tmux terminal çoklayıcı için gerekli araçlar
  # ==============================================================================
  tmuxDeps = with pkgs; [
    gnutar        # GNU arşiv yönetimi
    gzip          # Sıkıştırma aracı
    coreutils     # Temel sistem araçları
    yq-go         # YAML işleme aracı
    gawk          # Metin işleme dili
  ];

  # ==============================================================================
  # Terminal Eğlence Araçları
  # Terminal tabanlı eğlence ve görsel efekt araçları
  # ==============================================================================
  terminalFun = with pkgs; [
    cbonsai        # ASCII bonsai ağacı
    cmatrix        # Matrix efekti
    pipes          # ASCII boru animasyonu
    sl             # ASCII buhar lokomotifi
    tty-clock      # Terminal saati
    transmission_4 # Torrent istemcisi
    pirate-get     # TPB arayüzü
  ];

  # ==============================================================================
  # Üretkenlik Araçları
  # Zaman yönetimi ve üretkenlik araçları
  # ==============================================================================
  productivityTools = with pkgs; [
    gtt                # Zaman takip aracı
    todo               # Görev yöneticisi
    toipe              # Klavye pratik aracı
    ttyper             # Terminal yazım pratik aracı
    gparted            # Disk bölümleme aracı
  ];

  # ==============================================================================
  # Temel Önizleme Araçları
  # Dosya analizi ve temel önizleme için gerekli araçlar
  # ==============================================================================
  basicPreviewTools = with pkgs; [
    file            # Dosya türü belirleme
    jq              # JSON verisi görüntüleme ve işleme
    bat             # Sözdizimi vurgulayıcı metin görüntüleyici
    glow            # Markdown terminal görüntüleyici
    w3m             # Terminal web tarayıcısı
    eza             # Modern dizin listeleyici
    openssl         # SSL sertifika görüntüleme
  ];

  # ==============================================================================
  # Arşiv Önizleme Araçları
  # Sıkıştırılmış dosya ve arşivler için önizleme araçları
  # ==============================================================================
  archivePreviewTools = with pkgs; [
    atool           # Arşiv yönetim aracı
    p7zip          # 7-Zip sıkıştırma aracı
    libcdio        # CD-ROM ve ISO görüntüleme
  ];

  # ==============================================================================
  # Doküman Önizleme Araçları
  # Ofis ve metin belgelerinin önizlemesi için araçlar
  # ==============================================================================
  documentPreviewTools = with pkgs; [
    odt2txt         # LibreOffice metin dönüştürücü
    catdoc          # Microsoft Word dönüştürücü
    gnumeric        # Spreadsheet görüntüleyici
  ];

  # ==============================================================================
  # Medya Önizleme Araçları
  # Görsel ve medya dosyalarının önizlemesi için araçlar
  # ==============================================================================
  mediaPreviewTools = with pkgs; [
    exiftool            # Medya meta veri görüntüleyici
    chafa              # Terminal görsel görüntüleyici
    mediainfo          # Medya bilgi görüntüleyici
    ffmpegthumbnailer  # Video küçük resim oluşturucu
    poppler_utils      # PDF işleme araçları
  ];
in
{
  # Tüm paketleri merkezi olarak yönet ve birleştir
  home.packages = 
    fileManagement ++
    devTools ++
    terminalUtils ++
    mediaTools ++
    systemTools ++
    networkTools ++
    desktopTools ++
    systemIntegration ++
    browsers ++
    remoteDesktop ++
    waybarExtensions ++
    nixTools ++
    tmuxDeps ++
    terminalFun ++
    productivityTools++
    basicPreviewTools ++
    archivePreviewTools ++
    documentPreviewTools ++
    mediaPreviewTools;
}
