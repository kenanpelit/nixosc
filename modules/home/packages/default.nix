# modules/home/packages/default.nix
{ inputs, pkgs, ... }:
{
  home.packages = with pkgs; [
    # Dosya Yönetimi ve Gezgin Araçları
    caligula       # Gelişmiş dosya yöneticisi
    duf            # Disk kullanım analiz aracı
    eza            # Modern ls alternatifi
    fd             # Hızlı ve etkili dosya arama aracı
    file           # Dosya türü belirleme aracı
    gtrash         # GNOME çöp kutusu yönetimi
    lsd            # Renkli ve modern ls alternatifi
    ncdu           # Disk kullanım analizi için terminal aracı
    tree           # Dizin ağacını görselleştirme
    trash-cli      # Çöp kutusu CLI aracı
    unzip          # Zip dosyalarını açma aracı

    # Geliştirici Araçları
    binsider               # İkili dosya analizi aracı
    bitwise                # Bit manipülasyon hesaplayıcı
    hexdump                # Hex görüntüleyici
    lazygit                # Terminal tabanlı Git kullanıcı arayüzü
    lua-language-server    # Lua için dil sunucusu
    nixd                   # Nix dil sunucusu
    nixfmt-rfc-style       # Nix kod formatlayıcı
    nil                    # Nix araç koleksiyonu
    programmer-calculator  # Gelişmiş programcı hesap makinesi
    shellcheck             # Shell script analizi
    shfmt                  # Shell script formatlayıcı
    stylua                 # Lua kod formatlayıcı
    tree-sitter            # Kod ayrıştırma aracı
    treefmt2               # Çoklu dil formatlayıcı
    xxd                    # Hex editör ve analiz aracı
    inputs.alejandra.defaultPackage.${pkgs.system} # Nix kod formatlayıcı

    # Terminal Yardımcı Araçları
    bc             # Komut satırı hesap makinesi
    docfd          # Belgelerde arama aracı
    entr           # Dosya değişiklik izleme aracı
    jq             # JSON işleme aracı
    killall        # Süreç sonlandırma aracı
    mimeo          # MIME tip yöneticisi
    most           # Gelişmiş metin görüntüleyici
    ripgrep        # Hızlı ve etkili metin arama aracı
    sesh           # Oturum yöneticisi
    tldr           # Basitleştirilmiş man sayfaları
    wezterm        # Güçlü ve modern terminal emülatörü
    zoxide         # Akıllı dizin gezgini
    wl-clipboard   # Wayland pano yöneticisi
    bat            # Modern ve renkli dosya görüntüleyici
    detox          # Dosya adı temizleme aracı

    # Medya Oynatıcılar ve Düzenleyiciler
    ani-cli         # CLI tabanlı anime izleme aracı
    ffmpeg          # Medya dönüştürücü ve düzenleyici
    gifsicle        # GIF düzenleme aracı
    imv             # Resim görüntüleyici
    mpv             # Çok yönlü medya oynatıcı
    pamixer         # PulseAudio mikser aracı
    pavucontrol     # PulseAudio kontrol paneli
    playerctl       # Medya oynatıcı kontrol aracı
    satty           # Ekran görüntüsü alma aracı
    soundwireserver # Ses yayın sunucusu
    swappy          # Wayland için ekran görüntüsü düzenleyici
    tdf             # Terminal dosya yöneticisi
    vlc             # Çok formatlı medya oynatıcı
    yt-dlp          # Video indirme aracı

    # Sistem İzleme ve Tanılama Araçları
    atop        # Gerçek zamanlı sistem kaynak monitörü
    cpulimit    # CPU kullanım sınırlandırma aracı
    dstat       # Sistem istatistikleri toplama aracı
    glances     # Çok yönlü sistem monitörü
    iotop       # I/O izleme aracı
    lshw        # Donanım bilgisi listeleme
    lsof        # Açık dosyaları listeleme aracı
    nmon        # Performans monitörü
    pciutils    # PCI cihazları yönetim aracı
    strace      # Sistem çağrı izleyici
    inxi        # Sistem bilgi görüntüleyici
    neofetch    # Sistem bilgisi görselleştirme
    nitch       # Sistem bilgisi için minimalist araç
    onefetch    # Git depo bilgisi görselleştirme
    resources   # Sistem kaynak monitörü

    # Ağ Araçları
    aria2         # Hızlı ve çok protokollü indirme yöneticisi
    bmon          # Bant genişliği monitörü
    ethtool       # Ethernet bağlantı yönetim aracı
    fping         # Daha hızlı ping aracı
    iptraf-ng     # IP trafik monitörü
    pssh          # Paralel SSH komut çalıştırıcı
    traceroute    # Ağ yol izleme aracı
    vnstat        # Ağ trafiği izleme aracı
    dig           # DNS sorgulama aracı

    # Masaüstü ve Verimlilik Araçları
    bleachbit       # Sistem temizleme aracı
    discord         # Mesajlaşma ve topluluk uygulaması
    ente-auth       # Kimlik doğrulama aracı
    hyprsunset      # Hyprland renk sıcaklığı ayarı
    hypridle        # Hyprland boşta kalma yönetimi
    brightnessctl   # Ekran parlaklık kontrolü
    libreoffice     # Ofis uygulamaları paketi
    pyprland        # Hyprland Python araçları
    qalculate-gtk   # Bilimsel hesap makinesi
    woomer          # Wayland pencere yöneticisi
    zenity          # GUI tabanlı dialog oluşturucu
    copyq           # Gelişmiş pano yöneticisi
    keepassxc       # Şifre yöneticisi
    gopass          # Şifre yöneticisi CLI
    pdftk           # PDF düzenleyici
    zathura         # Hafif ve hızlı PDF görüntüleyici
    candy-icons
    beauty-line-icon-theme

    # Verimlilik Araçları
    gtt                # Zaman takip aracı
    nix-prefetch-github # GitHub indirme optimizasyonu
    todo               # Görev yönetim aracı
    toipe              # Yazma pratiği yapma aracı
    ttyper             # Terminal tabanlı yazma eğitimi
    gparted            # Disk bölümlendirme aracı

    # Terminal Eğlence Araçları
    cbonsai        # ASCII bonsai ağacı oluşturucu
    cmatrix        # Terminalde Matrix efekti
    pipes          # ASCII boru animasyonu
    sl             # Steam lokomotif animasyonu
    tty-clock      # Terminal tabanlı saat
    transmission_4 # Unlike some BitTorrent clients
    pirate-get     # Command line interface for TPB

    # Sistem Araçları
    gnome-keyring       # Şifre ve anahtar yönetimi
    polkit_gnome        # Yetkilendirme aracı
    blueman             # Bluetooth cihaz yönetimi
    seahorse            # GNOME şifre yöneticisi

    # Uzaktan Masaüstü Araçları
    anydesk        # Uzak masaüstü bağlantı yazılımı

    # Waybar Araçları
    waybar-mpris  # Waybar için medya denetim modülü
    
    # NixOS
    nix-prefetch-git
  ];
}
