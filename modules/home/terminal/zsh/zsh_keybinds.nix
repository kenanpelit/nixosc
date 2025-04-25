# ==============================================================================
# ZSH Key Bindings Configuration
# ==============================================================================
{ lib, ... }:
{
  programs.zsh = {
    defaultKeymap = "viins";  # Vi mode as default
    
    # =============================================================================
    # Key Binding Configuration
    # =============================================================================
    initContent = ''
      # ---------------------------------------------------------------------------
      # Vi Mode Setup and Configuration
      # ---------------------------------------------------------------------------
      bindkey -v
      export KEYTIMEOUT=1
      WORDCHARS='~!#$%^&*(){}[]<>?.+;-'
      ""{back,for}ward-word() WORDCHARS=$MOTION_WORDCHARS zle .$WIDGET
      zle -N backward-word
      zle -N forward-word

      # ---------------------------------------------------------------------------
      # Vi Mode Status Indicator
      # ---------------------------------------------------------------------------
      function zle-keymap-select {
        if [[ ''${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
          echo -ne '\e[1 q'  # Block cursor for normal mode
        elif [[ ''${KEYMAP} == main ]] || [[ ''${KEYMAP} == viins ]] || [[ ''${KEYMAP} = ''' ]] || [[ $1 = 'beam' ]]; then
          echo -ne '\e[5 q'  # Beam cursor for insert mode
        fi
      }
      zle -N zle-keymap-select

      # ---------------------------------------------------------------------------
      # Navigation Bindings
      # ---------------------------------------------------------------------------
      # Page Navigation
      bindkey -M vicmd "''${terminfo[kpp]}" up-line-or-history
      bindkey -M viins "''${terminfo[kpp]}" up-line-or-history
      bindkey -M vicmd "''${terminfo[knp]}" down-line-or-history
      bindkey -M viins "''${terminfo[knp]}" down-line-or-history

      # History Search
      autoload -U up-line-or-beginning-search down-line-or-beginning-search
      zle -N up-line-or-beginning-search
      zle -N down-line-or-beginning-search
      bindkey -M vicmd "k" up-line-or-beginning-search
      bindkey -M vicmd "j" down-line-or-beginning-search
      bindkey -M viins "^[[A" up-line-or-beginning-search
      bindkey -M viins "^[[B" down-line-or-beginning-search
      bindkey -M vicmd '?' history-incremental-search-backward
      bindkey -M vicmd '/' history-incremental-search-forward

      # Line Navigation
      bindkey -M vicmd 'H' beginning-of-line
      bindkey -M vicmd 'L' end-of-line

      # Word Navigation
      bindkey -M vicmd '^[[1;5C' forward-word
      bindkey -M viins '^[[1;5C' forward-word
      bindkey -M vicmd '^[[1;5D' backward-word
      bindkey -M viins '^[[1;5D' backward-word
      bindkey -M vicmd '^[[3;5~' kill-word
      bindkey -M viins '^[[3;5~' kill-word

      # ---------------------------------------------------------------------------
      # Vi Mode Special Bindings
      # ---------------------------------------------------------------------------
      bindkey -M vicmd 'Y' vi-yank-eol
      bindkey -M vicmd 'v' edit-command-line
      bindkey -M viins '^?' backward-delete-char
      bindkey -M viins '^h' backward-delete-char
      bindkey -M viins '^w' backward-kill-word
      bindkey -M vicmd '^w' backward-kill-word
      bindkey -M viins '^u' backward-kill-line
      bindkey -M viins '^k' kill-line
      bindkey -M viins '^f' autosuggest-accept

      # ---------------------------------------------------------------------------
      # Custom Word Deletion
      # ---------------------------------------------------------------------------
      function my-backward-delete-word() {
        local WORDCHARS="''${WORDCHARS//:}"
        WORDCHARS="''${WORDCHARS//\/}"
        WORDCHARS="''${WORDCHARS//.}"
        WORDCHARS="''${WORDCHARS//-}"
        zle backward-delete-word
      }
      zle -N my-backward-delete-word
      bindkey '^W' my-backward-delete-word
    '';
  };
}

