{ pkgs, lib, ... }: {
  programs.dconf.enable = true;
  programs.zsh.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Vim'i kapatıyoruz
  programs.vim = {
    enable = false;
  };

  # nano'yu da kapatıyoruz
  programs.nano.enable = false;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [ ];

  # Sistem genelinde varsayılan editörü ayarlama
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  environment.systemPackages = with pkgs; [
    assh
    xclip
    wl-clipboard
    neovim  # sistem genelinde neovim'i yüklüyoruz
  ];
}
