{ pkgs, lib, ... }: {
  programs = {
    # dconf ve zsh ayarları
    dconf.enable = true;
    zsh.enable = true;
    
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
