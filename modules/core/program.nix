# configuration.nix
{ pkgs, lib, ... }: {
  programs = {
    # dconf ve zsh ayarları
    dconf.enable = true;
    zsh.enable = true;

    # GnuPG ayarı
    gnupg.agent = {
      enable = true;
      enableSSHSupport = false;
    };

    # Vim ve nano'yu devre dışı bırak
    vim.enable = false;
    nano.enable = false;

    # nix-ld yapılandırması
    nix-ld = {
      enable = true;
      libraries = with pkgs; [];
    };
  };
}
