{ hostname, config, pkgs, host, ... }:
{
  imports = [
    ./zsh.nix
    ./zsh_alias.nix
    ./zsh_functions.nix
    ./zsh_keybinds.nix
    ./completions
  ];
}
