# modules/home/zsh/zsh_history.nix
{ config, lib, pkgs, ... }:

{
  home.file.".config/zsh/history" = {
    source = ./history;  # Aynı dizindeki history dosyasını kullanır
    onChange = ''
      chmod 644 ~/.config/zsh/history
    '';
  };
}
