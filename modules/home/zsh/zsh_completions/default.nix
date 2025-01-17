# modules/home/zsh/completions/default.nix
{ config, ... }:
{
  programs.zsh.initExtra = ''
    ${builtins.readFile ./iwctl-completion.zsh}
  '';
}
