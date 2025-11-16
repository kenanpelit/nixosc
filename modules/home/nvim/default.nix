# modules/home/nvim/defaults.nix
# ==============================================================================
# Neovim Configuration - LazyVim Edition with Tokyo Night Theme + Claude Code
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
      nil           # Nix LSP
      pyright       # Python LSP
      rust-analyzer # Rust LSP
      marksman      # Markdown LSP

      # ---------------------------------------------------------------------------
      # Formatters
      # ---------------------------------------------------------------------------
      stylua        # Lua formatter
      nixpkgs-fmt   # Nix formatter
      prettierd     # JS/TS/JSON/HTML/CSS formatter (daemon)
      black         # Python formatter
      rustfmt       # Rust formatter
      shfmt         # Shell script formatter

      # ---------------------------------------------------------------------------
      # Linters
      # ---------------------------------------------------------------------------
      nodePackages.eslint_d # JS/TS linter (daemon)
      shellcheck            # Shell script linter
      statix                # Nix linter

      # ---------------------------------------------------------------------------
      # Core Tools
      # ---------------------------------------------------------------------------
      ripgrep
      fd
      git
      nodejs
      tree-sitter
      lazygit       # TUI for git
      delta         # Better git diff viewer
      bat           # Better cat with syntax highlighting

      # ---------------------------------------------------------------------------
      # Clipboard Tools (both for compatibility)
      # ---------------------------------------------------------------------------
      xclip        # For GNOME
      wl-clipboard # For Hyprland/Sway
    ];

    # =============================================================================
    # Vim Configuration
    # =============================================================================
    extraConfig = ''
      " Desktop environment-aware clipboard configuration
      if $XDG_CURRENT_DESKTOP == 'GNOME'
        " =======================================================================
        " GNOME Configuration - Use xclip
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
        endif
      else
        " =======================================================================
        " Hyprland/Sway Configuration - Use wl-clipboard
        " =======================================================================
        set clipboard+=unnamedplus
      endif

      " LazyVim bootstrap with enhanced configuration
      lua << EOF
      -- Desktop environment detection
      local desktop_env = os.getenv("XDG_CURRENT_DESKTOP") or ""

      -- GNOME-specific clipboard safety
      if desktop_env == "GNOME" then
        local handle = io.popen("which wl-copy 2>/dev/null")
        local wl_copy_path = handle:read("*a")
        handle:close()

        if wl_copy_path ~= "" then
          vim.opt.clipboard = ""
          print("GNOME: Disabled automatic clipboard to prevent conflicts")
        end
      end

      -- Bootstrap lazy.nvim
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
          -- LazyVim Core
          { "LazyVim/LazyVim", import = "lazyvim.plugins" },

          -- =======================================================================
          -- Language Support
          -- =======================================================================
          { import = "lazyvim.plugins.extras.lang.typescript" },
          { import = "lazyvim.plugins.extras.lang.json" },
          { import = "lazyvim.plugins.extras.lang.python" },
          { import = "lazyvim.plugins.extras.lang.rust" },
          { import = "lazyvim.plugins.extras.lang.markdown" },

          -- =======================================================================
          -- Formatting & Linting
          -- =======================================================================
          { import = "lazyvim.plugins.extras.formatting.prettier" },
          { import = "lazyvim.plugins.extras.linting.eslint" },

          -- =======================================================================
          -- Editor Enhancements
          -- =======================================================================
          { import = "lazyvim.plugins.extras.editor.telescope" },
          { import = "lazyvim.plugins.extras.ui.treesitter-context" },
          { import = "lazyvim.plugins.extras.util.mini-hipatterns" },

          -- =======================================================================
          -- Git Integration
          -- =======================================================================
          {
            "kdheepak/lazygit.nvim",
            dependencies = { "nvim-lua/plenary.nvim" },
            keys = {
              { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
            },
          },

          -- =======================================================================
          -- Claude Code AI Integration
          -- =======================================================================
          {
            "coder/claudecode.nvim",
            dependencies = { "folke/snacks.nvim" },
            config = true,
            keys = {
              -- AI Group
              { "<leader>a", nil, desc = "AI/Claude" },

              -- Core Commands
              { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
              { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },

              -- Conversation Management
              { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Chat" },
              { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Chat" },

              -- Context Management
              { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Model" },
              { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add Current Buffer" },
              { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send Selection" },

              -- Diff Operations
              { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Diff" },
              { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny Diff" },
            },
          },

          -- =======================================================================
          -- Tokyo Night Theme
          -- =======================================================================
          {
            "folke/tokyonight.nvim",
            name = "tokyonight",
            priority = 1000,
            config = function()
              require("tokyonight").setup({
                style = "storm",              -- storm, moon, night, day
                light_style = "day",
                transparent = false,
                terminal_colors = true,
                styles = {
                  comments = { italic = true },
                  keywords = { italic = true },
                  functions = {},
                  variables = {},
                  sidebars = "dark",
                  floats = "dark",
                },
                sidebars = { "qf", "help", "neo-tree", "Trouble" },
                day_brightness = 0.3,
                hide_inactive_statusline = false,
                dim_inactive = false,
                lualine_bold = false,
              })
              vim.cmd([[colorscheme tokyonight]])
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

      -- Additional Settings
      vim.opt.relativenumber = true
      vim.opt.number = true
      vim.opt.expandtab = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 2
      vim.opt.smartindent = true
      vim.opt.wrap = false
      vim.opt.swapfile = false
      vim.opt.backup = false
      vim.opt.undofile = true
      vim.opt.hlsearch = false
      vim.opt.incsearch = true
      vim.opt.termguicolors = true
      vim.opt.scrolloff = 8
      vim.opt.signcolumn = "yes"
      vim.opt.updatetime = 50
      vim.opt.colorcolumn = "80"
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
