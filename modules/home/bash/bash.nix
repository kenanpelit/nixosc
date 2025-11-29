# modules/home/bash/bash.nix
# ==============================================================================
# Bash Configuration - Fast, minimal, modular
# Author: Kenan Pelit
# Notes:
#   - Mirrors the intent of zsh.nix but uses built-in bash features.
#   - Prompt handled by starship (portable) instead of p10k.
# ==============================================================================
{ config, pkgs, lib, host, ... }:

let
  enableStarship = true;
in
{
  programs.bash = {
    enable = true;

    # Use Vi keybindings in Bash (matches zsh viins)
    # Users can switch at runtime with: set -o emacs / set -o vi
    # NOTE: Home Manager exposes this via bashrcExtra; we set it there.
    # No direct option exists like defaultKeymap for ZSH.
    enableCompletion = true;
    historyControl = [ "ignoredups" "ignorespace" ];
    historyIgnore = [ "ls" "ll" "la" "cd" "exit" "clear" ];
    shellOptions = [
      "autocd"            # 'cd' into directories by just typing the name
      "checkwinsize"      # Update LINES and COLUMNS after each command
      "cmdhist"           # Save multi-line commands as a single line
      "histappend"        # Append to the history file, don't overwrite it
      "histreedit"        # Edit a failed history substitution
      "histverify"        # Don't execute expanded history line immediately
      "nocaseglob"        # Case-insensitive globbing
      "globstar"          # ** recursive globs
      "no_empty_cmd_completion"
    ];

    bashrcExtra = ''
      # ===========================
      # Interactive shell settings
      # ===========================
      case $- in
        *i*) ;;
          *) return;;
      esac

      # Vi mode (match zsh viins)
      set -o vi

      # Better history defaults
      export HISTFILESIZE=200000
      export HISTSIZE=200000
      export HISTCONTROL=ignoredups:ignorespace
      export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

      # Path helpers (preserves existing PATH)
      _add_path() { case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH";; esac }
      _add_path "$HOME/.local/bin"
      _add_path "$HOME/bin"

      # FZF (enabled here; exact keybinds in bash_unified.nix)
      # Home Manager can also install fzf package.
      if [ -f "${pkgs.fzf}/share/fzf/key-bindings.bash" ]; then
        source "${pkgs.fzf}/share/fzf/key-bindings.bash"
      fi
      if [ -f "${pkgs.fzf}/share/fzf/completion.bash" ]; then
        source "${pkgs.fzf}/share/fzf/completion.bash"
      fi

      # Starship prompt (portable alternative to p10k)
      ${lib.optionalString enableStarship ''
      eval "$(${pkgs.starship}/bin/starship init bash)"
      ''}
    '';

    profileExtra = ''
      # Login shell environment (minimal; app-specific envs belong to app launchers)
      export EDITOR=vim
      export PAGER=less
      export LESSHISTFILE=-
      export LANG=${config.i18n.defaultLocale or "en_US.UTF-8"}
      export LC_ALL=${config.i18n.defaultLocale or "en_US.UTF-8"}

      # Colorize common tools
      export CLICOLOR=1
      export GREP_OPTIONS=
      export GREP_COLOR=
    '';
  };

  # Optional: starship prompt with a sensible, fast config
  programs.starship = lib.mkIf enableStarship {
    enable = true;
    settings = {
      add_newline = false;
      command_timeout = 1000;
      format = "$username$hostname$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = { success_symbol = "[❯](bold)"; error_symbol = "[❯](bold)"; };
      directory = { truncate_to_repo = true; truncation_length = 3; };
      git_status = { conflicted = "⚠"; deleted = "✖"; modified = "!"; staged = "+";
                     stashed = "$"; untracked = "?"; ahead = "⇡"; behind = "⇣"; diverged = "⇕"; };
      cmd_duration = { min_time = 1500; format = "took [$duration]"; };
    };
  };
}
