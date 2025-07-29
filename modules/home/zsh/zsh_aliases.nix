# modules/home/zsh/zsh_aliases.nix
# ==============================================================================
# ZSH Shell Aliases - Core System Utilities Only
# ==============================================================================
{ hostname, config, pkgs, host, ... }:
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
  };
}

