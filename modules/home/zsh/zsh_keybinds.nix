{
  programs.zsh = {
    defaultKeymap = "viins";  # Set vi mode as default
    initExtra = ''
      # Enable vi mode
      bindkey -v

      WORDCHARS='~!#$%^&*(){}[]<>?.+;-'

      ""{back,for}ward-word() WORDCHARS=$MOTION_WORDCHARS zle .$WIDGET
      zle -N backward-word
      zle -N forward-word

      # Vi mode status
      function zle-keymap-select {
        if [[ ''${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
          echo -ne '\e[1 q'
        elif [[ ''${KEYMAP} == main ]] || [[ ''${KEYMAP} == viins ]] || [[ ''${KEYMAP} = ''' ]] || [[ $1 = 'beam' ]]; then
          echo -ne '\e[5 q'
        fi
      }
      zle -N zle-keymap-select

      # PageUp/PageDown navigation
      bindkey -M vicmd "''${terminfo[kpp]}" up-line-or-history
      bindkey -M viins "''${terminfo[kpp]}" up-line-or-history
      bindkey -M vicmd "''${terminfo[knp]}" down-line-or-history
      bindkey -M viins "''${terminfo[knp]}" down-line-or-history

      # Fuzzy history search
      autoload -U up-line-or-beginning-search down-line-or-beginning-search
      zle -N up-line-or-beginning-search
      zle -N down-line-or-beginning-search

      bindkey -M vicmd "k" up-line-or-beginning-search
      bindkey -M vicmd "j" down-line-or-beginning-search
      bindkey -M viins "^[[A" up-line-or-beginning-search
      bindkey -M viins "^[[B" down-line-or-beginning-search

      # Word navigation
      bindkey -M vicmd '^[[1;5C' forward-word
      bindkey -M viins '^[[1;5C' forward-word
      bindkey -M vicmd '^[[1;5D' backward-word
      bindkey -M viins '^[[1;5D' backward-word
      bindkey -M vicmd '^[[3;5~' kill-word
      bindkey -M viins '^[[3;5~' kill-word

      # Additional vi bindings
      bindkey -M vicmd 'Y' vi-yank-eol
      bindkey -M vicmd 'v' edit-command-line
      bindkey -M viins '^?' backward-delete-char
      bindkey -M viins '^H' backward-delete-char
      bindkey -M viins '^W' backward-kill-word
      bindkey -M vicmd '^W' backward-kill-word

      # Custom word deletion
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
