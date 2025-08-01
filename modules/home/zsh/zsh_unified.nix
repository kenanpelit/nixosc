# modules/home/zsh/zsh.nix
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
      grep = "rg";                 # ripgrep
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
      
      # =============================================================================
      # Session Management Functions (Sesh)
      # =============================================================================
      sesh-c = "sesh connect";
      sesh-l = "sesh list";
      sesh-k = "sesh kill";
      sesh-r = "sesh last";

      # =============================================================================
      # Fun & Useful
      # =============================================================================
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
      # ---------------------------------------------------------------------------
      # Enhanced Vi Mode Setup
      # ---------------------------------------------------------------------------
      bindkey -v
      export KEYTIMEOUT=1
      
      # Smart word characters for better navigation
      WORDCHARS='~!#$%^&*(){}[]<>?.+;-'
      MOTION_WORDCHARS='~!#$%^&*(){}[]<>?.+;'
      
      # Enhanced word movement
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

      # ---------------------------------------------------------------------------
      # Enhanced Vi Mode Visual Feedback
      # ---------------------------------------------------------------------------
      function zle-keymap-select {
        case $KEYMAP in
          vicmd|NORMAL)
            echo -ne '\e[1 q'  # Block cursor
            ;;
          viins|INSERT|main)
            echo -ne '\e[5 q'  # Beam cursor
            ;;
        esac
      }
      
      function zle-line-init {
        echo -ne '\e[5 q'  # Beam cursor on new line
      }
      
      zle -N zle-keymap-select
      zle -N zle-line-init

      # ---------------------------------------------------------------------------
      # Smart History Navigation
      # ---------------------------------------------------------------------------
      autoload -U up-line-or-beginning-search down-line-or-beginning-search
      zle -N up-line-or-beginning-search
      zle -N down-line-or-beginning-search
      
      # Vi mode history
      bindkey -M vicmd "k" up-line-or-beginning-search
      bindkey -M vicmd "j" down-line-or-beginning-search
      bindkey -M vicmd '?' history-incremental-search-backward
      bindkey -M vicmd '/' history-incremental-search-forward
      bindkey -M vicmd 'n' history-search-forward
      bindkey -M vicmd 'N' history-search-backward
      
      # Insert mode history (arrow keys)
      bindkey -M viins "^[[A" up-line-or-beginning-search
      bindkey -M viins "^[[B" down-line-or-beginning-search
      bindkey -M viins "^P" up-line-or-beginning-search
      bindkey -M viins "^N" down-line-or-beginning-search

      # ---------------------------------------------------------------------------
      # Enhanced Navigation Bindings
      # ---------------------------------------------------------------------------
      # Line movement
      bindkey -M vicmd 'H' beginning-of-line
      bindkey -M vicmd 'L' end-of-line
      bindkey -M viins '^A' beginning-of-line
      bindkey -M viins '^E' end-of-line
      
      # Word movement (Ctrl+arrows)
      bindkey -M vicmd '^[[1;5C' smart-forward-word
      bindkey -M viins '^[[1;5C' smart-forward-word
      bindkey -M vicmd '^[[1;5D' smart-backward-word
      bindkey -M viins '^[[1;5D' smart-backward-word
      
      # Alt+arrows for word movement
      bindkey -M viins '^[f' smart-forward-word
      bindkey -M viins '^[b' smart-backward-word

      # ---------------------------------------------------------------------------
      # Enhanced Editing Bindings
      # ---------------------------------------------------------------------------
      # Vi mode enhancements
      bindkey -M vicmd 'Y' vi-yank-eol
      bindkey -M vicmd 'v' edit-command-line
      bindkey -M vicmd 'gg' beginning-of-buffer-or-history
      bindkey -M vicmd 'G' end-of-buffer-or-history
      
      # Insert mode editing
      bindkey -M viins '^?' backward-delete-char
      bindkey -M viins '^H' backward-delete-char
      bindkey -M viins '^U' backward-kill-line
      bindkey -M viins '^K' kill-line
      bindkey -M viins '^Y' yank
      
      # Smart word deletion
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
      
      # ---------------------------------------------------------------------------
      # FZF Integration Bindings
      # ---------------------------------------------------------------------------
      if command -v fzf > /dev/null; then
        # Enhanced FZF bindings
        bindkey -M viins '^T' fzf-file-widget       # Ctrl+T: Files
        bindkey -M viins '^R' fzf-history-widget    # Ctrl+R: History
        bindkey -M viins '^[c' fzf-cd-widget        # Alt+C: Directories
        
        # Vi mode FZF bindings
        bindkey -M vicmd '^T' fzf-file-widget
        bindkey -M vicmd '^R' fzf-history-widget
        bindkey -M vicmd '^[c' fzf-cd-widget
      fi

      # ---------------------------------------------------------------------------
      # Terminal Integration
      # ---------------------------------------------------------------------------
      # Clear screen
      bindkey -M viins '^L' clear-screen
      bindkey -M vicmd '^L' clear-screen
      
      # Suspend/Resume
      bindkey -M viins '^Z' push-input
      bindkey -M vicmd '^Z' push-input

      # =============================================================================
      # Dosya Yöneticisi Fonksiyonları
      # =============================================================================
      # Yazi sarmalayıcı fonksiyonu
      function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }

      # Alternatif Yazi fonksiyonu (k komutu ile)
      function k() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }

      # =============================================================================
      # Ağ Fonksiyonları
      # =============================================================================
      # Dış IP kontrol fonksiyonu
      function wanip() {
        local ip
        ip=$(curl -s https://am.i.mullvad.net/ip 2>/dev/null) && echo "Mullvad IP: $ip" && return 0
        ip=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null) && echo "OpenDNS IP: $ip" && return 0
        ip=$(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com 2>/dev/null | tr -d '"') && echo "Google DNS IP: $ip" && return 0
        echo "Hata: IP adresi belirlenemedi"
        return 1
      }

      # Dosya transfer fonksiyonu
      function transfer() {  
        if [ -z "$1" ]; then
          echo "Kullanım: transfer TRANSFER_EDILECEK_DOSYA"
          return 1
        fi
        tmpfile=$(mktemp -t transferXXX)
        curl --progress-bar --upload-file "$1" "https://transfer.sh/$(basename $1)" >> $tmpfile
        cat $tmpfile
        rm -f $tmpfile
      }

      # =============================================================================
      # Dosya Düzenleme Fonksiyonları
      # =============================================================================
      # Hızlı dosya düzenleyici
      function v() {
        local file="$1"
        if [[ -z "$file" ]]; then
          echo "Hata: Dosya adı gerekli."
          return 1
        fi
        [[ ! -f "$file" ]] && touch "$file"
        chmod 755 "$file"
        vim -c "set paste" "$file"
      }

      # Komut yolu düzenleme
      function vw() {
        local file
        if [[ -n "$1" ]]; then
          file=$(which "$1" 2>/dev/null)
          if [[ -n "$file" ]]; then
            echo "Dosya bulundu: $file"
            vim "$file"
          else
            echo "Dosya bulunamadı: $1"
          fi
        else
          echo "Kullanım: vwhich <dosya-adı>"
        fi
      }

      # =============================================================================
      # Arşiv Yönetimi Fonksiyonları
      # =============================================================================
      # Evrensel arşiv çıkarıcı
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
            *)           echo "'$1' ex() ile çıkarılamıyor" ;;
          esac
        else
          echo "'$1' geçerli bir dosya değil"
        fi
      }

      # =============================================================================
      # FZF Gelişmiş Fonksiyonları
      # =============================================================================
      # Dosya içeriği arama
      function fif() {
        if [ ! "$#" -gt 0 ]; then echo "Arama terimi gerekli"; return 1; fi
        fd --type f --hidden --follow --exclude .git \
        | fzf -m --preview="bat --style=numbers --color=always {} 2>/dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
      }

      # Dizin geçmişi arama
      function fcd() {
        local dir
        dir=$(dirs -v | fzf --height 40% --reverse | cut -f2-)
        if [[ -n "$dir" ]]; then
          cd "$dir"
        fi
      }

      # Git commit arama
      function fgco() {
        local commits commit
        commits=$(git log --pretty=oneline --abbrev-commit --reverse) &&
        commit=$(echo "$commits" | fzf --tac +s +m -e) &&
        git checkout $(echo "$commit" | sed "s/ .*//")
      }

      # Hızlı commit (tek satır İngilizce mesaj)
      function gc() {
        if [ -z "$1" ]; then
          echo "Usage: gc <commit-message>"
          echo "Example: gc 'fix: resolve login issue'"
          return 1
        fi
        git add -A && git commit -m "$1"
      }

      # İnteraktif commit mesajı
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
      # History temizleme fonksiyonu
      # =============================================================================
      function cleanhistory() {
        print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +m --height 50% --reverse --border --header="DEL tuşu ile seçili komutu sil, ESC ile çık" \
        --bind="del:execute(sed -i '/{}/d' $HISTFILE)+reload(fc -R; ([ -n "$ZSH_NAME" ] && fc -l 1 || history))" \
        --preview="echo {}" --preview-window=up:3:hidden:wrap --bind="?:toggle-preview")
      }

      # ---------------------------------------------------------------------------
      # Session Management Bindings (Sesh)
      # ---------------------------------------------------------------------------
      # Sesh session manager function (if not already defined elsewhere)
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
      
      # Sesh keybindings - Alt+S for session picker
      bindkey -M viins '^[s' sesh-sessions    # Alt+S in insert mode
      bindkey -M vicmd '^[s' sesh-sessions    # Alt+S in command mode
      bindkey -M viins '\es' sesh-sessions    # Alternative Alt+S binding
      bindkey -M vicmd '\es' sesh-sessions    # Alternative Alt+S binding

      # =============================================================================
      # Nix Paket Yönetimi Fonksiyonları
      # =============================================================================
      # Basit bağımlılık görüntüleyici
      function nix_depends() {
        if [ -z "$1" ]; then
          echo "Kullanım: nix_depends <paket-adı>"
          return 1
        fi
        nix-store --query --referrers $(which "$1" 2>/dev/null || echo "/run/current-system/sw/bin/$1")
      }

      # Detaylı bağımlılık görüntüleyici
      function nix_deps() {
        if [ -z "$1" ]; then
          echo "Kullanım: nix_deps <paket-adı>"
          return 1
        fi
        
        echo "Doğrudan bağımlılıklar:"
        nix-store -q --references $(which "$1" 2>/dev/null || echo "/run/current-system/sw/bin/$1")
        
        echo -e "\nTers bağımlılıklar (bu pakete bağımlı paketler):"
        nix-store -q --referrers $(which "$1" 2>/dev/null || echo "/run/current-system/sw/bin/$1")
        
        echo -e "\nÇalışma zamanı bağımlılıkları:"
        nix-store -q --requisites $(which "$1" 2>/dev/null || echo "/run/current-system/sw/bin/$1")
      }

      # =============================================================================
      # Nix Temizleme Fonksiyonları
      # =============================================================================
      
      # Hızlı Nix temizliği (alias)
      alias nxc="nix-collect-garbage -d && nix-store --gc"

      # Detaylı Nix temizliği fonksiyonu
      function nix_clean() {
        echo "🧹 Nix detaylı temizlik başlıyor..."
        
        # GC roots temizliği
        echo "📂 Gereksiz GC root'ları temizleniyor..."
        nix-store --gc --print-roots | \
          egrep -v "^(/nix/var|/run/\w+-system|\{memory|/proc)" | \
          awk '{ print $1 }' | \
          grep -vE 'home-manager|flake-registry\.json' | \
          xargs -L1 unlink 2>/dev/null || true
        
        # Garbage collection
        echo "🗑️  Garbage collection çalışıyor..."
        nix-collect-garbage -d
        
        # Store optimizasyonu
        echo "⚡ Store optimize ediliyor..."
        nix-store --optimise
        
        echo "✅ Detaylı temizlik tamamlandı!"
        
        # Temizlik sonrası bilgi
        echo "📊 Temizlik sonrası durum:"
        du -sh /nix/store 2>/dev/null || echo "Store boyutu hesaplanamadı"
      }

      # Güvenli Nix temizliği (önizleme ile)
      function nix_clean_preview() {
        echo "🔍 Silinecek GC root'ları önizleniyor..."
        local roots_to_delete
        roots_to_delete=$(nix-store --gc --print-roots | \
          egrep -v "^(/nix/var|/run/\w+-system|\{memory|/proc)" | \
          awk '{ print $1 }' | \
          grep -vE 'home-manager|flake-registry\.json')
        
        if [[ -z "$roots_to_delete" ]]; then
          echo "✅ Silinecek gereksiz GC root bulunamadı."
        else
          echo "📋 Silinecek GC roots:"
          echo "$roots_to_delete"
          echo ""
        fi
        
        # Garbage collection önizlemesi
        echo "🗑️  Garbage collection simülasyonu..."
        nix-collect-garbage -d --dry-run
        
        echo ""
        echo -n "🤔 Temizlik işlemini başlatmak istiyor musunuz? (y/N): "
        read answer
        if [[ $answer == "y" || $answer == "Y" ]]; then
          nix_clean
        else
          echo "❌ Temizlik iptal edildi."
        fi
      }

      # Nix store boyutu kontrolü
      function nix_store_size() {
        echo "📊 Nix Store Analizi:"
        echo "├─ Store toplam boyutu: $(du -sh /nix/store 2>/dev/null | cut -f1 || echo 'Hesaplanamadı')"
        echo "├─ Toplam paket sayısı: $(ls /nix/store | wc -l 2>/dev/null || echo 'Hesaplanamadı')"
        echo "├─ GC root sayısı: $(nix-store --gc --print-roots | wc -l 2>/dev/null || echo 'Hesaplanamadı')"
        echo "└─ Eski generasyon sayısı: $(nix-env --list-generations | wc -l 2>/dev/null || echo 'Hesaplanamadı')"
      }

      # Nix profil temizliği
      function nix_profile_clean() {
        echo "🔄 Nix profilleri temizleniyor..."
        
        # Kullanıcı profili generasyonları
        echo "👤 Kullanıcı profili generasyonları:"
        nix-env --list-generations
        
        echo -n "🤔 Eski generasyonları silmek istiyor musunuz? (y/N): "
        read answer
        if [[ $answer == "y" || $answer == "Y" ]]; then
          nix-env --delete-generations old
          echo "✅ Eski generasyonlar silindi."
        fi
        
        # Sistem profili (eğer NixOS kullanıyorsa)
        if command -v nixos-rebuild >/dev/null 2>&1; then
          echo "🖥️  Sistem profili generasyonları temizleniyor..."
          sudo nix-collect-garbage -d
          echo "✅ Sistem profili temizlendi."
        fi
      }
    '';
  };
}

