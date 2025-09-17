# modules/home/zsh/zsh_unified.nix
{ lib, pkgs, config, host, ... }:
{
  programs.zsh = {
    enable = true;
    defaultKeymap = "viins";
    
    shellAliases = {
      # =============================================================================
      # Core Navigation & Utilities
      # =============================================================================
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      
      c = "clear";
      h = "history | tail -20";
      j = "jobs -l";
      path = "echo -e \${PATH//:/\\\\n}";
      now = "date +'%T'";
      nowtime = "date +'%d-%m-%Y %T'";
      nowdate = "date +'%d-%m-%Y'";
      
      # Modern replacements
      cd = "z";                    # zoxide
      cat = "bat --paging=never";  # bat with no pager for short files
      less = "bat --paging=always"; # bat with pager for long files
      diff = "delta --side-by-side";
      #grep = "rg";                 # ripgrep
      find = "fd";                 # fd
      ps = "procs";                # procs (if available)
      
      # File operations
      tt = "gtrash put";
      rm = "gtrash put";           # Safe delete
      cp = "cp -i";                # Interactive copy
      mv = "mv -i";                # Interactive move
      mkdir = "mkdir -pv";         # Create parents + verbose
      
      # Quick utilities
      py = "python3";
      ipy = "ipython";
      open = "xdg-open";
      pdf = "tdf";
      space = "ncdu";
      dsize = "du -hs";
      yy = "yazi";

      # =============================================================================
      # Enhanced File Listing (eza)
      # =============================================================================
      ls = "eza --icons --group-directories-first";
      l = "eza --icons -a --group-directories-first -1";
      ll = "eza --icons -la --group-directories-first --no-user";
      la = "eza --icons -la --group-directories-first";
      lt = "eza --icons --tree --level=2 --group-directories-first";
      llt = "eza --icons --tree --long --level=3 --group-directories-first";
      tree = "eza --icons --tree --group-directories-first";
      
      # Directory sizes
      lsize = "eza --icons -la --group-directories-first --total-size";
      ldot = "eza --icons -ld .*";  # List only dotfiles

      # =============================================================================
      # System Information & Monitoring
      # =============================================================================
      df = "df -h";
      free = "free -h";
      ip = "ip -color=auto";
      ports = "ss -tulanp";
      
      # Process management
      psa = "ps auxf";
      psgrep = "ps aux | grep -v grep | grep -i";
      psmem = "ps auxf | sort -nr -k 4 | head -20";
      pscpu = "ps auxf | sort -nr -k 3 | head -20";
      
      # System services
      sysfailed = "systemctl list-units --failed";
      sysactive = "systemctl list-units --state=active";
      userlist = "cut -d: -f1 /etc/passwd | sort";
      
      # Hardware info
      hw = "hwinfo --short";
      cpu = "lscpu";
      mem = "free -h && echo && cat /proc/meminfo | grep MemTotal";
      disk = "lsblk -f";
      usb = "lsusb";
      pci = "lspci";
      
      # Security & vulnerabilities
      microcode = "grep . /sys/devices/system/cpu/vulnerabilities/*";
      vulns = "grep . /sys/devices/system/cpu/vulnerabilities/*";

      # =============================================================================
      # Network Utilities
      # =============================================================================
      ping = "ping -c 5";
      fastping = "ping -c 100 -s.2";
      wget = "wget -c";
      curl = "curl -L";
      
      # Network info
      myip = "curl -s ifconfig.me";
      localip = "ip route get 8.8.8.8 | awk '{print \$7; exit}'";

      # =============================================================================
      # Development Tools
      # =============================================================================
      # Python
      piv = "python3 -m venv .venv";
      psv = "source .venv/bin/activate";
      pipi = "pip install";
      pipu = "pip install --upgrade";
      pipl = "pip list";
      pipf = "pip freeze";
      pipr = "pip install -r requirements.txt";
      
      # =============================================================================
      # Podman Container Management
      # =============================================================================
      # Core Podman Commands
      podman = "podman";
      pod-compose = "podman-compose";
      
      # Container Operations - Clear naming
      pod-ps = "podman ps";                    # List running containers
      pod-ps-all = "podman ps -a";             # List all containers
      pod-run = "podman run";                  # Run container
      pod-run-it = "podman run -it";           # Run interactive container
      pod-run-rm = "podman run --rm";          # Run and remove after exit
      pod-start = "podman start";              # Start container
      pod-stop = "podman stop";                # Stop container
      pod-restart = "podman restart";          # Restart container
      pod-rm = "podman rm";                    # Remove container
      pod-rm-force = "podman rm -f";           # Force remove container
      
      # Container Interaction - Descriptive names
      pod-exec = "podman exec -it";            # Execute interactive command
      pod-exec-cmd = "podman exec";            # Execute command in container
      pod-logs = "podman logs -f";             # Follow container logs
      pod-logs-show = "podman logs";           # Show container logs
      pod-inspect = "podman inspect";          # Inspect container
      pod-stats = "podman stats";              # Show container stats
      pod-top = "podman top";                  # Show running processes
      
      # Image Operations - Clear purpose
      pod-images = "podman images";            # List images
      pod-images-all = "podman images -a";     # List all images
      pod-pull = "podman pull";                # Pull image
      pod-push = "podman push";                # Push image
      pod-build = "podman build";              # Build image
      pod-rmi = "podman rmi";                  # Remove image
      pod-rmi-force = "podman rmi -f";         # Force remove image
      pod-tag = "podman tag";                  # Tag image
      
      # System & Cleanup - Self-documenting
      pod-system = "podman system";                    # System commands
      pod-prune = "podman system prune -f";           # Clean unused resources
      pod-prune-volumes = "podman volume prune -f";   # Clean unused volumes
      pod-clean-all = "podman system prune -a -f --volumes"; # Nuclear cleanup
      pod-info = "podman info";                       # System information
      pod-version = "podman version";                 # Version information
      pod-disk-usage = "podman system df";           # Show disk usage
      
      # Pod Operations (Podman's unique feature)
      pods-list = "podman pod ls";                    # List pods
      pods-create = "podman pod create";              # Create pod
      pods-remove = "podman pod rm";                  # Remove pod
      pods-start = "podman pod start";                # Start pod
      pods-stop = "podman pod stop";                  # Stop pod
      pods-restart = "podman pod restart";            # Restart pod
      pods-inspect = "podman pod inspect";            # Inspect pod
      pods-stats = "podman pod stats";                # Pod statistics
      
      # Volume Operations - Explicit naming
      pod-volumes = "podman volume ls";               # List volumes
      pod-volume-create = "podman volume create";     # Create volume
      pod-volume-remove = "podman volume rm";         # Remove volume
      pod-volume-inspect = "podman volume inspect";   # Inspect volume
      
      # Network Operations - Clear purpose
      pod-networks = "podman network ls";             # List networks
      pod-network-create = "podman network create";   # Create network
      pod-network-remove = "podman network rm";       # Remove network
      pod-network-inspect = "podman network inspect"; # Inspect network
      
      # Registry & Repository - Obvious function
      pod-login = "podman login";                     # Login to registry
      pod-logout = "podman logout";                   # Logout from registry
      pod-search = "podman search";                   # Search images
      
      # Compose Operations - podman-compose prefix
      pod-compose-up = "podman-compose up";           # Start services
      pod-compose-up-bg = "podman-compose up -d";     # Start in background
      pod-compose-down = "podman-compose down";       # Stop and remove
      pod-compose-build = "podman-compose build";     # Build services
      pod-compose-pull = "podman-compose pull";       # Pull service images
      pod-compose-ps = "podman-compose ps";           # List services
      pod-compose-logs = "podman-compose logs";       # Show logs
      pod-compose-logs-follow = "podman-compose logs -f"; # Follow logs
      pod-compose-restart = "podman-compose restart"; # Restart services
      pod-compose-stop = "podman-compose stop";       # Stop services
      pod-compose-start = "podman-compose start";     # Start services
      
      # Batch Operations - Descriptive names
      pod-clean-containers = "podman container prune -f"; # Clean containers only
      pod-clean-images = "podman image prune -f";         # Clean images only
      pod-stop-all = "podman stop \$(podman ps -q)";      # Stop all containers
      pod-remove-all = "podman rm \$(podman ps -aq)";     # Remove all containers
      
      # Inspection & Debugging - Clear intent
      pod-history = "podman history";                 # Show image history
      pod-diff = "podman diff";                       # Show container changes
      pod-events = "podman events";                   # Show system events
   
      # =============================================================================
      # Media & Download Tools
      # =============================================================================
      youtube-dl = "yt-dlp";
      yt = "yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio' --merge-output-format mp4";
      yta = "yt-dlp --extract-audio --audio-format mp3";
      ytv = "yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio' --merge-output-format mp4";
      
      # Playlist downloads
      ytp-mp3 = "yt-dlp --yes-playlist --extract-audio --audio-format mp3 -o '%(playlist_index)s-%(title)s.%(ext)s'";
      ytp-mp4 = "yt-dlp --yes-playlist -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio' --merge-output-format mp4 -o '%(playlist_index)s-%(title)s.%(ext)s'";

      # =============================================================================
      # Pipe Viewer (YouTube TUI) — Hızlı ve Anlaşılır Kısayollar
      # =============================================================================
      pv = "pipe-viewer";                                  # Varsayılan (arama/oynat)
      pv-help = "pipe-viewer --help";                      # Yardım
      pv-tricks = "pipe-viewer --tricks";                  # Gizli püf noktaları
      pv-examples = "pipe-viewer --examples";              # Kullanım örnekleri

      # --- Hızlı Arama / Oynatma ---------------------------------------------------
      pv-search = "pipe-viewer --search-videos";           # Video ara (varsayılan mod)
      pv-play = "pipe-viewer --best --player=mpv";         # En iyi kaliteyi mpv ile oynat
      pv-audio = "pipe-viewer -n -a --audio-quality=best"; # Sadece ses (podcast/müzik)
      pv-related = "pipe-viewer -rv";                      # İlgili videolar (ID/URL ver)
      pv-info = "pipe-viewer -i";                          # Video bilgisi (ID/URL ver)
      pv-comments = "pipe-viewer --comments";              # Yorumları göster (ID/URL ver)
      pv-comments-new = "pipe-viewer --comments --comments-order=time"; # En yeni yorumlar

      # --- Çözünürlük / Biçim ------------------------------------------------------
      pv-240 = "pipe-viewer -2";
      pv-360 = "pipe-viewer -3";
      pv-480 = "pipe-viewer -4";
      pv-720 = "pipe-viewer -7";
      pv-1080 = "pipe-viewer -1";
      pv-4k = "pipe-viewer --resolution=2160p";            # 4K tercih
      pv-best = "pipe-viewer --best";                      # En iyi kalite
      pv-mp4 = "pipe-viewer --prefer-mp4 --ignore-av1";    # MP4’ü ve AVC’yi tercih et
      pv-av1 = "pipe-viewer --prefer-av1";                 # AV1’i tercih et
      pv-m4a = "pipe-viewer --prefer-m4a";                 # AAC/M4A sesi tercih et
      pv-hfr = "pipe-viewer --hfr";                        # Yüksek FPS videolara öncelik

      # --- Filtreler (zaman/süre/sıralama/özellik) --------------------------------
      pv-short = "pipe-viewer --duration=short";           # Kısa videolar
      pv-long = "pipe-viewer --duration=long";             # Uzun videolar
      pv-today = "pipe-viewer --time=today";               # Bugün yayımlananlar
      pv-week = "pipe-viewer --time=week";                 # Bu hafta
      pv-month = "pipe-viewer --time=month";               # Bu ay
      pv-order-new = "pipe-viewer --order=upload_date";    # Yeniden eskiye
      pv-order-views = "pipe-viewer --order=view_count";   # Görüntülenmeye göre
      pv-cc = "pipe-viewer --captions";                    # Altyazılı videolar
      pv-live = "pipe-viewer --live";                      # Canlı yayınlar
      pv-hdr = "pipe-viewer --hdr";                        # HDR videolar
      pv-360deg = "pipe-viewer --360";                     # 360° videolar
      pv-3d = "pipe-viewer --dimension=3d";                # 3D videolar

      # --- Kanal / Çalma Listesi ---------------------------------------------------
      pv-ch = "pipe-viewer -sc";                           # Kanal ara
      pv-uploads = "pipe-viewer -uv";                      # Kanal yüklemeleri (kanal adı/ID ver)
      pv-streams = "pipe-viewer -us";                      # Kanal canlı yayınları
      pv-shorts = "pipe-viewer --shorts";                  # Kanal shorts listesi
      pv-pl-search = "pipe-viewer -sp";                    # Çalma listesi ara
      pv-pl = "pipe-viewer --pid";                         # Belirli playlist’i listele (ID ver)
      pv-pl-play = "pipe-viewer --pp";                     # Playlist(ler)i oynat (ID(ler) ver)

      # --- Trendler / Bölge --------------------------------------------------------
      pv-tr = "pipe-viewer --region=TR";                   # Bölgeyi TR olarak ayarla (komuta ekle)
      pv-trend = "pipe-viewer --trending:popular";         # Trendler (genel)
      pv-trend-music = "pipe-viewer --trending:music";     # Trend Müzik
      pv-trend-gaming = "pipe-viewer --trending:gaming";   # Trend Oyun
      pv-trend-news = "pipe-viewer --trending:news";       # Trend Haber
      pv-trend-movies = "pipe-viewer --trending:movies";   # Trend Filmler

      # --- Oynatıcı / Davranış -----------------------------------------------------
      pv-mpv = "pipe-viewer --player=mpv";
      pv-vlc = "pipe-viewer --player=vlc";
      pv-fs = "pipe-viewer --fullscreen";                  # Tam ekran
      pv-shuffle = "pipe-viewer --shuffle";                # Karıştır
      pv-all = "pipe-viewer --all";                        # Sonuçları sırayla oynat
      pv-backwards = "pipe-viewer --backwards";            # Ters sırada oynat
      pv-auto = "pipe-viewer --autoplay";                  # Otomatik bağıl video oynat
      pv-interactive = "pipe-viewer --interactive";        # Etkileşimli mod (soru sorar)

      # --- İndirme / Dönüştürme ----------------------------------------------------
      pv-dl = "pipe-viewer -d";                            # İndirme modu
      pv-dl-mp4 = "pipe-viewer -d --prefer-mp4 --mkv-merge";   # MP4 ağırlıklı, MKV birleştir
      pv-dl-audio = "pipe-viewer -d -n -a --convert-to=mp3";    # Sadece ses indir → MP3’e çevir
      pv-dl-skip = "pipe-viewer -d --skip-if-exists";      # Varsa atla
      pv-dl-subdir = "pipe-viewer -d --dl-in-subdir";      # Alt klasörlere indir
      pv-dl-name = "pipe-viewer -d --filename='%T - %t.%e'";    # Dosya adı formatı
      pv-dl-yt = "pipe-viewer --ytdl --ytdl-cmd=yt-dlp";   # yt-dlp kullanarak indir/oynat

      # --- Yerel Kayıtlar / Abonelikler -------------------------------------------
      pv-favs = "pipe-viewer -F";                          # Favori videoları listele
      pv-likes = "pipe-viewer -L";                         # Beğenilen videolar
      pv-dislikes = "pipe-viewer -D";                      # Beğenilmeyen videolar
      pv-subs = "pipe-viewer -S";                          # Abone olunan kanallar
      pv-saved = "pipe-viewer -lc";                        # Kaydedilen kanallar
      pv-playlists = "pipe-viewer -P";                     # Yerel çalma listeleri
      pv-like = "pipe-viewer --like";                      # Video beğen (URL/ID ekle)
      pv-dislike = "pipe-viewer --dislike";                # Video beğenme (URL/ID ekle)
      pv-fav = "pipe-viewer --favorite";                   # Favoriye ekle (URL/ID ekle)
      pv-save = "pipe-viewer --save";                      # Kanal kaydet (kanal adı/ID ekle)
      pv-sub = "pipe-viewer --subscribe";                  # Kanala abone ol (ad/ID ekle)

      # --- İnvidious / API / Proxy -------------------------------------------------
      pv-inv = "pipe-viewer --invidious --api=auto";       # İnvidious ile dene (rasgele instance)
      pv-api = "pipe-viewer --api";                        # Özel invidious API hostu (ekle)
      pv-proxy = "pipe-viewer --proxy";                    # Proxy ayarla (ekle: proto://host:port)
      pv-cookies = "pipe-viewer --cookies";                # Cookies dosyası kullan (ekle: path)

      # --- Sessizlik/Çıkış Biçimi --------------------------------------------------
      pv-quiet = "pipe-viewer -q";                         # Uyarıları kapat
      pv-rquiet = "pipe-viewer --really-quiet";            # Tamamen sessiz
      pv-vinfo = "pipe-viewer --video-info";               # Oynatmadan önce bilgi göster

      # =============================================================================
      # NixOS Management
      # =============================================================================
      osc = "cd ~/.nixosc";
      
      # Nix shell
      ns = "nom-shell --run zsh";
      ndev = "nix develop --command zsh";
      
      # System management
      nix-switch = "nh os switch --ask";
      nix-update = "nh os switch --update --ask";
      nix-test = "nh os test";
      nix-boot = "nh os boot";
      nix-clean = "nh clean all --keep 5";
      nix-cleanup = "nix-collect-garbage -d && nix-store --optimise";
      
      # Search and info
      nix-search = "nh search";
      nst = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}'";
      ninfo = "nix-info -m";
      
      # Flake operations
      nix-update-flake = "nix flake update ~/.nixosc";
      nix-check = "nix flake check ~/.nixosc";
      
      # Home manager
      hm-switch = "home-manager switch --flake ~/.nixosc";
      hm-build = "home-manager build --flake ~/.nixosc";

      # =============================================================================
      # Transmission CLI Management
      # =============================================================================
      # Core Transmission commands
      tsm = "tsm";
      tsm-list = "tsm list";
      tsm-add = "tsm add";
      tsm-info = "tsm info";
      tsm-speed = "tsm speed";
      tsm-files = "tsm files";
      tsm-config = "tsm config";
      
      # Torrent search functionality
      tsm-search = "tsm search";
      tsm-search-cat = "tsm search -l";                # List categories
      tsm-search-recent = "tsm search -R";             # Recent torrents (48h)
      
      # Individual torrent management
      tsm-start = "tsm start";
      tsm-stop = "tsm stop";
      tsm-remove = "tsm remove";
      tsm-purge = "tsm purge";                         # Remove torrent + files
      
      # Batch torrent operations
      tsm-start-all = "tsm start all";
      tsm-stop-all = "tsm stop all";
      tsm-remove-all = "tsm remove all";
      tsm-purge-all = "tsm purge all";
      
      # Advanced torrent management
      tsm-health = "tsm health";                       # Health check
      tsm-stats = "tsm stats";                         # Detailed statistics
      tsm-disk = "tsm disk-check";                     # Disk usage check
      tsm-tracker = "tsm tracker";                     # Tracker information
      tsm-limit = "tsm limit";                         # Speed limits
      tsm-auto-remove = "tsm auto-remove";             # Auto-remove daemon
      tsm-remove-done = "tsm remove-done";             # Remove completed
      
      # Priority management
      tsm-priority-high = "tsm priority high";
      tsm-priority-normal = "tsm priority normal";
      tsm-priority-low = "tsm priority low";
      
      # Scheduling and organization
      tsm-schedule = "tsm schedule";                   # Schedule start/stop
      tsm-tag = "tsm tag";                             # Manual tagging
      tsm-auto-tag = "tsm auto-tag";                   # Auto-tag by content
      
      # List sorting and filtering
      tsm-list-sort-name = "tsm list --sort-by=name";
      tsm-list-sort-size = "tsm list --sort-by=size";
      tsm-list-sort-status = "tsm list --sort-by=status";
      tsm-list-sort-progress = "tsm list --sort-by=progress";
      tsm-list-filter-size = "tsm list --filter=\"size>1GB\"";
      tsm-list-filter-complete = "tsm list --filter=\"progress=100\"";

      # =============================================================================
      # Utilities & Quality of Life
      # =============================================================================
      # Archive operations
      extract = "aunpack";
      compress = "apack";
      
      # Quick edits
      zshrc = "nvim ~/.nixosc/modules/home/zsh/zsh.nix";
      vimrc = "nvim ~/.config/nvim/init.lua";
      
      # Calendar and time
      cal = "cal -3";
      week = "date +%V";
      
      # Quick server
      serve = "python3 -m http.server 8000";
      
      # Clipboard (if available)
      copy = "xclip -selection clipboard";
      paste = "xclip -selection clipboard -o";
      
      # Session Management Functions (Sesh)
      sesh-c = "sesh connect";
      sesh-l = "sesh list";
      sesh-k = "sesh kill";
      sesh-r = "sesh last";

      # Fun & Useful
      weather = "curl wttr.in";
      moon = "curl wttr.in/moon";
      news = "curl getnews.tech";
      
      # System load
      load = "uptime";
      usage = "du -h --max-depth=1 | sort -hr";
      
      # Colors test
      colors = "for i in {0..255}; do print -Pn \"%K{\$i}  %k%F{\$i}\$'{i:3d}'%f \" \$'{i%16==15?\"\\\\n\":\"\"}'; done";
    };

initContent = ''
      # =============================================================================
      # Environment Variables and Core Setup
      # =============================================================================
      # Transmission script location for CLI access
      export TSM_SCRIPT="tsm"
      
      # =============================================================================
      # Enhanced Vi Mode Configuration
      # =============================================================================
      bindkey -v
      export KEYTIMEOUT=1
      
      # Smart word characters for enhanced navigation
      WORDCHARS='~!#$%^&*(){}[]<>?.+;-'
      MOTION_WORDCHARS='~!#$%^&*(){}[]<>?.+;'
      
      # Enhanced word movement functions
      function smart-backward-word() {
        local WORDCHARS="''${MOTION_WORDCHARS}"
        zle backward-word
      }
      function smart-forward-word() {
        local WORDCHARS="''${MOTION_WORDCHARS}"
        zle forward-word
      }
      zle -N smart-backward-word
      zle -N smart-forward-word

      # =============================================================================
      # Enhanced Vi Mode Visual Feedback System
      # =============================================================================
      function zle-keymap-select {
        case $KEYMAP in
          vicmd|NORMAL)
            echo -ne '\e[1 q'  # Block cursor for command mode
            ;;
          viins|INSERT|main)
            echo -ne '\e[5 q'  # Beam cursor for insert mode
            ;;
        esac
      }
      
      function zle-line-init {
        echo -ne '\e[5 q'  # Beam cursor on new line
      }
      
      zle -N zle-keymap-select
      zle -N zle-line-init

      # =============================================================================
      # Smart History Navigation System
      # =============================================================================
      autoload -U up-line-or-beginning-search down-line-or-beginning-search
      zle -N up-line-or-beginning-search
      zle -N down-line-or-beginning-search
      
      # Vi mode history navigation
      bindkey -M vicmd "k" up-line-or-beginning-search
      bindkey -M vicmd "j" down-line-or-beginning-search
      bindkey -M vicmd '?' history-incremental-search-backward
      bindkey -M vicmd '/' history-incremental-search-forward
      bindkey -M vicmd 'n' history-search-forward
      bindkey -M vicmd 'N' history-search-backward
      
      # Insert mode history (arrow keys and Ctrl shortcuts)
      bindkey -M viins "^[[A" up-line-or-beginning-search
      bindkey -M viins "^[[B" down-line-or-beginning-search
      bindkey -M viins "^P" up-line-or-beginning-search
      bindkey -M viins "^N" down-line-or-beginning-search

      # =============================================================================
      # Enhanced Navigation Key Bindings
      # =============================================================================
      # Line movement shortcuts
      bindkey -M vicmd 'H' beginning-of-line
      bindkey -M vicmd 'L' end-of-line
      bindkey -M viins '^A' beginning-of-line
      bindkey -M viins '^E' end-of-line
      
      # Word movement (Ctrl+arrows for both modes)
      bindkey -M vicmd '^[[1;5C' smart-forward-word
      bindkey -M viins '^[[1;5C' smart-forward-word
      bindkey -M vicmd '^[[1;5D' smart-backward-word
      bindkey -M viins '^[[1;5D' smart-backward-word
      
      # Alt+arrows for word movement alternative
      bindkey -M viins '^[f' smart-forward-word
      bindkey -M viins '^[b' smart-backward-word

      # =============================================================================
      # Enhanced Editing Key Bindings
      # =============================================================================
      # Vi mode enhancements
      bindkey -M vicmd 'Y' vi-yank-eol
      bindkey -M vicmd 'v' edit-command-line
      bindkey -M vicmd 'gg' beginning-of-buffer-or-history
      bindkey -M vicmd 'G' end-of-buffer-or-history
      
      # Insert mode editing shortcuts
      bindkey -M viins '^?' backward-delete-char
      bindkey -M viins '^H' backward-delete-char
      bindkey -M viins '^U' backward-kill-line
      bindkey -M viins '^K' kill-line
      bindkey -M viins '^Y' yank
      
      # Smart word deletion function
      function smart-backward-kill-word() {
        local WORDCHARS="''${WORDCHARS//:}"
        WORDCHARS="''${WORDCHARS//\/}"
        WORDCHARS="''${WORDCHARS//.}"
        WORDCHARS="''${WORDCHARS//-}"
        zle backward-kill-word
      }
      zle -N smart-backward-kill-word
      bindkey -M viins '^W' smart-backward-kill-word
      bindkey -M vicmd '^W' smart-backward-kill-word
      
      # Autosuggestion bindings
      bindkey -M viins '^F' autosuggest-accept
      bindkey -M viins '^L' autosuggest-accept
      bindkey -M viins '^[[Z' autosuggest-execute  # Shift+Tab

      # =============================================================================
      # FZF Integration Key Bindings
      # =============================================================================
      if command -v fzf > /dev/null; then
        # Enhanced FZF bindings for both modes
        bindkey -M viins '^T' fzf-file-widget       # Ctrl+T: Files
        bindkey -M viins '^R' fzf-history-widget    # Ctrl+R: History
        bindkey -M viins '^[c' fzf-cd-widget        # Alt+C: Directories
        
        # Vi command mode FZF bindings
        bindkey -M vicmd '^T' fzf-file-widget
        bindkey -M vicmd '^R' fzf-history-widget
        bindkey -M vicmd '^[c' fzf-cd-widget
      fi

      # =============================================================================
      # Terminal Integration Key Bindings
      # =============================================================================
      # Clear screen for both modes
      bindkey -M viins '^L' clear-screen
      bindkey -M vicmd '^L' clear-screen
      
      # Suspend/Resume functionality
      bindkey -M viins '^Z' push-input
      bindkey -M vicmd '^Z' push-input

      # =============================================================================
      # ZSH Completion System for Transmission CLI
      # =============================================================================
      _tsm_completions() {
          local commands=(
              # Core transmission commands
              "list:Display torrent list with status information"
              "add:Add new torrent from file or magnet link"
              "info:Show detailed information about specific torrent"
              "speed:Display current download/upload speeds"
              "files:List files contained in torrent"
              "config:Configure authentication credentials"
              
              # Search and discovery commands
              "search:Search for torrents by keyword"
              "search-cat:List available torrent categories"
              "search-recent:Search in recent torrents (last 48 hours)"
              
              # Individual torrent management
              "start:Start downloading specified torrent"
              "stop:Stop downloading specified torrent"
              "remove:Remove torrent from client (keep files)"
              "purge:Remove torrent and delete all files"
              
              # Batch operation commands
              "start-all:Start all torrents in queue"
              "stop-all:Stop all active torrents"
              "remove-all:Remove all torrents (keep files)"
              "purge-all:Remove all torrents and delete files"
              
              # Advanced management features
              "health:Check torrent health and connectivity"
              "stats:Show detailed client statistics"
              "disk:Check disk usage and available space"
              "tracker:Display tracker information and status"
              "limit:Set speed limits for downloads/uploads"
              "auto-remove:Enable automatic removal of completed torrents"
              "remove-done:Remove all completed torrents"
              
              # Priority and scheduling
              "priority:Set torrent priority (high/normal/low)"
              "schedule:Schedule torrent start/stop times"
              "tag:Add custom tags to torrents"
              "auto-tag:Automatically tag torrents by content type"
              
              # List management and filtering
              "list-sort:Sort torrent list by criteria"
              "list-filter:Filter torrents by specific conditions"
          )
          _describe 'tsm commands' commands
      }
      compdef _tsm_completions tsm

      # =============================================================================
      # File Manager Functions (Yazi Integration)
      # =============================================================================
      # Main Yazi wrapper function with directory change support
      function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }

      # Alternative Yazi function with 'k' command
      function k() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }

      # =============================================================================
      # Network Utility Functions
      # =============================================================================
      # Multi-source external IP detection function
      function wanip() {
        local ip
        # Try Mullvad first (privacy-focused)
        ip=$(curl -s https://am.i.mullvad.net/ip 2>/dev/null) && echo "Mullvad IP: $ip" && return 0
        # Fallback to OpenDNS
        ip=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null) && echo "OpenDNS IP: $ip" && return 0
        # Fallback to Google DNS
        ip=$(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com 2>/dev/null | tr -d '"') && echo "Google DNS IP: $ip" && return 0
        echo "Error: Could not determine external IP address"
        return 1
      }

      # File transfer function using transfer.sh service
      function transfer() {  
        if [ -z "$1" ]; then
          echo "Usage: transfer FILE_TO_TRANSFER"
          return 1
        fi
        tmpfile=$(mktemp -t transferXXX)
        curl --progress-bar --upload-file "$1" "https://transfer.sh/$(basename $1)" >> $tmpfile
        cat $tmpfile
        rm -f $tmpfile
      }

      # =============================================================================
      # File Editing Utility Functions
      # =============================================================================
      # Quick file editor with automatic creation and permissions
      function v() {
        local file="$1"
        if [[ -z "$file" ]]; then
          echo "Error: Filename required."
          return 1
        fi
        [[ ! -f "$file" ]] && touch "$file"
        chmod 755 "$file"
        vim -c "set paste" "$file"
      }

      # Edit command by path (which-edit)
      function vw() {
        local file
        if [[ -n "$1" ]]; then
          file=$(which "$1" 2>/dev/null)
          if [[ -n "$file" ]]; then
            echo "File found: $file"
            vim "$file"
          else
            echo "File not found: $1"
          fi
        else
          echo "Usage: vw <command-name>"
        fi
      }

      # =============================================================================
      # Archive Management Functions
      # =============================================================================
      # Universal archive extraction function
      function ex() {
        if [ -f $1 ] ; then
          case $1 in
            *.tar.bz2)   tar xjf $1   ;;
            *.tar.gz)    tar xzf $1   ;;
            *.bz2)       bunzip2 $1   ;;
            *.rar)       unrar x $1   ;;
            *.gz)        gunzip $1    ;;
            *.tar)       tar xf $1    ;;
            *.tbz2)      tar xjf $1   ;;
            *.tgz)       tar xzf $1   ;;
            *.zip)       unzip $1     ;;
            *.Z)         uncompress $1;;
            *.7z)        7z x $1      ;;
            *.deb)       ar x $1      ;;
            *.tar.xz)    tar xf $1    ;;
            *.tar.zst)   tar xf $1    ;;
            *)           echo "'$1' cannot be extracted with ex()" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }

      # =============================================================================
      # FZF Enhanced Search Functions
      # =============================================================================
      # File content search with preview
      function fif() {
        if [ ! "$#" -gt 0 ]; then echo "Search term required"; return 1; fi
        fd --type f --hidden --follow --exclude .git \
        | fzf -m --preview="bat --style=numbers --color=always {} 2>/dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
      }

      # Directory history search
      function fcd() {
        local dir
        dir=$(dirs -v | fzf --height 40% --reverse | cut -f2-)
        if [[ -n "$dir" ]]; then
          cd "$dir"
        fi
      }

      # Git commit search and checkout
      function fgco() {
        local commits commit
        commits=$(git log --pretty=oneline --abbrev-commit --reverse) &&
        commit=$(echo "$commits" | fzf --tac +s +m -e) &&
        git checkout $(echo "$commit" | sed "s/ .*//")
      }

      # Quick commit function (English single-line message)
      function gc() {
        if [ -z "$1" ]; then
          echo "Usage: gc <commit-message>"
          echo "Example: gc 'fix: resolve login issue'"
          return 1
        fi
        git add -A && git commit -m "$1"
      }

      # Interactive commit message function
      function gci() {
        git add -A
        echo "Enter commit message (English, single line):"
        read -r message
        if [ -n "$message" ]; then
          git commit -m "$message"
        else
          echo "Commit cancelled: empty message"
          return 1
        fi
      }

      # =============================================================================
      # History Management Function
      # =============================================================================
      function cleanhistory() {
        print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +m --height 50% --reverse --border --header="DEL key to delete selected command, ESC to exit" \
        --bind="del:execute(sed -i '/{}/d' $HISTFILE)+reload(fc -R; ([ -n "$ZSH_NAME" ] && fc -l 1 || history))" \
        --preview="echo {}" --preview-window=up:3:hidden:wrap --bind="?:toggle-preview")
      }

      # =============================================================================
      # Session Management Functions (Sesh Integration)
      # =============================================================================
      # Enhanced session manager with FZF integration
      if ! typeset -f sesh-sessions > /dev/null; then
        function sesh-sessions() {
          {
            exec </dev/tty
            exec <&1
            local session
            session=$(sesh list -t -c | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ')
            zle reset-prompt > /dev/null 2>&1 || true
            [[ -z "$session" ]] && return
            sesh connect $session
          }
        }
        zle -N sesh-sessions
      fi
      
      # Sesh session management key bindings
      bindkey -M viins '^[s' sesh-sessions    # Alt+S in insert mode
      bindkey -M vicmd '^[s' sesh-sessions    # Alt+S in command mode
      bindkey -M viins '\es' sesh-sessions    # Alternative Alt+S binding
      bindkey -M vicmd '\es' sesh-sessions    # Alternative Alt+S binding

      # =============================================================================
      # Nix Package Management Functions
      # =============================================================================
      # Simple dependency viewer for Nix packages
      function nix_depends() {
        if [ -z "$1" ]; then
          echo "Usage: nix_depends <package-name>"
          return 1
        fi
        nix-store --query --referrers $(which "$1" 2>/dev/null || echo "/run/current-system/sw/bin/$1")
      }

      # Detailed dependency analysis for Nix packages
      function nix_deps() {
        if [ -z "$1" ]; then
          echo "Usage: nix_deps <package-name>"
          return 1
        fi
        
        echo "Direct dependencies:"
        nix-store -q --references $(which "$1" 2>/dev/null || echo "/run/current-system/sw/bin/$1")
        
        echo -e "\nReverse dependencies (packages depending on this):"
        nix-store -q --referrers $(which "$1" 2>/dev/null || echo "/run/current-system/sw/bin/$1")
        
        echo -e "\nRuntime dependencies:"
        nix-store -q --requisites $(which "$1" 2>/dev/null || echo "/run/current-system/sw/bin/$1")
      }

      # =============================================================================
      # Nix Cleanup and Maintenance Functions
      # =============================================================================
      
      # Quick Nix cleanup alias
      alias nxc="nix-collect-garbage -d && nix-store --gc"

      # Comprehensive Nix cleanup function
      function nix_clean() {
        echo "🧹 Starting comprehensive Nix cleanup..."
        
        # Clean unnecessary GC roots
        echo "📂 Cleaning unnecessary GC roots..."
        nix-store --gc --print-roots | \
          egrep -v "^(/nix/var|/run/\w+-system|\{memory|/proc)" | \
          awk '{ print $1 }' | \
          grep -vE 'home-manager|flake-registry\.json' | \
          xargs -L1 unlink 2>/dev/null || true
        
        # Run garbage collection
        echo "🗑️  Running garbage collection..."
        nix-collect-garbage -d
        
        # Optimize store
        echo "⚡ Optimizing store..."
        nix-store --optimise
        
        echo "✅ Comprehensive cleanup completed!"
        
        # Post-cleanup information
        echo "📊 Post-cleanup status:"
        du -sh /nix/store 2>/dev/null || echo "Store size calculation failed"
      }

      # Safe Nix cleanup with preview
      function nix_clean_preview() {
        echo "🔍 Previewing GC roots to be deleted..."
        local roots_to_delete
        roots_to_delete=$(nix-store --gc --print-roots | \
          egrep -v "^(/nix/var|/run/\w+-system|\{memory|/proc)" | \
          awk '{ print $1 }' | \
          grep -vE 'home-manager|flake-registry\.json')
        
        if [[ -z "$roots_to_delete" ]]; then
          echo "✅ No unnecessary GC roots found for deletion."
        else
          echo "📋 GC roots to be deleted:"
          echo "$roots_to_delete"
          echo ""
        fi
        
        # Garbage collection preview
        echo "🗑️  Garbage collection simulation..."
        nix-collect-garbage -d --dry-run
        
        echo ""
        echo -n "🤔 Do you want to proceed with cleanup? (y/N): "
        read answer
        if [[ $answer == "y" || $answer == "Y" ]]; then
          nix_clean
        else
          echo "❌ Cleanup cancelled."
        fi
      }

      # Nix store size analysis
      function nix_store_size() {
        echo "📊 Nix Store Analysis:"
        echo "├─ Total store size: $(du -sh /nix/store 2>/dev/null | cut -f1 || echo 'Cannot calculate')"
        echo "├─ Total package count: $(ls /nix/store | wc -l 2>/dev/null || echo 'Cannot calculate')"
        echo "├─ GC root count: $(nix-store --gc --print-roots | wc -l 2>/dev/null || echo 'Cannot calculate')"
        echo "└─ Old generation count: $(nix-env --list-generations | wc -l 2>/dev/null || echo 'Cannot calculate')"
      }

      # Nix profile cleanup
      function nix_profile_clean() {
        echo "🔄 Cleaning Nix profiles..."
        
        # User profile generations
        echo "👤 User profile generations:"
        nix-env --list-generations
        
        echo -n "🤔 Do you want to delete old generations? (y/N): "
        read answer
        if [[ $answer == "y" || $answer == "Y" ]]; then
          nix-env --delete-generations old
          echo "✅ Old generations deleted."
        fi
        
        # System profile (if NixOS)
        if command -v nixos-rebuild >/dev/null 2>&1; then
          echo "🖥️  Cleaning system profile generations..."
          sudo nix-collect-garbage -d
          echo "✅ System profile cleaned."
        fi
      }
    '';
  };
}
