# modules/home/zsh/zsh_unified.nix
# ==============================================================================
# Zsh unified config fragment: aliases/helpers (core utils, media, nix, podman),
# extra functions, vi-mode tweaks, and FZF integrations.
# Keeps shell conveniences centralized instead of scattered snippets.
# ==============================================================================

{ lib, pkgs, config, ... }:
let
  cfg = config.my.user.zsh;
in
lib.mkIf cfg.enable {
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
      # Pipe Viewer (YouTube TUI) — Güncel ve Dayanıklı Kısayollar
      # =============================================================================
      pv-v = "pipe-viewer";                                  # Ana komut (eski 'pv')

      # Yardım / ipuçları
      pv-help = "pipe-viewer --help";
      pv-tricks = "pipe-viewer --tricks";
      pv-examples = "pipe-viewer --examples";

      # Hızlı arama / oynatma
      pv-search = "pipe-viewer --search-videos";             # Arama modu
      pv-play = "pipe-viewer --best --player=mpv";           # En iyi kalite mpv
      pv-audio = "pipe-viewer -n -a --audio-quality=best";   # Sadece ses
      pv-info = "pipe-viewer -i";                            # Video bilgisi (ID/URL ver)
      pv-comments = "pipe-viewer --comments";                # Yorumlar (ID/URL ver)

      # Çözünürlük / biçim
      pv-240 = "pipe-viewer -2";
      pv-360 = "pipe-viewer -3";
      pv-480 = "pipe-viewer -4";
      pv-720 = "pipe-viewer -7";
      pv-1080 = "pipe-viewer -1";
      pv-4k = "pipe-viewer --resolution=2160p";
      pv-best = "pipe-viewer --best";
      pv-mp4 = "pipe-viewer --prefer-mp4 --ignore-av1";
      pv-av1 = "pipe-viewer --prefer-av1";
      pv-m4a = "pipe-viewer --prefer-m4a";
      pv-hfr = "pipe-viewer --hfr";

      # Filtreler
      pv-short = "pipe-viewer --duration=short";
      pv-long = "pipe-viewer --duration=long";
      pv-today = "pipe-viewer --time=today";
      pv-week = "pipe-viewer --time=week";
      pv-month = "pipe-viewer --time=month";
      pv-order-new = "pipe-viewer --order=upload_date";
      pv-order-views = "pipe-viewer --order=view_count";
      pv-cc = "pipe-viewer --captions";
      pv-live = "pipe-viewer --live";
      pv-hdr = "pipe-viewer --hdr";
      pv-360deg = "pipe-viewer --360";
      pv-3d = "pipe-viewer --dimension=3d";

      # Kanal / Liste
      pv-ch = "pipe-viewer -sc";                             # Kanal ara
      pv-uploads = "pipe-viewer -uv";                        # Kanal yüklemeleri
      pv-streams = "pipe-viewer -us";                        # Kanal canlıları
      pv-shorts = "pipe-viewer --shorts";                    # Kanal shorts
      pv-pl-search = "pipe-viewer -sp";                      # Playlist ara
      pv-pl = "pipe-viewer --pid";                           # Playlist ID listele
      pv-pl-play = "pipe-viewer --pp";                       # Playlist(ler)i oynat

      # Trendler — En sağlam (Invidious kapalı + yt-dlp)
      pv-trend        = "pipe-viewer --no-invidious --ytdl --trending=popular --region=TR";
      pv-trend-music  = "pipe-viewer --no-invidious --ytdl --trending=music --region=TR";
      pv-trend-gaming = "pipe-viewer --no-invidious --ytdl --trending=gaming --region=TR";
      pv-trend-news   = "pipe-viewer --no-invidious --ytdl --trending=news --region=TR";
      pv-trend-movies = "pipe-viewer --no-invidious --ytdl --trending=movies --region=TR";

      # Davranış / oynatıcı
      pv-mpv = "pipe-viewer --player=mpv";
      pv-vlc = "pipe-viewer --player=vlc";
      pv-fs = "pipe-viewer --fullscreen";
      pv-shuffle = "pipe-viewer --shuffle";
      pv-all = "pipe-viewer --all";
      pv-backwards = "pipe-viewer --backwards";
      pv-auto = "pipe-viewer --autoplay";
      pv-interactive = "pipe-viewer --interactive";

      # İndirme
      pv-dl = "pipe-viewer -d";
      pv-dl-audio = "pipe-viewer -d -n -a --convert-to=mp3";
      pv-dl-mp4 = "pipe-viewer -d --prefer-mp4 --mkv-merge";
      pv-dl-skip = "pipe-viewer -d --skip-if-exists";
      pv-dl-subdir = "pipe-viewer -d --dl-in-subdir";
      pv-dl-name = "pipe-viewer -d --filename='%T - %t.%e'";

      # Yerel kayıtlar
      pv-favs = "pipe-viewer -F";
      pv-likes = "pipe-viewer -L";
      pv-dislikes = "pipe-viewer -D";
      pv-subs = "pipe-viewer -S";
      pv-saved = "pipe-viewer -lc";
      pv-like = "pipe-viewer --like";
      pv-dislike = "pipe-viewer --dislike";
      pv-fav = "pipe-viewer --favorite";
      pv-save = "pipe-viewer --save";
      pv-sub = "pipe-viewer --subscribe";

      # Sessizlik / çıktı
      pv-quiet = "pipe-viewer -q";
      pv-rquiet = "pipe-viewer --really-quiet";
      pv-vinfo = "pipe-viewer --video-info";

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
      
    };

    initContent = lib.mkAfter ''
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
      # Pipe Viewer — Akıllı Fonksiyonlar (fallback'lı, Nix-safe)
      # =============================================================================
      export PV_CMD="pipe-viewer"

      # pv-tr <kategori> [bölge]
      # kategori: popular | music | gaming | news | movies
      pv-tr() {
        local cat="$1"
        local region="$2"
        [ -z "$cat" ] && cat="popular"
        [ -z "$region" ] && region="TR"

        "$PV_CMD" --invidious --api=auto --trending="$cat" --region="$region" \
        || "$PV_CMD" --no-invidious --ytdl --trending="$cat" --region="$region"
      }

      # pv-find "anahtar kelimeler" [ek pipe-viewer argümanları...]
      pv-find() {
        if [ -z "$1" ]; then
          echo "Usage: pv-find \"keywords\" [extra pipe-viewer opts]"; return 1
        fi
        local q="$1"; shift
        "$PV_CMD" --no-invidious --ytdl --search-videos "$q" "$@"
      }

      # pv-playx [--best | --resolution=720p | ...] "<url|keywords>" [ek opsiyonlar...]
      # URL ise direkt oynatır; değilse arayıp listeler.
      pv-playx() {
        local opts=()
        while [ -n "$1" ] && printf "%s" "$1" | grep -qE '^--'; do
          opts+=( "$1" )
          shift
        done

        if [ -z "$1" ]; then
          echo "Usage: pv-playx [--best|--resolution=...] <url|keywords> [extra opts]"; return 1
        fi

        local input="$1"; shift
        if printf "%s" "$input" | grep -qE '^https?://|(^| )youtu(\.be|be\.com)'; then
          "$PV_CMD" --no-invidious --ytdl "''${opts[@]}" "$input" "$@"
        else
          "$PV_CMD" --no-invidious --ytdl --search-videos "''${opts[@]}" "$input" "$@"
        fi
      }

      # pv-audiox "<url|keywords>" [--audio-quality=best|medium|low]
      pv-audiox() {
        if [ -z "$1" ]; then
          echo "Usage: pv-audiox <url|keywords> [--audio-quality=best|medium|low]"; return 1
        fi
        local input="$1"; shift
        if printf "%s" "$input" | grep -qE '^https?://'; then
          "$PV_CMD" --no-invidious --ytdl -n -a --audio-quality=best "$input" "$@"
        else
          "$PV_CMD" --no-invidious --ytdl -n -a --audio-quality=best --search-videos "$input" "$@"
        fi
      }

      # pv-dlx [--dir="..."] [--name="%T - %t.%e"] <url|keywords>
      # Ör: pv-dlx --dir="$HOME/Videos" --name="%T - %t.%e" "linux news"
      pv-dlx() {
        local dldir="."
        local namefmt="%T - %t.%e"
        local args=()

        while [ -n "$1" ] && printf "%s" "$1" | grep -qE '^--'; do
          case "$1" in
            --dir=*)
              dldir="$(printf "%s" "$1" | sed 's/^--dir=//')"
              ;;
            --name=*)
              namefmt="$(printf "%s" "$1" | sed 's/^--name=//')"
              ;;
            *)
              args+=( "$1" )
              ;;
          esac
          shift
        done

        if [ -z "$1" ]; then
          echo "Usage: pv-dlx [--dir=DIR] [--name=FMT] <url|keywords>"; return 1
        fi

        local input="$1"; shift
        mkdir -p "$dldir"

        if printf "%s" "$input" | grep -qE '^https?://'; then
          "$PV_CMD" --no-invidious --ytdl -d --skip-if-exists --dl-in-subdir \
            --downloads-dir="$dldir" --filename="$namefmt" "$input" "$@" "''${args[@]}"
        else
          "$PV_CMD" --no-invidious --ytdl -d --skip-if-exists --dl-in-subdir \
            --downloads-dir="$dldir" --filename="$namefmt" --search-videos "$input" "$@" "''${args[@]}"
        fi
      }

      # pv-commentsx <id|url> [relevance|time]
      pv-commentsx() {
        if [ -z "$1" ]; then
          echo "Usage: pv-commentsx <video-id|url> [relevance|time]"; return 1
        fi
        local target="$1"
        local order="$2"
        [ -z "$order" ] && order="relevance"

        "$PV_CMD" --comments="$target" --comments-order="$order" \
        || "$PV_CMD" --ytdl --comments="$target" --comments-order="$order"
      }

      # pv-plx list|play <playlist-id>
      pv-plx() {
        if [ "$1" != "list" ] && [ "$1" != "play" ]; then
          echo "Usage: pv-plx list|play <playlist-id>"; return 1
        fi
        local mode="$1"; shift
        local pid="$1"

        if [ -z "$pid" ]; then
          echo "Missing <playlist-id>"; return 1
        fi

        if [ "$mode" = "list" ]; then
          "$PV_CMD" --pid="$pid"
        else
          "$PV_CMD" --no-invidious --ytdl --pp="$pid"
        fi
      }

      # pv-chx <channel|@handle> uploads|streams|shorts|popular|pstreams|pshorts
      pv-chx() {
        if [ -z "$1" ] || [ -z "$2" ]; then
          echo "Usage: pv-chx <channel> <uploads|streams|shorts|popular|pstreams|pshorts>"; return 1
        fi
        local ch="$1"
        local mode="$2"

        case "$mode" in
          uploads)   "$PV_CMD" -uv "$ch" ;;
          streams)   "$PV_CMD" -us "$ch" ;;
          shorts)    "$PV_CMD" --shorts "$ch" ;;
          popular)   "$PV_CMD" -pv "$ch" ;;
          pstreams)  "$PV_CMD" -ps "$ch" ;;
          pshorts)   "$PV_CMD" --pshorts "$ch" ;;
          *) echo "Invalid mode: $mode"; return 1 ;;
        esac
      }

      # pv-reg <ISO-REGION>  (ör: pv-reg TR)
      pv-reg() {
        if [ -z "$1" ]; then
          echo "Usage: pv-reg <REGION>"; return 1
        fi
        local region="$1"
        "$PV_CMD" --no-invidious --ytdl --trending=popular --region="$region" \
        || "$PV_CMD" --invidious --api=auto --trending=popular --region="$region"
      }

      # pv-open ...  → pipe-viewer'a argümanları doğrudan geçir
      pv-open() {
        if [ "$#" -eq 0 ]; then
          "$PV_CMD" --help
          return 0
        fi
        "$PV_CMD" "$@"
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

    initExtra = ''
      # download_nixpkgs_cache_index: pull prebuilt nix-index db manually
      download_nixpkgs_cache_index() {
        local arch="$(uname -m | sed 's/^arm64$/aarch64/')"
        local os="$(uname | tr 'A-Z' 'a-z')"
        local filename="index-$arch-$os"
        local cache="$HOME/.cache/nix-index"
        mkdir -p "$cache" && cd "$cache" || return
        if command -v wget >/dev/null 2>&1; then
          wget -q -N "https://github.com/nix-community/nix-index-database/releases/latest/download/${filename}"
        else
          curl -fL -O "https://github.com/nix-community/nix-index-database/releases/latest/download/${filename}"
        fi
        ln -sf "$filename" files
      }
    '';
  };
}
