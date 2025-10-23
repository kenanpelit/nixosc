# modules/home/nvim/defaults.nix
# ==============================================================================
# Neovim Configuration - LazyVim Edition with Tokyo Night Theme
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
   # Vim Configuration with Tokyo Night Theme
   # =============================================================================
   extraConfig = ''
     " Desktop environment-aware clipboard configuration
     if $XDG_CURRENT_DESKTOP == 'GNOME'
       " =======================================================================
       " GNOME Configuration
       " =======================================================================
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
         set clipboard+=unnamedplus
       else
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

     " LazyVim bootstrap with Tokyo Night theme
     lua << EOF
     -- Desktop environment detection in Lua
     local desktop_env = os.getenv("XDG_CURRENT_DESKTOP") or ""
     
     -- Additional GNOME-specific clipboard safety
     if desktop_env == "GNOME" then
       local handle = io.popen("which wl-copy 2>/dev/null")
       local wl_copy_path = handle:read("*a")
       handle:close()
       
       if wl_copy_path ~= "" then
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

     -- Plugin Configuration with Tokyo Night
     require("lazy").setup({
       spec = {
         { "LazyVim/LazyVim", import = "lazyvim.plugins" },
         { import = "lazyvim.plugins.extras.lang.typescript" },
         { import = "lazyvim.plugins.extras.lang.json" },
         { import = "lazyvim.plugins.extras.util.mini-hipatterns" },
         { import = "lazyvim.plugins.extras.lsp.none-ls" },
         { "mason-org/mason.nvim" },
         { "mason-org/mason-lspconfig.nvim" },
         { "neovim/nvim-lspconfig" },
         
         -- Tokyo Night theme plugin
         {
           "folke/tokyonight.nvim",
           name = "tokyonight",
           priority = 1000,
           config = function()
             require("tokyonight").setup({
               -- Style options: storm, moon, night, day
               style = "storm", -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
               light_style = "day", -- The theme is used when the background is set to light
               transparent = false, -- Enable this to disable setting the background color
               terminal_colors = true, -- Configure the colors used when opening a `:terminal` in Neovim
               styles = {
                 -- Style to be applied to different syntax groups
                 -- Value is any valid attr-list value for `:help nvim_set_hl`
                 comments = { italic = true },
                 keywords = { italic = true },
                 functions = {},
                 variables = {},
                 -- Background styles. Can be "dark", "transparent" or "normal"
                 sidebars = "dark", -- style for sidebars, see below
                 floats = "dark", -- style for floating windows
               },
               sidebars = { "qf", "help", "neo-tree", "Trouble" }, -- Set a darker background on sidebar-like windows
               day_brightness = 0.3, -- Adjusts the brightness of the colors of the **Day** style
               hide_inactive_statusline = false, -- Enabling this option, will hide inactive statuslines and replace them with a thin border instead
               dim_inactive = false, -- dims inactive windows
               lualine_bold = false, -- When `true`, section headers in the lualine theme will be bold
               
               --- You can override specific color groups to use other groups or a hex color
               --- function will be called with a ColorScheme table
               ---@param colors ColorScheme
               on_colors = function(colors)
                 -- Customize specific colors if needed
                 -- colors.hint = colors.orange
                 -- colors.error = "#ff0000"
               end,
               
               --- You can override specific highlights to use other groups or a hex color
               --- function will be called with a Highlights and ColorScheme table
               ---@param highlights Highlights
               ---@param colors ColorScheme
               on_highlights = function(highlights, colors)
                 -- Customize specific highlights
                 -- highlights.Comment = { fg = colors.comment, style = { italic = true } }
                 -- highlights.Keyword = { fg = colors.magenta, style = { italic = true } }
               end,
               
               -- Plugin integrations
               plugins = {
                 -- enable all plugins when not using lazy.nvim
                 -- set to false to manually enable/disable plugins
                 all = package.loaded.lazy == nil,
                 -- uses your plugin manager to automatically enable needed plugins
                 -- currently only lazy.nvim is supported
                 auto = true,
                 -- add any plugins here that you want to enable
                 -- for all plugins, see:
                 -- https://github.com/folke/tokyonight.nvim#-plugin-support
                 alpha = true,
                 cmp = true,
                 dashboard = true,
                 flash = true,
                 gitsigns = true,
                 hop = true,
                 leap = true,
                 lsp_trouble = true,
                 mason = true,
                 markdown = true,
                 mini = true,
                 neo_tree = true,
                 neorg = true,
                 noice = true,
                 notify = true,
                 nvimtree = true,
                 semantic_tokens = true,
                 telescope = true,
                 treesitter = true,
                 treesitter_context = true,
                 ts_rainbow = true,
                 ts_rainbow2 = true,
                 which_key = true,
               },
             })
           end,
         },
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
         "ts_ls",  -- TypeScript
         "lua_ls",    -- Lua
       },
       automatic_installation = true,
     })

     -- LazyVim Settings
     require("lazyvim.config").init({
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
     
     -- Set Tokyo Night theme
     vim.defer_fn(function()
       vim.cmd.colorscheme("tokyonight-storm")
       -- Alternative variants:
       -- vim.cmd.colorscheme("tokyonight-night")  -- Darker variant
       -- vim.cmd.colorscheme("tokyonight-moon")   -- Medium variant
       -- vim.cmd.colorscheme("tokyonight-day")    -- Light variant
       vim.o.background = "dark"
     end, 100)
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

