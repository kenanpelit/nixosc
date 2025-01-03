{ hostname, config, pkgs, host, ... }:
{
  imports = [
    ./zsh.nix
    ./zsh_alias.nix
    ./zsh_keybinds.nix
  ];
}
