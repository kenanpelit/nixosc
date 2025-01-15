# modules/core/ssh/default.nix
{ pkgs, lib, ... }: {
  programs.ssh = {
    startAgent = false;  # GPG agent kullanacağımız için false yapıyoruz
    enableAskPassword = false;
    extraConfig = ''
      Host *
        ServerAliveInterval 60
        ServerAliveCountMax 2
    '';
  };
  environment.variables = {
    ASSH_CONFIG = "$HOME/.ssh/assh.yml";
  };
  environment.shellAliases = {
    assh = "${pkgs.assh}/bin/assh";
    sshconfig = "${pkgs.assh}/bin/assh config build > ~/.ssh/config";
  };
}
