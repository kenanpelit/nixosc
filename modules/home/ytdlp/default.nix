# modules/home/ytdlp/default.nix
# ==============================================================================
# Home module for yt-dlp video downloader.
# Installs yt-dlp and manages user config/aliases via Home Manager.
# ==============================================================================

{ config, lib, ... }:
let
  cfg = config.my.user.ytdlp;
  username = config.home.username;
in
{
  options.my.user.ytdlp = {
    enable = lib.mkEnableOption "yt-dlp configuration";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Configuration File
    # =============================================================================
    home.file.".config/yt-dlp/config".text = ''
      # ---------------------------------------------------------------------------
      # Video Quality and Format Settings
      # ---------------------------------------------------------------------------
      # Video kalitesi seçim sırası:
      # 1. 1080p+ yüksek FPS (>30fps) videoları tercih eder (AV1 > VP9.2 > VP9 > H.264)
      # 2. Bulamazsa 1080p normal FPS videoları dener
      # 3. En son olarak mevcut en iyi video kalitesini seçer
      # Her durumda en iyi ses formatını (Opus tercih eder) video ile birleştirir
      --format "(bestvideo[vcodec^=av01][height>=1080][fps>30]/bestvideo[vcodec^=vp9.2][height>=1080][fps>30]/bestvideo[vcodec^=vp9][height>=1080][fps>30]/bestvideo[vcodec^=avc1][height>=1080][fps>30]/bestvideo[height>=1080][fps>30]/bestvideo[vcodec^=av01][height>=1080]/bestvideo[vcodec^=vp9.2][height>=1080]/bestvideo[vcodec^=vp9][height>=1080]/bestvideo[vcodec^=avc1][height>=1080]/bestvideo[height>=1080]/bestvideo)+(bestaudio[acodec^=opus]/bestaudio)/best"
  
      # ---------------------------------------------------------------------------
      # YouTube Client Settings
      # ---------------------------------------------------------------------------
      # YouTube player client seçimi (öncelik sırasına göre):
      # - android: Cookies desteklemez ama en güvenilir, çoğu video için çalışır
      # - web_creator: YouTube Creator Studio client, ek özellikler sağlar
      # - web: Standart web client, cookies destekler (yaş kısıtlamalı videolar için)
      # NOT: Cookies aktifse android client atlanır ve direkt web_creator/web kullanılır
      --extractor-args "youtube:player_client=android,web_creator,web"
  
      # ---------------------------------------------------------------------------
      # Output Settings
      # ---------------------------------------------------------------------------
      # İndirilen dosyalar için ayarlar:
      --paths "$HOME/Videos/yt-dlp"                    # İndirme dizini
      # Dosya adı formatı: VideoAdi.20231025.1920x1080.vp9.opus.01.mp4
      # %(title)s: Video başlığı
      # %(upload_date)s: Yüklenme tarihi (YYYYMMDD)
      # %(resolution)s: Çözünürlük (örn: 1920x1080)
      # %(vcodec)s: Video codec (örn: vp9, avc1)
      # %(acodec)s: Ses codec (örn: opus, m4a)
      # %(autonumber)02d: Otomatik numara (aynı isimde birden fazla video varsa)
      --output "%(title)s.%(upload_date)s.%(resolution)s.%(vcodec)s.%(acodec)s.%(autonumber)02d.%(ext)s"
      --restrict-filenames                             # Dosya adlarında özel karakterleri kaldır
      --no-mtime                                       # Dosya tarihini indirme tarihine ayarla (yükleme tarihine değil)
      --no-overwrites                                  # Varolan dosyaların üzerine yazma
      #--no-playlist                                   # Playlist URL'si verilse bile sadece tek video indir (şu an kapalı)
  
      # ---------------------------------------------------------------------------
      # Subtitle Settings
      # ---------------------------------------------------------------------------
      # Altyazı ayarları:
      --write-sub                                      # Manuel yüklenmiş altyazıları indir
      --write-auto-sub                                 # Otomatik oluşturulan altyazıları da indir
      --sub-langs "tur,tr,eng,en"                      # Türkçe ve İngilizce altyazıları indir
      --sub-format "ass/srt/best"                      # Altyazı formatı tercihi (ASS > SRT > diğerleri)
      --embed-subs                                     # Altyazıları video dosyasına göm
  
      # ---------------------------------------------------------------------------
      # Metadata Settings
      # ---------------------------------------------------------------------------
      # Video metadata ayarları:
      --embed-metadata                                 # Video başlığı, açıklama, yükleyen vb. bilgileri dosyaya göm
      --embed-chapters                                 # Video bölümlerini (chapters) dosyaya göm
      --embed-thumbnail                                # Video küçük resmini dosyaya göm
      --convert-thumbnails webp                        # Küçük resimleri WebP formatına dönüştür (daha küçük dosya boyutu)
  
      # ---------------------------------------------------------------------------
      # Download Settings
      # ---------------------------------------------------------------------------
      # İndirme davranışı ayarları:
      --continue                                       # Yarım kalan indirmelere devam et
      --min-sleep-interval 1                           # İstekler arasında minimum 1 saniye bekle
      --max-sleep-interval 2                           # İstekler arasında maksimum 2 saniye bekle
      --concurrent-fragments 4                         # Aynı anda 4 video parçası indir (hızlandırır)
      --socket-timeout 30                              # Bağlantı zaman aşımı (30 saniye)
      --extractor-retries 3                            # Video bilgisi çekerken 3 kez tekrar dene
      --fragment-retries 3                             # Video parçası indirirken 3 kez tekrar dene
  
      # ---------------------------------------------------------------------------
      # Interface Settings
      # ---------------------------------------------------------------------------
      # Terminal arayüz ayarları:
      --console-title                                  # Terminal başlığında ilerleme göster
      --progress                                       # İndirme ilerlemesini göster
  
      # ---------------------------------------------------------------------------
      # Browser Integration
      # ---------------------------------------------------------------------------
      # Tarayıcı çerezlerini kullan (giriş gerektiren veya yaş kısıtlamalı videolar için):
      # NOT: Android client cookies desteklemediği için bu aktifken android client atlanır
      #--cookies-from-browser firefox:/home/${username}/.zen/Kenp
      --cookies-from-browser brave:/home/${username}/.config/BraveSoftware/Brave-Browser/Default
    '';
  };
}
