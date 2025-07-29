# modules/home/zsh/zsh_aliases.nix
{ hostname, config, pkgs, host, lib, ... }:
{
  programs.zsh = {
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
      path = "echo -e ''${PATH//:/\\\\n}";
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
      top = "btop";                # btop
      htop = "btop";
      du = "dust";                 # dust
      
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
      # Git Shortcuts (Enhanced)
      # =============================================================================
      g = "git";
      gs = "git status -sb";
      ga = "git add";
      gaa = "git add -A";
      gc = "git commit -m";
      gca = "git commit -am";
      gp = "git push";
      gpl = "git pull";
      gl = "git log --oneline -10";
      gd = "git diff";
      gds = "git diff --staged";
      gb = "git branch";
      gco = "git checkout";
      gcb = "git checkout -b";
      gm = "git merge";
      gr = "git remote -v";
      gst = "git stash";
      gstp = "git stash pop";
      
      # Advanced git
      glog = "git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative";
      gundo = "git reset --soft HEAD~1";
      greset = "git reset --hard HEAD";

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
      localip = "ip route get 8.8.8.8 | awk '{print $7; exit}'";
      ports = "netstat -tulanp";

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
      
      # Docker (if available)
      d = "docker";
      dc = "docker-compose";
      dps = "docker ps";
      dpsa = "docker ps -a";
      di = "docker images";
      dex = "docker exec -it";
      dlog = "docker logs -f";
      
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
      # NixOS Management (Enhanced)
      # =============================================================================
      osc = "cd ~/.nixosc";
      
      # Nix shell
      ns = "nom-shell --run zsh";
      ndev = "nix develop --command zsh";  # Modern nix develop
      
      # System management
      nix-switch = "nh os switch --ask";     # Ask before switching
      nix-update = "nh os switch --update --ask";
      nix-test = "nh os test";
      nix-boot = "nh os boot";               # Build but don't switch
      nix-clean = "nh clean all --keep 5";
      nix-cleanup = "nix-collect-garbage -d && nix-store --optimise";
      
      # Search and info
      nix-search = "nh search";
      nst = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}'";
      ninfo = "nix-info -m";                 # System info
      
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
      extract = "aunpack";           # Use atool
      compress = "apack";
      
      # Quick edits
      zshrc = "nvim ~/.nixosc/modules/home/zsh/zsh.nix";
      
      # Calendar and time
      cal = "cal -3";                # Show 3 months
      week = "date +%V";             # Week number
      
      # Quick server
      serve = "python3 -m http.server 8000";
      
      # Clipboard (if available)
      copy = "xclip -selection clipboard";
      paste = "xclip -selection clipboard -o";
      
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
      colors = "for i in {0..255}; do print -Pn \"%K{$i}  %k%F{$i}$'{i:3d}'%f \" $'{i%16==15?\"\\n\":\"\"}'; done";
    };
  };
}

