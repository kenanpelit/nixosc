# modules/home/fzf/default.nix
# ------------------------------------------------------------------------------
# Home Manager module for fzf.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ------------------------------------------------------------------------------

{ config, pkgs, lib, ... }:

let
  cfg = config.my.user.fzf;

  # Catppuccin source from your central module
  inherit (config.catppuccin) sources;

  # Load color palette from Catppuccin JSON
  colors =
    (lib.importJSON "${sources.palette}/palette.json")
    .${config.catppuccin.flavor}
    .colors;

  # Map Catppuccin colors to FZF --color options
  catppuccinColors = [
    "--color=bg+:${colors.surface0.hex},bg:${colors.base.hex},spinner:${colors.rosewater.hex},hl:${colors.red.hex}"
    "--color=fg:${colors.text.hex},header:${colors.red.hex},info:${colors.mauve.hex},pointer:${colors.rosewater.hex}"
    "--color=marker:${colors.green.hex},fg+:${colors.text.hex},prompt:${colors.mauve.hex},hl+:${colors.red.hex}"
    "--color=border:${colors.overlay0.hex},label:${colors.text.hex},query:${colors.text.hex}"
    "--color=selected-bg:${colors.surface0.hex},selected-fg:${colors.text.hex}"
  ];

  # UI-related options (layout, borders, etc.)
  catppuccinUI = [
    "--border=rounded"
    "--border-label="
    "--preview-window=right:60%:wrap,border-rounded"
    "--prompt=❯ "
    "--marker=✓"
    "--pointer=▶"
    "--separator=─"
    "--scrollbar=│"
    "--info=inline"
  ];

  # General behaviour options (height, scroll, keybinds)
  defaultBehavior = [
    "--height=80%"
    "--layout=reverse"
    "--multi"
    "--cycle"
    "--scroll-off=5"
    "--bind=ctrl-/:toggle-preview"
    "--bind=ctrl-u:preview-half-page-up"
    "--bind=ctrl-d:preview-half-page-down"
    "--bind=ctrl-a:select-all"
    "--bind=ctrl-x:deselect-all"
    "--bind=ctrl-space:toggle+down"
    "--bind=alt-w:toggle-preview-wrap"
    "--no-scrollbar"
  ];

in
{
  # ============================================================================
  # Options
  # ============================================================================

  options.my.user.fzf = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable FZF fuzzy finder with advanced previews.";
    };

    enableZshIntegration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Zsh shell integration (FZF_* env vars, keybinds).";
    };

    previewImageHandler = lib.mkOption {
      type = lib.types.enum [ "chafa" "sixel" ];
      default = "chafa";
      description = "Image preview handler (chafa for most terminals, sixel for advanced terminals).";
    };
  };

  # ============================================================================
  # Config
  # ============================================================================

  config = lib.mkIf cfg.enable {

    # -------------------------------------------------------------------------
    # FZF program configuration (Home Manager side)
    # -------------------------------------------------------------------------
    programs.fzf = {
      enable = true;
      enableZshIntegration = cfg.enableZshIntegration;

      # Simple default command; real logic is further controlled via Zsh env
      defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";

      # CTRL-T file widget options
      fileWidgetOptions = [
        "--preview 'bat -n --color=always --line-range :500 {} 2>/dev/null || cat {}'"
        "--height=50%"
        "--layout=reverse"
        "--info=inline"
      ];

      # ALT-C directory widget
      changeDirWidgetCommand = "fd --type=d --hidden --strip-cwd-prefix --exclude .git";
      changeDirWidgetOptions = [
        "--preview 'eza --tree --color=always --level=2 {} 2>/dev/null || ls -la {}'"
        "--height=50%"
        "--layout=reverse"
        "--info=inline"
      ];

      # CTRL-R history widget
      historyWidgetOptions = [
        "--height=50%"
        "--layout=reverse"
        "--info=inline"
        "--tiebreak=index"
      ];

      # THE ONLY SOURCE OF FZF_DEFAULT_OPTS:
      # Home Manager will build a proper, single FZF_DEFAULT_OPTS from this.
      defaultOptions = catppuccinColors ++ catppuccinUI ++ defaultBehavior;
    };

    # -------------------------------------------------------------------------
    # Zsh-side integration (NO FZF_DEFAULT_OPTS HERE)
    # -------------------------------------------------------------------------
    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration ''
      # =========================================================================
      # FZF configuration (Zsh side)
      # DO NOT touch FZF_DEFAULT_OPTS here.
      # Catppuccin theme is already injected via programs.fzf.defaultOptions.
      # =========================================================================

      # Completion trigger and options
      export FZF_COMPLETION_TRIGGER='**'
      export FZF_COMPLETION_OPTS='--border=rounded --info=inline'

      # Default file search command
      if command -v rg &>/dev/null; then
        export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!{.git,.cache,node_modules}/*"'
      elif command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --strip-cwd-prefix -E .git -E .cache -E node_modules'
      fi

      # CTRL-T and ALT-C commands (fd-based)
      if command -v fd &>/dev/null; then
        export FZF_CTRL_T_COMMAND='fd --type f --type d --hidden --follow --strip-cwd-prefix -E .git -E .cache -E node_modules'
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --strip-cwd-prefix -E .git -E .cache -E node_modules'
      fi

      # CTRL-T: file/dir picker + preview + nvim integration
      export FZF_CTRL_T_OPTS="\
        --preview '[[ -d {} ]] && eza -T -L2 --icons --color=always {} || bat -n --color=always -r :500 {}' \
        --preview-window 'right:60%:wrap' \
        --bind 'ctrl-/:change-preview-window(down|hidden|)' \
        --bind 'ctrl-e:execute(nvim {} < /dev/tty > /dev/tty 2>&1)'"

      # ALT-C: directory picker + tree preview
      export FZF_ALT_C_OPTS="\
        --preview 'eza -T -L3 --icons --color=always --group-directories-first {}' \
        --preview-window 'right:60%' \
        --bind 'ctrl-/:change-preview-window(down|hidden|)'"

      # CTRL-R: history search with small preview
      export FZF_CTRL_R_OPTS="\
        --preview 'echo {}' \
        --preview-window 'down:3:hidden:wrap' \
        --bind '?:toggle-preview' \
        --bind 'ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort' \
        --exact"
    '';

    # -------------------------------------------------------------------------
    # Shared environment variables
    # -------------------------------------------------------------------------
    home.sessionVariables = {
      FZF_PREVIEW_IMAGE_HANDLER = cfg.previewImageHandler;
    };

  };
}
