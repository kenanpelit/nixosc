# modules/home/nvim/defaults.nix
# ==============================================================================
# Neovim Configuration - LazyVim Edition with Tokyo Night Theme + Gemini
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
      curl          # HTTP client for Gemini plugin

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
          -- Gemini AI Integration
          -- =======================================================================
          {
            "kiddos/gemini.nvim",
            dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
            opts = {
              model_config = {
                model_id = "gemini-3-pro-preview",
                temperature = 0.10,
                top_k = 128,
                response_mime_type = "text/plain",
              },
              chat_config = { enabled = true },
              hints = {
                enabled = true,
                hints_delay = 2000,
                insert_result_key = "<S-Tab>",
                get_prompt = function(node, bufnr)
                  local code_block = vim.treesitter.get_node_text(node, bufnr)
                  local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
                  local prompt = [[
  Instruction: Use 1 or 2 sentences to describe what the following {filetype} function does:

  ```{filetype}
  {code_block}
  ```]] .. "`"
                  prompt = prompt:gsub("{filetype}", filetype)
                  prompt = prompt:gsub("{code_block}", code_block)
                  return prompt
                end,
              },
              completion = {
                enabled = true,
                blacklist_filetypes = { "help", "qf", "json", "yaml", "toml", "xml" },
                blacklist_filenames = { ".env" },
                completion_delay = 800,
                insert_result_key = "<S-Tab>",
                move_cursor_end = true,
                can_complete = function()
                  return vim.fn.pumvisible() ~= 1
                end,
                get_system_text = function()
                  return "You are a coding AI assistant that autocomplete user's code."
                    .. "\n* Your task is to provide code suggestion at the cursor location marked by <cursor></cursor>."
                    .. "\n* Your response does not need to contain explaination."
                end,
                get_prompt = function(bufnr, pos)
                  local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
                  local prompt = "Below is the content of a %s file `%s`:\n"
                      .. "```%s\n%s\n```\n\n"
                      .. "Suggest the most likely code at <cursor></cursor>.\n"
                      .. "Wrap your response in ``` ```\n"
                      .. "eg.\n```\n```\n\n"
                  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                  local line = pos[1]
                  local col = pos[2]
                  local target_line = lines[line]
                  if target_line then
                    lines[line] = target_line:sub(1, col) .. "<cursor></cursor>" .. target_line:sub(col + 1)
                  else
                    return nil
                  end
                  local code = vim.fn.join(lines, "\n")
                  local abs_path = vim.api.nvim_buf_get_name(bufnr)
                  local filename = vim.fn.fnamemodify(abs_path, ":.")
                  prompt = string.format(prompt, filetype, filename, filetype, code)
                  return prompt
                end,
              },
              instruction = {
                enabled = true,
                menu_key = "<Leader><Leader><Leader>g",
                prompts = {
                  {
                    name = "Unit Test",
                    command_name = "GeminiUnitTest",
                    menu = "Unit Test",
                    get_prompt = function(lines, bufnr)
                      local code = vim.fn.join(lines, "\n")
                      local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
                      local prompt = "Context:\n\n```%s\n%s\n```\n\n"
                          .. "Objective: Write unit test for the above snippet of code\n"
                      return string.format(prompt, filetype, code)
                    end,
                  },
                  {
                    name = "Code Review",
                    command_name = "GeminiCodeReview",
                    menu = "Code Review",
                    get_prompt = function(lines, bufnr)
                      local code = vim.fn.join(lines, "\n")
                      local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
                      local prompt = "Context:\n\n```%s\n%s\n```\n\n"
                          .. "Objective: Do a thorough code review for the following code.\n"
                          .. "Provide detail explaination and sincere comments.\n"
                      return string.format(prompt, filetype, code)
                    end,
                  },
                  {
                    name = "Code Explain",
                    command_name = "GeminiCodeExplain",
                    menu = "Code Explain",
                    get_prompt = function(lines, bufnr)
                      local code = vim.fn.join(lines, "\n")
                      local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
                      local prompt = "Context:\n\n```%s\n%s\n```\n\n"
                          .. "Objective: Explain the following code.\n"
                          .. "Provide detail explaination and sincere comments.\n"
                      return string.format(prompt, filetype, code)
                    end,
                  },
                },
              },
              task = {
                enabled = true,
                get_system_text = function()
                  return "You are an AI assistant that helps user write code."
                    .. "\n* You should output the new content for the Current Opened File"
                end,
                get_prompt = function(bufnr, user_prompt)
                  local buffers = vim.api.nvim_list_bufs()
                  local file_contents = {}

                  for _, b in ipairs(buffers) do
                    if vim.api.nvim_buf_is_loaded(b) then
                      local lines = vim.api.nvim_buf_get_lines(b, 0, -1, false)
                      local abs_path = vim.api.nvim_buf_get_name(b)
                      local filename = vim.fn.fnamemodify(abs_path, ":.")
                      local filetype = vim.api.nvim_get_option_value("filetype", { buf = b })
                      local file_content = table.concat(lines, "\n")
                      file_content = string.format("`%s`:\n\n```%s\n%s\n```\n\n", filename, filetype, file_content)
                      table.insert(file_contents, file_content)
                    end
                  end

                  local current_filepath = vim.api.nvim_buf_get_name(bufnr)
                  current_filepath = vim.fn.fnamemodify(current_filepath, ":.")

                  local context = table.concat(file_contents, "\n\n")
                  return string.format("%s\n\nCurrent Opened File: %s\n\nTask: %s",
                    context, current_filepath, user_prompt)
                end,
              },
            },
            config = function(_, opts)
              require("gemini").setup(opts)
            end,
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
