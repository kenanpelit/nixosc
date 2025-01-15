{ pkgs, ... }:
{
  # Terminal emulators
  programs = {
    wezterm.enable = false;  # Geçici olarak devre dışı
    kitty.enable = true;

    # Shell ve araçları
    zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
    };

    # Temel araçlar
    bat.enable = true;
    fzf.enable = true;
    htop.enable = true;
    ripgrep.enable = true;
    tmux.enable = true;

    # Git yapılandırması
    git = {
      enable = true;
      delta.enable = true;
      lfs.enable = true;
    };
  };
}
