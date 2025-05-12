# modules/home/system/packages/default.nix
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
   # Dosya Yönetimi
   # ==============================================================================
   caligula       # Vim benzeri dosya yöneticisi
   duf            # Disk kullanım analizi
   eza            # Modern ls alternatifi
   fd             # Hızlı dosya bulucu
   file           # Dosya türü tanımlayıcı
   gtrash         # GNOME çöp yöneticisi
   lsd            # Renkli ls alternatifi
   ncdu           # Disk kullanım analizi
   tree           # Dizin ağacı görüntüleyici
   trash-cli      # Çöp CLI yöneticisi
   unzip          # Arşiv açıcı
   fdupes         # Yinelenen dosya bulucu
   czkawka        # Yinelenen dosya bulucu GUI
   lftp           # FTP clients
   android-tools  # adb
   scrcpy         # Android devices over USB or TCP/IP
 
   # ==============================================================================
   # Geliştirme Araçları
   # ==============================================================================
   binsider               # İkili analizci
   bitwise                # Bit manipülasyonu
   hexdump                # Hex görüntüleyici
   lazygit                # Git TUI
   lua-language-server    # Lua LSP
   nixd                   # Nix LSP
   nixfmt-rfc-style       # Nix biçimlendirici
   nil                    # Nix dil araçları
   programmer-calculator  # Geliştirici hesap makinesi
   psmisc                 # Süreç araçları
   shellcheck            # Kabuk analizci
   shfmt                 # Kabuk biçimlendirici
   stylua                # Lua biçimlendirici
   tig                   # Git metin arayüzü
   tree-sitter           # Parser üreteci
   treefmt               # Çoklu dil biçimlendirici
   xxd                   # Hex editör
   nix-search-tv         # Nix paket arayıcı
   inputs.alejandra.defaultPackage.${pkgs.system} # Nix biçimlendirici
 
   # ==============================================================================
   # Terminal Araçları
   # ==============================================================================
   bc              # Hesap makinesi
   docfd           # Belge bulucu
   entr            # Dosya izleyici
   jq              # JSON işlemci
   killall         # Süreç sonlandırıcı
   mimeo           # MIME işleyici
   most            # Sayfalayıcı
   ripgrep         # Metin arama
   sesh            # Oturum yöneticisi
   tldr            # Basit man sayfaları
   wezterm         # Terminal emülatörü
   zoxide          # Dizin atlayıcı
   wl-clipboard    # Wayland pano
   bat             # Gelişmiş cat
   detox           # Dosya adı temizleyici
   pv              # Boru görüntüleyici
   pwgen           # Password generator
   gist            # GitHub gist aracı
   translate-shell # Çeviri aracı
   rmpc            # Zengin MPD istemcisi
   mpc-cli         # MPD istemcisi
   calcurse        # Takvim

   # ==============================================================================
   # Medya Araçları
   # ==============================================================================
   ani-cli         # Anime CLI
   ffmpeg          # Medya dönüştürücü
   gifsicle       # GIF editör
   imv             # Resim görüntüleyici
   qview           # Hızlı görüntüleyici
   mpv             # Medya oynatıcı
   pamixer         # Ses karıştırıcı
   pavucontrol     # Ses kontrolü
   playerctl       # Medya kontrolü
   satty           # Ekran görüntüsü
   soundwireserver # Ses akışı
   spotify         # Müzik servisi  
   spotify-cli-linux # Command line interface to Spotify
   swappy          # Ekran görüntüsü editörü
   tdf             # Dosya yöneticisi
   vlc             # Medya oynatıcı
   yt-dlp          # Video indirici
   radiotray-ng    # İnternet radyosu
   #python312Packages.subliminal # Altyazı indirici

   # ==============================================================================
   # Sistem İzleme
   # ==============================================================================
   atop            # Sistem monitörü
   cpulimit        # CPU sınırlayıcı
   dool            # Sistem istatistikleri
   glances         # Sistem monitörü
   iotop           # I/O monitörü
   lshw            # Donanım listeleyici
   lsof            # Açık dosya listeleyici
   nmon            # Performans monitörü
   pciutils        # PCI araçları
   strace          # Sistem çağrı izleyici
   inxi            # Sistem bilgisi
   neofetch        # Sistem bilgisi
   nitch           # Sistem bilgisi
   onefetch        # Git repo bilgisi
   resources       # Kaynak monitörü
   mlocate         # Dosya konumlandırıcı

   # ==============================================================================
   # Ağ Araçları
   # ==============================================================================
   aria2           # İndirme yöneticisi
   bmon            # Bant genişliği monitörü
   ethtool         # Ethernet aracı
   fping           # Hızlı ping
   iptraf-ng       # IP trafik monitörü
   pssh            # Paralel SSH
   traceroute      # Ağ izleyici
   vnstat          # Ağ monitörü
   dig             # DNS aracı

   # ==============================================================================
   # Masaüstü Araçları
   # ==============================================================================
   bleachbit        # Sistem temizleyici
   libqalculate     # Gelişmiş hesap makinesi kitaplığı
   discord          # Sohbet platformu
   ente-auth        # Kimlik doğrulama
   hyprsunset       # Renk sıcaklığı
   hypridle         # Boşta yöneticisi
   brightnessctl    # Parlaklık kontrolü
   libreoffice      # Ofis paketi
   pyprland         # Hyprland araçları
   qalculate-gtk    # Hesap makinesi
   woomer           # Pencere yöneticisi
   zenity           # GTK diyalogları
   copyq            # Pano yöneticisi
   cliphist         # Pano yöneticisi
   clipman          # Pano yöneticisi
   keepassxc        # Parola yöneticisi
   gopass           # Parola CLI
   pdftk            # PDF araçları
   zathura          # PDF görüntüleyici
   imagemagick      # Image manager
   evince           # PDF görüntüleyici
   candy-icons      # Simge teması
   wpaperd          # Duvar kağıdı 
   sway             # Pencere yöneticisi
   beauty-line-icon-theme # Simgeler
   gnomeExtensions.gsconnect # KDE Connect
   #walker           # Uygulama başlatıcı
   wtype            # Tuş simülatörü
   whatsie          # WhatsApp
   whatsapp-for-linux # WhatsApp
   waybar-mpris     # Medya kontrolü
   ferdium          # Services in one place

   # ==============================================================================
   # Tarayıcılar
   # ==============================================================================
   lynx            # Metin tarayıcı
   links2          # Metin tarayıcı
   elinks          # Metin tarayıcı
   anydesk         # Uzak masaüstü

   # ==============================================================================
   # Önizleme Araçları
   # ==============================================================================
   jq             # JSON aracı
   bat            # Kod görüntüleyici
   glow           # Markdown görüntüleyici
   w3m            # Metin tarayıcı
   eza            # Dosya listeleyici
   openssl        # SSL araçları
   atool          # Arşiv aracı
   p7zip          # Sıkıştırma
   libcdio        # CD/DVD aracı
   odt2txt        # ODT dönüştürücü
   catdoc         # DOC görüntüleyici
   gnumeric       # Hesap tablosu
   exiftool       # Meta veri aracı
   chafa          # Resim görüntüleyici
   mediainfo      # Medya bilgisi
   ffmpegthumbnailer # Küçük resimler
   poppler_utils  # PDF araçları

   # ==============================================================================
   # Eğlence
   # ==============================================================================
   cbonsai          # Bonsai ağacı
   cmatrix          # Matrix efekti
   figlet           # ASCII sanatı
   pipes            # Borular ekran koruyucu
   sl               # Buhar lokomotifi
   toilet           # ASCII sanatı
   tty-clock        # Terminal saati
   transmission_4   # Torrent istemcisi
   pirate-get       # Torrent arama

   # ==============================================================================
   # Üretkenlik
   # ==============================================================================
   gtt               # Zaman takibi
   todo              # Yapılacaklar yöneticisi
   toipe             # Yazma öğretici
   ttyper            # Yazma oyunu
   gparted           # Disk bölümü editörü

   # ==============================================================================
   # VPN Araçları
   # ==============================================================================
   gpauth                    # GlobalProtect
   globalprotect-openconnect # VPN istemcisi
   openvpn                   # VPN istemcisi
   openconnect               # VPN istemcisi
   openfortivpn              # VPN istemcisi
 ];
}

