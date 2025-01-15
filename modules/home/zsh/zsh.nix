# ==============================================================================
# ZSH Ana Yapılandırma Dosyası
# Özelleştirilmiş konfigürasyon, performans optimizasyonları ve gelişmiş özellikler
# ==============================================================================
{ hostname, config, pkgs, host, ... }:
{
  # SSH konfigürasyonu için gerekli dizin yapısı
  home.file.".ssh/.keep".text = "";

  # Powerlevel10k tema yapılandırması
  # Modern ve özelleştirilebilir bir prompt teması
  home.file.".p10k.zsh" = {
    enable = true;
    source = ../p10k/.p10k.zsh;
  };

  programs.zsh = {
    enable = true;                     # ZSH'i etkinleştir
    autosuggestion.enable = true;      # Fish benzeri akıllı öneri sistemi
    syntaxHighlighting.enable = true;  # Canlı sözdizimi vurgulama
    enableCompletion = true;           # Gelişmiş tamamlama sistemi
    defaultKeymap = "viins";           # Vi input modunu varsayılan yap

    initExtraFirst = ''
      # URL ve quote magic yapılandırması
      # Özel karakterleri ve URL'leri akıllıca işler
      autoload -U url-quote-magic url-quote-magic bracketed-paste-magic
      zle -N self-insert url-quote-magic
      zle -N bracketed-paste bracketed-paste-magic
      zstyle ':url-quote-magic:*' url-metas ""
      
      # Powerlevel10k instant prompt yapılandırması
      # Shell başlatma hızını önemli ölçüde artırır
      typeset -g POWERLEVEL9K_INSTANT_PROMPT="quiet"
      [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]] && source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"

      # XDG Base Directory Specification
      # Yapılandırma dosyaları için standart konumlar
      export XDG_CONFIG_HOME="$HOME/.config"
      export XDG_CACHE_HOME="$HOME/.cache"
      export XDG_DATA_HOME="$HOME/.local/share"

      # Varsayılan uygulama tercihleri
      export EDITOR='nvim'
      export VISUAL='nvim'
      export PAGER='most'
      export TERM=xterm-256color

      # Gelişmiş geçmiş ayarları
      # Daha temiz ve düzenli bir komut geçmişi
      setopt HIST_REDUCE_BLANKS      # Gereksiz boşlukları kaldır
      setopt HIST_VERIFY            # Geçmiş genişletmelerini çalıştırmadan önce göster
      setopt HIST_FCNTL_LOCK        # Dosya kilitleme kullan
      setopt HIST_BEEP              # Geçmiş olaylarında uyarı sesi

      # Vi modu yapılandırması
      # Vim benzeri klavye kontrolü ve imleç yönetimi
      bindkey -v
      export KEYTIMEOUT=1

      # Vi modları için akıllı imleç şekillendirme
      function zle-keymap-select {
        if [[ ''${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
          echo -ne '\e[1 q'  # Blok imleç
        elif [[ ''${KEYMAP} == main ]] || [[ ''${KEYMAP} == viins ]] || [[ ''${KEYMAP} = ''' ]] || [[ $1 = 'beam' ]]; then
          echo -ne '\e[5 q'  # Çizgi imleç
        fi
      }
      zle -N zle-keymap-select

      # FZF (Fuzzy Finder) yapılandırması
      # Gelişmiş bulanık arama ve önizleme özellikleri
      export FZF_DEFAULT_OPTS="--height 80% --layout=reverse --border --cycle --marker='✓' --pointer='▶'"
      export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}'"
      export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
      export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"

      # fd entegrasyonu (hızlı dosya arama)
      if command -v fd > /dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude .cache'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --exclude node_modules --exclude .cache'
      fi

      # Zoxide entegrasyonu
      # Akıllı dizin geçiş sistemi
      eval "$(zoxide init zsh)"

      # Vi modu için özelleştirilmiş kısayollar
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

    # P10k tema yüklemesi
    initExtra = ''
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    '';

    # Komut geçmişi yapılandırması
    history = {
      size = 50000;                    # Hafızada tutulacak komut sayısı
      save = 50000;                    # Dosyada saklanacak komut sayısı
      path = "$XDG_CONFIG_HOME/zsh/history";  # Geçmiş dosyası konumu
      ignoreDups = true;               # Tekrarlanan komutları yoksay
      share = true;                    # Geçmişi tüm oturumlar arasında paylaş
      extended = true;                 # Genişletilmiş geçmiş formatı
      expireDuplicatesFirst = true;    # Önce tekrarları sil
      ignoreSpace = true;              # Boşlukla başlayan komutları yoksay
      ignoreAllDups = true;            # Tüm tekrarları yoksay
    };

    # ZSH eklentileri
    plugins = [
      {
        name = "fzf-tab";  # FZF tabanlı tamamlama menüsü
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
      {
        name = "powerlevel10k";  # Modern ve hızlı prompt teması
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "fast-syntax-highlighting";  # Hızlı sözdizimi vurgulama
        src = pkgs.zsh-fast-syntax-highlighting;
      }
      {
        name = "zsh-completions";  # Ek tamamlama tanımları
        src = pkgs.zsh-completions;
      }
      {
        name = "zsh-autosuggestions";  # Akıllı komut önerileri
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
      bindkey "^e" edit-command-line
      bindkey '^f' autosuggest-accept

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
      # Gelişmiş tamamlama menüsü ve önizleme özellikleri
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
        "git"                    # Git için kısayollar ve alias'lar
        "sudo"                   # ESC iki kez basınca sudo ekler
        "command-not-found"      # Komut bulunamadığında paket önerir
        "history"                # Geçmiş için ek özellikler
        "copypath"               # pwd'yi panoya kopyalar
        "dirhistory"             # Dizin geçmişi için kısayollar
        "colored-man-pages"      # Man sayfalarını renklendirir
        "ssh-agent"              # SSH agent yönetimi
        "extract"                # Arşiv dosyalarını otomatik çıkarır
        "aliases"                # Sık kullanılan komutlar için alias'lar
      ];
    };
  };
}
