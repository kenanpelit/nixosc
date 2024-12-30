{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;  # Sistem genelinde varsayılan editör yap
    
    extraPackages = with pkgs; [
      xclip
      wl-clipboard
    ];

    extraConfig = ''
      set clipboard+=unnamedplus
      
      if executable('wl-copy')
        let g:clipboard = {
          \   'name': 'wl-clipboard',
          \   'copy': {
          \      '+': 'wl-copy',
          \      '*': 'wl-copy',
          \    },
          \   'paste': {
          \      '+': 'wl-paste',
          \      '*': 'wl-paste',
          \   },
          \   'cache_enabled': 0,
          \ }
      endif
    '';
  };

  # Sistem genelinde EDITOR değişkenini ayarla
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    GIT_EDITOR = "nvim";
  };
}
