{ inputs, pkgs, ... }: 
{
  home.packages = (with pkgs; [
    ## CLI Utility (Temel Komut Satırı Araçları)
    ani-cli                           # Anime izlemek için TUI aracı
    binsider                          # İkili dosyalar için inceleme ve analiz aracı
    bitwise                           # Bit/hex manipülasyonları için CLI aracı
    byobu                             # Gelişmiş tmux wrapper
    caligula                          # Disk imajlama için hafif ve kullanıcı dostu TUI
    dconf-editor                      # GNOME dconf yapılandırma düzenleyicisi
    docfd                             # Çok satırlı fuzzy metin arama TUI'si
    eza                               # Modern bir ls alternatifi
    entr                              # Dosya değişiminde komut çalıştırma aracı
    fd                                # Hızlı ve kullanıcı dostu bir find alternatifi
    ffmpeg                            # Video ve ses işleme aracı
    file                              # Dosya bilgisi gösterici
    gtt                               # Google Translate TUI aracı
    gifsicle                          # GIF düzenleme ve sıkıştırma aracı
    gtrash                            # Dosyaları çöp kutusuna taşıyan bir rm alternatifi
    hexdump                           # İkili dosyaların hex dökümü
    imv                               # Basit ve hızlı bir görsel görüntüleyici
    jq                                # JSON veri işlemcisi
    killall                           # Süreçleri topluca sonlandırma aracı
    lazygit                           # Git için kullanıcı dostu TUI
    libnotify                         # Bildirim sistemi
    man-pages                         # Ekstra manuel sayfalar
    mimeo                             # MIME türü temelli komut çalıştırma
    mpv                               # Hafif ve güçlü medya oynatıcı
    ncdu                              # Disk kullanımını analiz eden TUI
    nitch                             # Sistem bilgisi gösteren fetch aracı
    nixd                              # Nix için dil sunucusu
    nixfmt-rfc-style                  # Nix kodu formatlayıcı
    openssl                           # Kriptografi araçları ve kütüphanesi
    onefetch                          # Git depoları için fetch aracı
    pamixer                           # PulseAudio CLI mikser
    playerctl                         # Medya oynatıcı kontrol aracı
    poweralertd                       # Güç uyarıları için daemon
    programmer-calculator             # Geliştirici dostu hesap makinesi
    ripgrep                           # Hızlı bir grep alternatifi
    shfmt                             # Shell scriptleri için formatlayıcı
    swappy                            # Ekran görüntüsü düzenleme aracı
    tdf                               # Terminalde PDF görüntüleme
    treefmt2                          # Proje formatlayıcı
    tldr                              # Özet manuel sayfalar
    todo                              # Komut satırı yapılacaklar listesi
    toipe                             # Terminalde yazma testi aracı
    ttyper                            # CLI yazma testi
    tmux                              # Terminal çoklayıcı
    unzip                             # ZIP dosyalarını açma
    wl-clipboard                      # Wayland kopyala-yapıştır araçları (wl-copy, wl-paste)
    wezterm                           # Modern ve hızlı terminal emülatörü
    wget                              # Dosya indirme aracı
    yt-dlp-light                      # YouTube ve benzeri sitelerden video indirme
    xdg-utils                         # XDG standart araçları
    xxd                               # Hex dump aracı

    ## Eğlenceli CLI Araçları
    cbonsai                           # Terminalde bonsai ağaçları
    cmatrix                           # Matrix temalı terminal efekti
    pipes                             # Terminalde boru animasyonları
    sl                                # "ls" yazım hatasını eğlenceli bir animasyona çevirir
    tty-clock                         # Terminalde basit saat

    ## Grafiksel Uygulamalar (GUI)
    bleachbit                         # Sistem önbelleği temizleyici
    discord                           # Sohbet ve topluluk uygulaması
    libreoffice                       # Ofis uygulamaları paketi
    nix-prefetch-github               # GitHub projeleri için prefetch aracı
    pavucontrol                       # PulseAudio ses kontrol arayüzü
    qalculate-gtk                     # Gelişmiş hesap makinesi (GUI)
    resources                         # Sistem kaynaklarını izlemek için GUI uygulaması
    soundwireserver                   # Ses akışı sunucusu
    vlc                               # Gelişmiş medya oynatıcı
    zenity                            # Grafiksel komut kutuları oluşturma aracı

    ## C / C++ Araçları
    gcc                               # GNU C Compiler
    gdb                               # GNU Hata Ayıklayıcı
    gnumake                           # Makefile desteği

    ## Python Araçları
    python3                           # Python 3
    python312Packages.ipython         # Gelişmiş Python konsolu

    ## Diğer
    inputs.alejandra.defaultPackage.${system} # Alejandra için varsayılan paket
  ]);
}
