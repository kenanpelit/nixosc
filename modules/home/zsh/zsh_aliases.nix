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
