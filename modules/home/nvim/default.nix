# ==============================================================================
# Neovim Konfigürasyonu - LazyVim Edition
# ==============================================================================
{ config, pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;

    # LSP sunucuları ve gerekli araçlar için
    extraPackages = with pkgs; [
      # LSP Sunucuları
      nodePackages.typescript-language-server
      nodePackages.vscode-json-languageserver
      lua-language-server
      nil # Nix LSP

      # Gerekli araçlar
      ripgrep
      fd
      git
      nodejs
      tree-sitter
    ];

    extraConfig = ''
      " Sistem panosu ile entegrasyon
      set clipboard+=unnamedplus
      " Wayland pano entegrasyonu
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
      " LazyVim bootstrap
      lua << EOF
      local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      if not vim.loop.fs_stat(lazypath) then
        vim.fn.system({
          "git",
          "clone",
          "--filter=blob:none",
          "https://github.com/folke/lazy.nvim.git",
          "--branch=stable",
          lazypath,
        })
      end
      vim.opt.rtp:prepend(lazypath)

      require("lazy").setup({
        spec = {
          { "LazyVim/LazyVim", import = "lazyvim.plugins" },
          { import = "lazyvim.plugins.extras.lang.typescript" },
          { import = "lazyvim.plugins.extras.lang.json" },
          { import = "lazyvim.plugins.extras.util.mini-hipatterns" },
          { import = "lazyvim.plugins.extras.lsp.none-ls" },
          { "williamboman/mason.nvim" },
          { "williamboman/mason-lspconfig.nvim" },
          { "neovim/nvim-lspconfig" },
        },
        defaults = {
          lazy = false,
          version = false,
        },
        checker = { enabled = true },
        performance = {
          rtp = {
            disabled_plugins = {
              "gzip",
              "tarPlugin",
              "tohtml",
              "tutor",
              "zipPlugin",
            },
          },
        },
      })
      
      -- Mason kurulumu
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "jsonls",    -- JSON
          "tsserver",  -- TypeScript
          "lua_ls",    -- Lua
          "nil_ls",    -- Nix
        },
        automatic_installation = true,
      })

      -- LazyVim ayarları
      require("lazyvim.config").init({
        colorscheme = "tokyonight",
        defaults = {
          autocmds = true,
          keymaps = true,
        },
        icons = {
          diagnostics = {
            Error = " ",
            Warn = " ",
            Hint = " ",
            Info = " ",
          },
          git = {
            added = " ",
            modified = " ",
            removed = " ",
          },
        },
      })
      EOF
    '';
  };
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    GIT_EDITOR = "nvim";
  };
}
