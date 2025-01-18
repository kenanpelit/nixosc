# modules/home/zsh/zsh_aliases.nix
# ==============================================================================
# ZSH Shell Aliases
# ==============================================================================
{ hostname, config, pkgs, host, ... }:
{
  programs.zsh = {
    shellAliases = {
      # =============================================================================
      # Core Utilities
      # =============================================================================
      c = "clear";
      cd = "z";
      tt = "gtrash put";
      cat = "bat";
      diff = "delta --diff-so-fancy --side-by-side";
      less = "bat";
      yy = "yazi";
      py = "python";
      ipy = "ipython";
      icat = "kitten icat";
      dsize = "du -hs";
      pdf = "tdf";
      open = "xdg-open";
      space = "ncdu";
      man = "BAT_THEME='default' batman";

      # System Information
      df = "df -h";
      ip = "ip -color";
      free = "free -mt";
      hw = "hwinfo --short";
      psa = "ps auxf";
      psgrep = "ps aux | grep -v grep | grep -i -e VSZ -e";
      psmem = "ps auxf | sort -nr -k 4";
      psmem10 = "ps auxf | sort -nr -k 4 | head -10";
      jctl = "journalctl -p 3 -xb";
      microcode = "grep . /sys/devices/system/cpu/vulnerabilities/*";
      cpu = "cpuid -i | grep uarch | head -n 1";
      sysfailed = "systemctl list-units --failed";
      userlist = "cut -d: -f1 /etc/passwd | sort";

      # YTV
      ytv-best = ''yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" --merge-output-format mp4'';
      yt = ''yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" --merge-output-format mp4'';
      
      # Playlist İndirme
      ytp-mp3 = ''yt-dlp --yes-playlist --extract-audio --audio-format mp3 -o "%(playlist_index)s-%(title)s.%(ext)s"'';
      ytp-mp4 = ''yt-dlp --yes-playlist -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" --merge-output-format mp4 -o "%(playlist_index)s-%(title)s.%(ext)s"'';
      ytp-best = ''yt-dlp --yes-playlist -f "bestvideo+bestaudio" -o "%(playlist_index)s-%(title)s.%(ext)s"'';
    
      # =============================================================================
      # File Listing
      # =============================================================================
      l = "eza --icons  -a --group-directories-first -1"; 
      ll = "eza --icons  -a --group-directories-first -1 --no-user --long";
      tree = "eza --icons --tree --group-directories-first";

      # =============================================================================
      # NixOS Management
      # =============================================================================
      osc = "cd ~/.nixosc";
      ns = "nom-shell --run zsh";
      nix-switch = "nh os switch";
      nix-update = "nh os switch --update";
      nix-clean = "nh clean all --keep 5";
      nix-search = "nh search";
      nix-test = "nh os test";

      # =============================================================================
      # Python Development
      # =============================================================================
      piv = "python -m venv .venv";
      psv = "source .venv/bin/activate";

      # =============================================================================
      # Media Tools
      # =============================================================================
      youtube-dl = "yt-dlp";
    };
  };
}
