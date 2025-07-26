# ==============================================================================
# ZSH Özel Fonksiyonları Yapılandırması
# ==============================================================================
{ lib, config, pkgs, host, ... }:
{
  programs.zsh = {
    enable = true;
    initContent = ''
      # =============================================================================
      # Dosya Yöneticisi Fonksiyonları
      # =============================================================================
      # Yazi sarmalayıcı fonksiyonu
      function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }

      # Alternatif Yazi fonksiyonu (k komutu ile)
      function k() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }

      # =============================================================================
      # Ağ Fonksiyonları
      # =============================================================================
      # Dış IP kontrol fonksiyonu
      function wanip() {
        local ip
        ip=$(curl -s https://am.i.mullvad.net/ip 2>/dev/null) && echo "Mullvad IP: $ip" && return 0
        ip=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null) && echo "OpenDNS IP: $ip" && return 0
        ip=$(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com 2>/dev/null | tr -d '"') && echo "Google DNS IP: $ip" && return 0
        echo "Hata: IP adresi belirlenemedi"
        return 1
      }

      # Dosya transfer fonksiyonu
      function transfer() {  
        if [ -z "$1" ]; then
          echo "Kullanım: transfer TRANSFER_EDILECEK_DOSYA"
          return 1
        fi
        tmpfile=$(mktemp -t transferXXX)
        curl --progress-bar --upload-file "$1" "https://transfer.sh/$(basename $1)" >> $tmpfile
        cat $tmpfile
        rm -f $tmpfile
      }

      # =============================================================================
      # Dosya Düzenleme Fonksiyonları
      # =============================================================================
      # Hızlı dosya düzenleyici
      function v() {
        local file="$1"
        if [[ -z "$file" ]]; then
          echo "Hata: Dosya adı gerekli."
          return 1
        fi
        [[ ! -f "$file" ]] && touch "$file"
        chmod 755 "$file"
        vim -c "set paste" "$file"
      }

      # Komut yolu düzenleme
      function vw() {
        local file
        if [[ -n "$1" ]]; then
          file=$(which "$1" 2>/dev/null)
          if [[ -n "$file" ]]; then
            echo "Dosya bulundu: $file"
            vim "$file"
          else
            echo "Dosya bulunamadı: $1"
          fi
        else
          echo "Kullanım: vwhich <dosya-adı>"
        fi
      }

      # =============================================================================
      # Arşiv Yönetimi Fonksiyonları
      # =============================================================================
      # Evrensel arşiv çıkarıcı
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
            *)           echo "'$1' ex() ile çıkarılamıyor" ;;
          esac
        else
          echo "'$1' geçerli bir dosya değil"
        fi
      }

      # =============================================================================
      # FZF Gelişmiş Fonksiyonları
      # =============================================================================
      # Dosya içeriği arama
      function fif() {
        if [ ! "$#" -gt 0 ]; then echo "Arama terimi gerekli"; return 1; fi
        fd --type f --hidden --follow --exclude .git \
        | fzf -m --preview="bat --style=numbers --color=always {} 2>/dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
      }

      # Dizin geçmişi arama
      function fcd() {
        local dir
        dir=$(dirs -v | fzf --height 40% --reverse | cut -f2-)
        if [[ -n "$dir" ]]; then
          cd "$dir"
        fi
      }

      # Git commit arama
      function fgco() {
        local commits commit
        commits=$(git log --pretty=oneline --abbrev-commit --reverse) &&
        commit=$(echo "$commits" | fzf --tac +s +m -e) &&
        git checkout $(echo "$commit" | sed "s/ .*//")
      }

      # =============================================================================
      # History temizleme fonksiyonu
      # =============================================================================
      function cleanhistory() {
        print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +m --height 50% --reverse --border --header="DEL tuşu ile seçili komutu sil, ESC ile çık" \
        --bind="del:execute(sed -i '/{}/d' $HISTFILE)+reload(fc -R; ([ -n "$ZSH_NAME" ] && fc -l 1 || history))" \
        --preview="echo {}" --preview-window=up:3:hidden:wrap --bind="?:toggle-preview")
      }

      # =============================================================================
      # Nix Paket Yönetimi Fonksiyonları
      # =============================================================================
      # Basit bağımlılık görüntüleyici
      function nix_depends() {
        if [ -z "$1" ]; then
          echo "Kullanım: nix_depends <paket-adı>"
          return 1
        fi
        nix-store --query --referrers $(which "$1" 2>/dev/null || echo "/run/current-system/sw/bin/$1")
      }

      # Detaylı bağımlılık görüntüleyici
      function nix_deps() {
        if [ -z "$1" ]; then
          echo "Kullanım: nix_deps <paket-adı>"
          return 1
        fi
        
        echo "Doğrudan bağımlılıklar:"
        nix-store -q --references $(which "$1" 2>/dev/null || echo "/run/current-system/sw/bin/$1")
        
        echo -e "\nTers bağımlılıklar (bu pakete bağımlı paketler):"
        nix-store -q --referrers $(which "$1" 2>/dev/null || echo "/run/current-system/sw/bin/$1")
        
        echo -e "\nÇalışma zamanı bağımlılıkları:"
        nix-store -q --requisites $(which "$1" 2>/dev/null || echo "/run/current-system/sw/bin/$1")
      }

      # =============================================================================
      # Nix Temizleme Fonksiyonları
      # =============================================================================
      # Hızlı Nix temizliği (alias)
      alias nxc="nix-collect-garbage -d && nix-store --gc"

      # Detaylı Nix temizliği (GC roots dahil)
      function           nixdeepclean() {
        echo "🧹 Nix detaylı temizlik başlıyor..."
        
        # GC roots temizliği
        echo "📂 Gereksiz GC root'ları temizleniyor..."
        nix-store --gc --print-roots | \
          egrep -v "^(/nix/var|/run/\w+-system|\{memory|/proc)" | \
          awk '{ print $1 }' | \
          grep -vE 'home-manager|flake-registry\.json' | \
          xargs -L1 unlink 2>/dev/null || true
        
        # Garbage collection
        echo "🗑️  Garbage collection çalışıyor..."
        nix-collect-garbage -d
        
        # Store optimizasyonu
        echo "⚡ Store optimize ediliyor..."
        nix-store --optimise
        
        echo "✅ Detaylı temizlik tamamlandı!"
        
        # Temizlik sonrası bilgi
        echo "📊 Temizlik sonrası durum:"
        du -sh /nix/store 2>/dev/null || echo "Store boyutu hesaplanamadı"
      }

      # Güvenli Nix temizliği (önizleme ile)
      function nix_clean_preview() {
        echo "🔍 Silinecek GC root'ları önizleniyor..."
        local roots_to_delete
        roots_to_delete=$(nix-store --gc --print-roots | \
          egrep -v "^(/nix/var|/run/\w+-system|\{memory|/proc)" | \
          awk '{ print $1 }' | \
          grep -vE 'home-manager|flake-registry\.json')
        
        if [[ -z "$roots_to_delete" ]]; then
          echo "✅ Silinecek gereksiz GC root bulunamadı."
        else
          echo "📋 Silinecek GC roots:"
          echo "$roots_to_delete"
          echo ""
        fi
        
        # Garbage collection önizlemesi
        echo "🗑️  Garbage collection simülasyonu..."
        nix-collect-garbage -d --dry-run
        
        echo ""
        echo -n "🤔 Temizlik işlemini başlatmak istiyor musunuz? (y/N): "
        read answer
        if [[ $answer == "y" || $answer == "Y" ]]; then
          nix_clean
        else
          echo "❌ Temizlik iptal edildi."
        fi
      }

      # Nix store boyutu kontrolü
      function nix_store_size() {
        echo "📊 Nix Store Analizi:"
        echo "├─ Store toplam boyutu: $(du -sh /nix/store 2>/dev/null | cut -f1 || echo 'Hesaplanamadı')"
        echo "├─ Toplam paket sayısı: $(ls /nix/store | wc -l 2>/dev/null || echo 'Hesaplanamadı')"
        echo "├─ GC root sayısı: $(nix-store --gc --print-roots | wc -l 2>/dev/null || echo 'Hesaplanamadı')"
        echo "└─ Eski generasyon sayısı: $(nix-env --list-generations | wc -l 2>/dev/null || echo 'Hesaplanamadı')"
      }

      # Nix profil temizliği
      function nix_profile_clean() {
        echo "🔄 Nix profilleri temizleniyor..."
        
        # Kullanıcı profili generasyonları
        echo "👤 Kullanıcı profili generasyonları:"
        nix-env --list-generations
        
        echo -n "🤔 Eski generasyonları silmek istiyor musunuz? (y/N): "
        read answer
        if [[ $answer == "y" || $answer == "Y" ]]; then
          nix-env --delete-generations old
          echo "✅ Eski generasyonlar silindi."
        fi
        
        # Sistem profili (eğer NixOS kullanıyorsa)
        if command -v nixos-rebuild >/dev/null 2>&1; then
          echo "🖥️  Sistem profili generasyonları temizleniyor..."
          sudo nix-collect-garbage -d
          echo "✅ Sistem profili temizlendi."
        fi
      }
    '';
  };
}

