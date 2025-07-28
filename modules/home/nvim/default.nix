# modules/home/nvim/defaults.nix
# ==============================================================================
# Neovim Configuration - LazyVim Edition with GNOME/Hyprland Clipboard Support
# ==============================================================================
{ config, pkgs, ... }:
{
 # =============================================================================
 # Core Neovim Settings
 # =============================================================================
 programs.neovim = {
   enable = true;
   viAlias = true;
   vimAlias = true;
   defaultEditor = true;

   # =============================================================================
   # Package Dependencies
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
     
     # ---------------------------------------------------------------------------
     # Clipboard Tools (both for compatibility)
     # ---------------------------------------------------------------------------
     xclip        # For GNOME
     wl-clipboard # For Hyprland/Sway
   ];

   # =============================================================================
   # Vim Configuration with Desktop Environment Detection
   # =============================================================================
   extraConfig = ''
     " Desktop environment-aware clipboard configuration
     if $XDG_CURRENT_DESKTOP == 'GNOME'
       " =======================================================================
       " GNOME Configuration
       " =======================================================================
       " Use xclip for reliable clipboard in GNOME
       if executable('xclip')
         let g:clipboard = {
               \   'name': 'xclip-gnome',
               \   'copy': {
               \      '+': 'xclip -selection clipboard',
               \      '*': 'xclip -selection primary',
               \    },
               \   'paste': {
               \      '+': 'xclip -selection clipboard -o',
               \      '*': 'xclip -selection primary -o',
               \   },
               \   'cache_enabled': 1,
               \ }
         " Enable system clipboard integration with xclip
         set clipboard+=unnamedplus
       else
         " Fallback: disable automatic clipboard to prevent freezing
         set clipboard=
         echom "Warning: xclip not found, clipboard disabled for GNOME"
       endif
       
       " Manual clipboard mappings for GNOME
       nnoremap <Leader>y "+y
       vnoremap <Leader>y "+y
       nnoremap <Leader>p "+p
       vnoremap <Leader>p "+p
       nnoremap <Leader>Y "+Y
       
     else
       " =======================================================================
       " Hyprland/Sway Configuration (Non-GNOME)
       " =======================================================================
       " Use wl-clipboard for proper Wayland integration
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
       else
         " Fallback to xclip if wl-clipboard not available
         if executable('xclip')
           let g:clipboard = {
                 \   'name': 'xclip-fallback',
                 \   'copy': {
                 \      '+': 'xclip -selection clipboard',
                 \      '*': 'xclip -selection primary',
                 \    },
                 \   'paste': {
                 \      '+': 'xclip -selection clipboard -o',
                 \      '*': 'xclip -selection primary -o',
                 \   },
                 \   'cache_enabled': 1,
                 \ }
         else
           set clipboard=
           echom "Warning: No clipboard tool found"
         endif
       endif
     endif

     " LazyVim bootstrap
     lua << EOF
     -- Desktop environment detection in Lua
     local desktop_env = os.getenv("XDG_CURRENT_DESKTOP") or ""
     
     -- Additional GNOME-specific clipboard safety
     if desktop_env == "GNOME" then
       -- Disable unnamedplus if wl-copy is somehow still being used
       local handle = io.popen("which wl-copy 2>/dev/null")
       local wl_copy_path = handle:read("*a")
       handle:close()
       
       if wl_copy_path ~= "" then
         -- Force disable clipboard if wl-copy is present in GNOME
         vim.opt.clipboard = ""
         print("GNOME detected: Disabled automatic clipboard to prevent wl-copy conflicts")
       end
     end
     
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

     -- Plugin Configuration
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
     
     -- Mason Setup
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

     -- LazyVim Settings
     require("lazyvim.config").init({
       colorscheme = "catppuccin-mocha",
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

