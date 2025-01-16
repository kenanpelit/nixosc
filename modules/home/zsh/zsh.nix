# ==============================================================================
# ZSH Ana Yapılandırma Dosyası
# Özelleştirilmiş konfigürasyon, performans optimizasyonları ve gelişmiş özellikler
# ==============================================================================
{ hostname, config, pkgs, host, ... }:
{
  imports = [
    ./zsh_keybinds.nix
  ];

  # SSH konfigürasyonu için gerekli dizin yapısı
  home.file.".ssh/.keep".text = "";

  # Powerlevel10k tema yapılandırması artık .config/zsh altında
  home.file.".config/zsh/p10k.zsh" = {
    enable = true;
    source = ../p10k/.p10k.zsh;
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    initExtraFirst = ''
      # XDG Base Directory Specification
      export XDG_CONFIG_HOME="$HOME/.config"
      export XDG_CACHE_HOME="$HOME/.cache"
      export XDG_DATA_HOME="$HOME/.local/share"
      export XDG_STATE_HOME="$HOME/.local/state"

      # Zsh için XDG dizinleri
      export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
      mkdir -p "$XDG_CACHE_HOME/zsh"
      mkdir -p "$XDG_STATE_HOME/zsh"
      mkdir -p "$ZDOTDIR"

      # Completion cache ve geçmiş dosyası konumları
      export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump-$HOST-${ZSH_VERSION}"
      export ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"

      # URL ve quote magic yapılandırması
      autoload -U url-quote-magic url-quote-magic bracketed-paste-magic
      zle -N self-insert url-quote-magic
      zle -N bracketed-paste bracketed-paste-magic
      zstyle ':url-quote-magic:*' url-metas ""
      
      # Powerlevel10k instant prompt yapılandırması
      typeset -g POWERLEVEL9K_INSTANT_PROMPT="quiet"
      [[ -r "$XDG_CACHE_HOME/p10k-instant-prompt-''${(%):-%n}.zsh" ]] && source "$XDG_CACHE_HOME/p10k-instant-prompt-''${(%):-%n}.zsh"

      # Varsayılan uygulama tercihleri
      export EDITOR='nvim'
      export VISUAL='nvim'
      export PAGER='most'
      export TERM=xterm-256color

      # Gelişmiş geçmiş ayarları
      setopt HIST_REDUCE_BLANKS
      setopt HIST_VERIFY
      setopt HIST_FCNTL_LOCK
      setopt HIST_BEEP

      # FZF yapılandırması
      export FZF_DEFAULT_OPTS="--height 80% --layout=reverse --border --cycle --marker='✓' --pointer='▶'"
      export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}'"
      export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
      export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"

      # fd entegrasyonu
      if command -v fd > /dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude .cache'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --exclude node_modules --exclude .cache'
      fi

      # Zoxide entegrasyonu
      eval "$(zoxide init zsh)"
    '';

    # P10k tema yüklemesi - artık .config/zsh altından
    initExtra = ''
      [[ ! -f "$ZDOTDIR/p10k.zsh" ]] || source "$ZDOTDIR/p10k.zsh"
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    '';

    # Komut geçmişi yapılandırması
    history = {
      size = 50000;
      save = 50000;
      path = "$XDG_STATE_HOME/zsh/history";
      ignoreDups = true;
      share = true;
      extended = true;
      expireDuplicatesFirst = true;
      ignoreSpace = true;
      ignoreAllDups = true;
    };

    # ZSH eklentileri
    plugins = [
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "fast-syntax-highlighting";
        src = pkgs.zsh-fast-syntax-highlighting;
      }
      {
        name = "zsh-completions";
        src = pkgs.zsh-completions;
      }
      {
        name = "zsh-autosuggestions";
        src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
        file = "zsh-autosuggestions.zsh";
      }
    ];

    # Tamamlama sistemi yapılandırması
    completionInit = ''
      # Temel ayarlar
      autoload -Uz colors && colors
      _comp_options+=(globdots)

      # Komut düzenleme widget'ı
      autoload -Uz edit-command-line
      zle -N edit-command-line

      # Tamamlama sistemi stil ve davranış ayarları
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

      # fzf-tab yapılandırması
      zstyle ':fzf-tab:complete:*:*' fzf-preview 'eza --icons -a --group-directories-first -1 --color=always $realpath'
      zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
      zstyle ':fzf-tab:*' fzf-command fzf
      zstyle ':fzf-tab:*' fzf-min-height 100
      zstyle ':fzf-tab:*' switch-group ',' '.'
    '';

    # Oh My Zsh yapılandırması
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "command-not-found"
        "history"
        "copypath"
        "dirhistory"
        "colored-man-pages"
        "ssh-agent"
        "extract"
        "aliases"
      ];
    };
  };
}
