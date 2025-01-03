{ hostname, config, pkgs, host, ... }:
{
 programs.zsh = {
   enable = true;
   autosuggestion.enable = true;
   syntaxHighlighting.enable = true;
   enableCompletion = true;
   defaultKeymap = "viins";

   history = {
     size = 50000;
     save = 50000;
     path = "$XDG_CONFIG_HOME/zsh/history";
     ignoreDups = true;
     share = true;
     extended = true;
   };

   plugins = [
     {
       name = "fzf-tab";
       src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
     }
     {
       name = "fast-syntax-highlighting";
       src = pkgs.zsh-fast-syntax-highlighting;
     }
     {
       name = "zsh-completions";
       src = pkgs.zsh-completions;
     }
   ];

   completionInit = ''
     autoload -Uz colors && colors
     _comp_options+=(globdots)

     autoload -Uz edit-command-line
     zle -N edit-command-line
     bindkey "^e" edit-command-line

     zstyle ':completion:*' completer _extensions _complete _approximate
     zstyle ':completion:*' use-cache on
     zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcompcache"
     zstyle ':completion:*' complete true
     zstyle ':completion:*' complete-options true
     zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
     zstyle ':completion:*' keep-prefix true
     zstyle ':completion:*' menu select
     zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
     zstyle ':completion:*' special-dirs true
     zstyle ':completion:*' squeeze-slashes true
     zstyle ':completion:*' sort false
     zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
     
     # fzf-tab configuration
     zstyle ':fzf-tab:complete:*:*' fzf-preview 'eza --icons -a --group-directories-first -1 --color=always $realpath'
     zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
     zstyle ':fzf-tab:*' fzf-command fzf
     zstyle ':fzf-tab:*' fzf-min-height 100
     zstyle ':fzf-tab:*' switch-group ',' '.'
   '';

   initExtraFirst = ''
     export XDG_CONFIG_HOME="$HOME/.config"
     export XDG_CACHE_HOME="$HOME/.cache"
     export XDG_DATA_HOME="$HOME/.local/share"
     export EDITOR='nvim'
     export VISUAL='nvim'
     export PAGER='most'
     export TERM=xterm-256color
     
     # Vi mode
     bindkey -v
     export KEYTIMEOUT=1
     
     # Change cursor shape for different vi modes
     function zle-keymap-select {
       if [[ ''${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
         echo -ne '\e[1 q'
       elif [[ ''${KEYMAP} == main ]] || [[ ''${KEYMAP} == viins ]] || [[ ''${KEYMAP} = ''' ]] || [[ $1 = 'beam' ]]; then
         echo -ne '\e[5 q'
       fi
     }
     zle -N zle-keymap-select
     
     # FZF settings
     export FZF_DEFAULT_OPTS="--height 80% --layout=reverse --border --cycle --marker='✓' --pointer='▶'"
     export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}'"
     export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
     
     # History settings
     setopt sharehistory
     setopt hist_ignore_all_dups
     setopt hist_save_no_dups
     setopt hist_ignore_space
     setopt hist_verify
     setopt hist_reduce_blanks
     
     _fzf_compgen_path() { fd --hidden --exclude .git . "$1" }
     _fzf_compgen_dir() { fd --type=d --hidden --exclude .git . "$1" }
     
     # Vi mode bindings
     bindkey -M vicmd 'k' up-line-or-beginning-search
     bindkey -M vicmd 'j' down-line-or-beginning-search
     bindkey -M vicmd 'H' beginning-of-line
     bindkey -M vicmd 'L' end-of-line
     bindkey -M vicmd '?' history-incremental-search-backward
     bindkey -M vicmd '/' history-incremental-search-forward
     bindkey -M viins '^?' backward-delete-char
     bindkey -M viins '^h' backward-delete-char
     bindkey -M viins '^w' backward-kill-word
     bindkey -M vicmd '^w' backward-kill-word
     bindkey -M viins '^u' backward-kill-line
     bindkey -M viins '^k' kill-line
   '';
 };

 programs.zoxide = {
   enable = true;
   enableZshIntegration = true;
   options = ["--cmd cd"];
 };

 home.packages = with pkgs; [
   fd fzf bat eza tree most dig
 ];
}
