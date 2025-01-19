#!/usr/bin/env sh

# Yapılandırma dizinleri ve dosyaları
CONFIG_DIR="$HOME/.anote/cheats"
CACHE_DIR="$HOME/.cache/anote"
SNIPPET_FILE="$CONFIG_DIR/snippetrc"
SNIPPET_CACHE="$CACHE_DIR/snippetrc"
MULTI_CACHE="$CACHE_DIR/multi"
EDITOR="${EDITOR:-nvim}"

# Gerekli dizinleri ve dosyaları oluştur
mkdir -p "$CONFIG_DIR" "$CACHE_DIR"
touch "$SNIPPET_FILE" "$SNIPPET_CACHE" "$MULTI_CACHE"

# Yardım mesajı
show_help() {
  cat <<EOF
Kullanım: $(basename "$0") [seçenek]

Seçenekler:
    -s, --snippet     Tek satır snippet modunda çalıştır
    -m, --multi      Çok satırlı metin bloğu modunda çalıştır
    -h, --help       Bu yardım mesajını göster

Örnekler:
    $(basename "$0") -s    # Tek satır snippet seç
    $(basename "$0") -m    # Çok satırlı metin bloğu seç
EOF
  exit 0
}

# Cache güncelleme fonksiyonu
update_cache() {
  local item="$1"
  local cache_file="$2"
  # Cache dosyasından aynı satırı sil
  sed -i "\|^$item$|d" "$cache_file"
  # Yeni satırı başa ekle
  printf '%s\n' "$item" | cat - "$cache_file" >"$CONFIG_DIR/temp" && mv "$CONFIG_DIR/temp" "$cache_file"
  # Cache'i sınırla
  tail -n 100 "$cache_file" >"$CONFIG_DIR/temp" && mv "$CONFIG_DIR/temp" "$cache_file"
}

# Panoya kopyalama fonksiyonu
copy_to_clipboard() {
  local content="$1"
  local notify=""

  if command -v wl-copy >/dev/null; then
    printf '%s' "$content" | wl-copy && notify="wl-copy ile kopyalandı"
  elif command -v xsel >/dev/null; then
    printf '%s' "$content" | xsel -b && notify="xsel ile kopyalandı"
  elif command -v xclip >/dev/null; then
    printf '%s' "$content" | xclip -selection clipboard && notify="xclip ile kopyalandı"
  else
    echo "HATA: Pano uygulaması bulunamadı"
    exit 1
  fi

  # tmux açıksa oraya da kopyala
  if [ -n "$TMUX" ]; then
    printf '%s' "$content" | tmux load-buffer -
    tmux display-message "Kopyalandı: $content"
  fi

  # Sistem bildirimi gönder (1000ms = 1 saniye süreyle)
  if command -v notify-send >/dev/null; then
    notify-send -t 1000 "Kopyalandı" "$content"
  fi
}

# Tek satır snippet modu
snippet_mode() {
  local selected
  selected="$(cat "$SNIPPET_CACHE" "$SNIPPET_FILE" | awk '!seen[$0]++' |
    sed '/^$/d' |
    fzf -e -i \
      --prompt="Panoya kopyalanacak snippet: " \
      --info=default \
      --layout=reverse \
      --tiebreak=index \
      --header="CTRL+E: Düzenle | ESC: Çıkış | ENTER: Kopyala" \
      --bind "ctrl-e:execute($EDITOR $SNIPPET_FILE < /dev/tty > /dev/tty)" |
    sed -e 's/;;.*$//' |
    sed 's/^[ \t]*//;s/[ \t]*$//' |
    tr -d '\n')"

  [ -z "$selected" ] && exit 0

  update_cache "$selected" "$SNIPPET_CACHE"
  copy_to_clipboard "$selected"
}

# Çok satırlı metin bloğu modu
multi_mode() {
  local selected
  selected="$({
    cat "$MULTI_CACHE"
    find "$CONFIG_DIR" -type f -not -name ".*"
  } |
    awk '!seen[$0]++' |
    sort |
    fzf -e -i \
      --delimiter / \
      --with-nth -1 \
      --preview 'cat {}' \
      --preview-window='right:60%:wrap' \
      --prompt="Metin bloğu seç: " \
      --header="ESC: Çıkış | ENTER: Kopyala | CTRL+E: Düzenle" \
      --info=hidden \
      --layout=reverse \
      --tiebreak=index \
      --bind "ctrl-e:execute($EDITOR {} < /dev/tty > /dev/tty)")"

  [ -z "$selected" ] && exit 0

  update_cache "$selected" "$MULTI_CACHE"
  copy_to_clipboard "$(cat "$selected")"
}

# Ana program mantığı
case "$1" in
-s | --snippet)
  snippet_mode
  ;;
-m | --multi)
  multi_mode
  ;;
-h | --help)
  show_help
  ;;
*)
  show_help
  ;;
esac
