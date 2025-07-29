# modules/home/zsh/zsh_keybinds.nix
{ lib, pkgs, ... }:
{
  programs.zsh = {
    defaultKeymap = "viins";
    
    initContent = ''
      # ---------------------------------------------------------------------------
      # Enhanced Vi Mode Setup
      # ---------------------------------------------------------------------------
      bindkey -v
      export KEYTIMEOUT=1
      
      # Smart word characters for better navigation
      WORDCHARS='~!#$%^&*(){}[]<>?.+;-'
      MOTION_WORDCHARS='~!#$%^&*(){}[]<>?.+;'
      
      # Enhanced word movement
      function smart-backward-word() {
        local WORDCHARS="''${MOTION_WORDCHARS}"
        zle backward-word
      }
      function smart-forward-word() {
        local WORDCHARS="''${MOTION_WORDCHARS}"
        zle forward-word
      }
      zle -N smart-backward-word
      zle -N smart-forward-word

      # ---------------------------------------------------------------------------
      # Enhanced Vi Mode Visual Feedback
      # ---------------------------------------------------------------------------
      function zle-keymap-select {
        case $KEYMAP in
          vicmd|NORMAL)
            echo -ne '\e[1 q'  # Block cursor
            ;;
          viins|INSERT|main)
            echo -ne '\e[5 q'  # Beam cursor
            ;;
        esac
      }
      
      function zle-line-init {
        echo -ne '\e[5 q'  # Beam cursor on new line
      }
      
      zle -N zle-keymap-select
      zle -N zle-line-init

      # ---------------------------------------------------------------------------
      # Smart History Navigation
      # ---------------------------------------------------------------------------
      autoload -U up-line-or-beginning-search down-line-or-beginning-search
      zle -N up-line-or-beginning-search
      zle -N down-line-or-beginning-search
      
      # Vi mode history
      bindkey -M vicmd "k" up-line-or-beginning-search
      bindkey -M vicmd "j" down-line-or-beginning-search
      bindkey -M vicmd '?' history-incremental-search-backward
      bindkey -M vicmd '/' history-incremental-search-forward
      bindkey -M vicmd 'n' history-search-forward
      bindkey -M vicmd 'N' history-search-backward
      
      # Insert mode history (arrow keys)
      bindkey -M viins "^[[A" up-line-or-beginning-search
      bindkey -M viins "^[[B" down-line-or-beginning-search
      bindkey -M viins "^P" up-line-or-beginning-search
      bindkey -M viins "^N" down-line-or-beginning-search

      # ---------------------------------------------------------------------------
      # Enhanced Navigation Bindings
      # ---------------------------------------------------------------------------
      # Line movement
      bindkey -M vicmd 'H' beginning-of-line
      bindkey -M vicmd 'L' end-of-line
      bindkey -M viins '^A' beginning-of-line
      bindkey -M viins '^E' end-of-line
      
      # Word movement (Ctrl+arrows)
      bindkey -M vicmd '^[[1;5C' smart-forward-word
      bindkey -M viins '^[[1;5C' smart-forward-word
      bindkey -M vicmd '^[[1;5D' smart-backward-word
      bindkey -M viins '^[[1;5D' smart-backward-word
      
      # Alt+arrows for word movement
      bindkey -M viins '^[f' smart-forward-word
      bindkey -M viins '^[b' smart-backward-word

      # ---------------------------------------------------------------------------
      # Enhanced Editing Bindings
      # ---------------------------------------------------------------------------
      # Vi mode enhancements
      bindkey -M vicmd 'Y' vi-yank-eol
      bindkey -M vicmd 'v' edit-command-line
      bindkey -M vicmd 'gg' beginning-of-buffer-or-history
      bindkey -M vicmd 'G' end-of-buffer-or-history
      
      # Insert mode editing
      bindkey -M viins '^?' backward-delete-char
      bindkey -M viins '^H' backward-delete-char
      bindkey -M viins '^U' backward-kill-line
      bindkey -M viins '^K' kill-line
      bindkey -M viins '^Y' yank
      
      # Smart word deletion
      function smart-backward-kill-word() {
        local WORDCHARS="''${WORDCHARS//:}"
        WORDCHARS="''${WORDCHARS//\/}"
        WORDCHARS="''${WORDCHARS//.}"
        WORDCHARS="''${WORDCHARS//-}"
        zle backward-kill-word
      }
      zle -N smart-backward-kill-word
      bindkey -M viins '^W' smart-backward-kill-word
      bindkey -M vicmd '^W' smart-backward-kill-word
      
      # Autosuggestion bindings
      bindkey -M viins '^F' autosuggest-accept
      bindkey -M viins '^L' autosuggest-accept
      bindkey -M viins '^[[Z' autosuggest-execute  # Shift+Tab
      
      # ---------------------------------------------------------------------------
      # FZF Integration Bindings
      # ---------------------------------------------------------------------------
      if command -v fzf > /dev/null; then
        # Enhanced FZF bindings
        bindkey -M viins '^T' fzf-file-widget       # Ctrl+T: Files
        bindkey -M viins '^R' fzf-history-widget    # Ctrl+R: History
        bindkey -M viins '^[c' fzf-cd-widget        # Alt+C: Directories
        
        # Vi mode FZF bindings
        bindkey -M vicmd '^T' fzf-file-widget
        bindkey -M vicmd '^R' fzf-history-widget
        bindkey -M vicmd '^[c' fzf-cd-widget
      fi

      # ---------------------------------------------------------------------------
      # Terminal Integration
      # ---------------------------------------------------------------------------
      # Clear screen
      bindkey -M viins '^L' clear-screen
      bindkey -M vicmd '^L' clear-screen
      
      # Suspend/Resume
      bindkey -M viins '^Z' push-input
      bindkey -M vicmd '^Z' push-input
    '';
  };
}

