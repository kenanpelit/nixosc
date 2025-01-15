# modules/home/nvim/defaults.nix
# ==============================================================================
# Neovim Configuration - LazyVim Edition
# ==============================================================================
{ config, pkgs, ... }:
{
  programs.neovim = {
    # =============================================================================
    # Basic Configuration
    # =============================================================================
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;

    # =============================================================================
    # Required Packages
    # =============================================================================
    extraPackages = with pkgs; [
      # ---------------------------------------------------------------------------
      # LSP Servers
      # ---------------------------------------------------------------------------
      nodePackages.typescript-language-server
      nodePackages.vscode-json-languageserver
      lua-language-server
      nil # Nix LSP

      # ---------------------------------------------------------------------------
      # Core Tools
      # ---------------------------------------------------------------------------
      ripgrep
      fd
      git
      nodejs
      tree-sitter
    ];

    # =============================================================================
    # Extended Configuration
    # =============================================================================
    extraConfig = ''
      # ---------------------------------------------------------------------------
      # Clipboard Integration
      # ---------------------------------------------------------------------------
      set clipboard+=unnamedplus
      
      # Wayland Clipboard Support
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

      # ---------------------------------------------------------------------------
      # LazyVim Setup
      # ---------------------------------------------------------------------------
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

      # ---------------------------------------------------------------------------
      # Plugin Configuration
      # ---------------------------------------------------------------------------
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
      
      # ---------------------------------------------------------------------------
      # Mason Configuration
      # ---------------------------------------------------------------------------
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

      # ---------------------------------------------------------------------------
      # LazyVim Settings
      # ---------------------------------------------------------------------------
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

  # =============================================================================
  # Environment Variables
  # =============================================================================
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    GIT_EDITOR = "nvim";
  };
}
