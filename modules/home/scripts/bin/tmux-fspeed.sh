#!/usr/bin/env bash

# Scriptin bulunduğu dizin ve cache dosyası
DIR="$HOME/.config/tmux/fzf"
CACHE_FILE="$HOME/.cache/fzf_cache"

# Cache dosyasını oluştur (yoksa)
touch "$CACHE_FILE"

# İstatistikler
total=$(find "$DIR" -type f -name '_*' | wc -l)
ssh_count=$(find "$DIR" -type f -name '_ssh*' | wc -l)
tmux_count=$(find "$DIR" -type f -name '_tmux*' | wc -l)

# Sık kullanılanları al
get_frequent() {
  if [ -f "$CACHE_FILE" ] && [ -s "$CACHE_FILE" ]; then
    cat "$CACHE_FILE" |
      sort |
      uniq -c |
      sort -nr |
      head -n 10 |
      awk '{print $2}' |
      sed 's/^/⭐ /'
  fi
}

# FZF için ayarlar
export FZF_DEFAULT_OPTS="\
    -e -i \
    --delimiter=_ \
    --with-nth=2.. \
    --info=default \
    --layout=reverse \
    --margin=1 \
    --padding=1 \
    --ansi \
    --prompt='Speed:' \
    --pointer='❯' \
    --header='Toplam: $total | SSH: $ssh_count | TMUX: $tmux_count | ESC ile çık, ENTER ile çalıştır' \
    --color='header:blue' \
    --color='prompt:cyan' \
    --color='pointer:magenta' \
    --tiebreak=index"

# Ana komut
SELECTED="$(
  (
    # Sık kullanılanlar
    get_frequent
    # Tüm liste
    find "$DIR" -maxdepth 1 -type f -exec basename {} \; |
      sort |
      grep '^_' |
      sed 's@\.@ @g'
  ) |
    column -s ',' -t |
    fzf |
    sed 's/^⭐ //' |
    cut -d ' ' -f1
)"

# Seçim yapılmadıysa çık
[ -z "$SELECTED" ] && exit 1

# Kullanımı kaydet (sadece script adını)
echo "${SELECTED}" >>"$CACHE_FILE"

# Cache dosyasını maksimum 100 satırda tut
if [ "$(wc -l <"$CACHE_FILE")" -gt 100 ]; then
  tail -n 100 "$CACHE_FILE" >"$CACHE_FILE.tmp" &&
    mv "$CACHE_FILE.tmp" "$CACHE_FILE"
fi

# Seçilen scripti çalıştır
eval "${DIR}/${SELECTED},*"
