# ssh.nix
{ pkgs, lib, ... }: {
  # SSH yapılandırması
  programs.ssh = {
    startAgent = true;
    enableAskPassword = false;
    extraConfig = ''
      Host *
        ServerAliveInterval 60
        ServerAliveCountMax 2
    '';
  };

  # SSH ile ilgili paketler
  environment.systemPackages = with pkgs; [
    assh
    openssh
  ];

  # SSH ile ilgili çevre değişkenleri
  environment.variables = {
    ASSH_CONFIG = "$HOME/.ssh/assh.yml";
  };

  # SSH ile ilgili alias'lar
  environment.shellAliases = {
    assh = "${pkgs.assh}/bin/assh";
  };
}
