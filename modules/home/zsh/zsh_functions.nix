{ lib, config, pkgs, host, ... }:

{
  programs.zsh = {
    enable = true;
    initExtra = ''
      # Yazi file manager wrapper
      function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }

      # Alternative Yazi function
      function k() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }

      # External IP check function
      function wanip() {
        local ip
        ip=$(curl -s https://am.i.mullvad.net/ip 2>/dev/null) && echo "Mullvad IP: $ip" && return 0
        ip=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null) && echo "OpenDNS IP: $ip" && return 0
        ip=$(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com 2>/dev/null | tr -d '"') && echo "Google DNS IP: $ip" && return 0
        echo "Error: Could not determine IP address"
        return 1
      }

      # File transfer via transfer.sh
      function transfer() {  
        if [ -z "$1" ]; then
          echo "usage: transfer FILE_TO_TRANSFER"
          return 1
        fi
        tmpfile=$(mktemp -t transferXXX)
        curl --progress-bar --upload-file "$1" "https://transfer.sh/$(basename $1)" >> $tmpfile
        cat $tmpfile
        rm -f $tmpfile
      }

      # Quick file edit/create
      function v() {
        local file="$1"
        if [[ -z "$file" ]]; then
          echo "Error: File name required."
          return 1
        fi
        [[ ! -f "$file" ]] && touch "$file"
        chmod 755 "$file"
        vim -c "set paste" "$file"
      }

      # Edit command path
      function vw() {
        local file
        if [[ -n "$1" ]]; then
          file=$(which "$1" 2>/dev/null)
          if [[ -n "$file" ]]; then
            echo "File found: $file"
            vim "$file"
          else
            echo "File not found: $1"
          fi
        else
          echo "Usage: vwhich <filename>"
        fi
      }

      # NixOS package dependencies (simple version)
      function nix_depends() {
        if [ -z "$1" ]; then
          echo "Usage: nix_depends <package-name>"
          return 1
        fi
        nix-store --query --referrers $(which "$1" 2>/dev/null || echo "/run/current-system/sw/bin/$1")
      }

      # NixOS package dependencies (detailed version)
      function nix_deps() {
        if [ -z "$1" ]; then
          echo "Usage: nix_deps <package-name>"
          return 1
        fi
        
        echo "Direct dependencies:"
        nix-store -q --references $(which "$1" 2>/dev/null || echo "/run/current-system/sw/bin/$1")
        
        echo -e "\nReverse dependencies (packages that depend on this):"
        nix-store -q --referrers $(which "$1" 2>/dev/null || echo "/run/current-system/sw/bin/$1")
        
        echo -e "\nRuntime dependencies:"
        nix-store -q --requisites $(which "$1" 2>/dev/null || echo "/run/current-system/sw/bin/$1")
      }

      # Universal archive extractor
      function ex() {
        if [ -f $1 ] ; then
          case $1 in
            *.tar.bz2)   tar xjf $1   ;;
            *.tar.gz)    tar xzf $1   ;;
            *.bz2)       bunzip2 $1   ;;
            *.rar)       unrar x $1   ;;
            *.gz)        gunzip $1    ;;
            *.tar)       tar xf $1    ;;
            *.tbz2)      tar xjf $1   ;;
            *.tgz)       tar xzf $1   ;;
            *.zip)       unzip $1     ;;
            *.Z)         uncompress $1;;
            *.7z)        7z x $1      ;;
            *.deb)       ar x $1      ;;
            *.tar.xz)    tar xf $1    ;;
            *.tar.zst)   tar xf $1    ;;
            *)           echo "'$1' cannot be extracted via ex()" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }

      # FZF enhanced file search
      function fif() {
        if [ ! "$#" -gt 0 ]; then echo "Search term required"; return 1; fi
        fd --type f --hidden --follow --exclude .git \
        | fzf -m --preview="bat --style=numbers --color=always {} 2>/dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
      }

      # FZF directory history search
      function fcd() {
        local dir
        dir=$(dirs -v | fzf --height 40% --reverse | cut -f2-)
        if [[ -n "$dir" ]]; then
          cd "$dir"
        fi
      }

      # FZF git commit search
      function fgco() {
        local commits commit
        commits=$(git log --pretty=oneline --abbrev-commit --reverse) &&
        commit=$(echo "$commits" | fzf --tac +s +m -e) &&
        git checkout $(echo "$commit" | sed "s/ .*//")
      }
    '';
  };
}
