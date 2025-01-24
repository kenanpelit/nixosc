# modules/home/terminal/zsh/zsh_completions/default.nix
{ config, ... }:
{
  home.file = {
    #".config/zsh/completions/_iwctl".source = ./_iwctl;
    ".config/zsh/completions/_assh".source = ./_assh;
    # Diğer completion dosyaları için:
    # ".config/zsh/completions/other-completion.zsh".source = ./other-completion.zsh;
  };

  programs.zsh.initExtra = ''
    fpath+=~/.config/zsh/completions
    autoload -Uz compinit && compinit
  '';
}

