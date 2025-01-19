#!/usr/bin/env bash

# Hata ayıklama
set -euo pipefail

# Dizin tanımlamaları
WOFI_DIR="$HOME/.config/wofi"
CACHE_DIR="$HOME/.cache/wofi-scripts/web-search"
BROWSER="zen-browser"

# Test edilmiş arama motorları
declare -A SITES=(
  # Genel Arama
  ["🔍 Google"]="https://www.google.com/search?q="
  ["🦆 DuckDuckGo"]="https://duckduckgo.com/?q="
  ["🌐 Brave"]="https://search.brave.com/search?q="
  ["🔍 Bing"]="https://www.bing.com/search?q="

  # Video Platformları
  ["📹 YouTube"]="https://www.youtube.com/results?search_query="
  ["📺 Odysee"]="https://odysee.com/$/search?q="
  ["🎥 Vimeo"]="https://vimeo.com/search?q="
  ["🎬 IMDb"]="https://www.imdb.com/find?q="
  ["🍿 FilmIzle"]="https://www.fullhdfilmizlesene.pw/search/"

  # Sosyal Medya
  ["👥 Reddit"]="https://www.reddit.com/search/?q="
  ["🐦 Twitter"]="https://twitter.com/search?q="
  ["📸 Instagram"]="https://www.instagram.com/explore/tags/"
  ["💭 Mastodon"]="https://mastodon.social/tags/"
  ["📌 Pinterest"]="https://www.pinterest.com/search/pins/?q="

  # Yazılım & Geliştirme
  ["💻 GitHub"]="https://github.com/search?q="
  ["🔧 Stack Overflow"]="https://stackoverflow.com/search?q="
  ["📚 DevDocs"]="https://devdocs.io/#q="
  ["🐧 ArchWiki"]="https://wiki.archlinux.org/index.php?search="
  ["🐋 Docker Hub"]="https://hub.docker.com/search?q="
  ["📦 NPM"]="https://www.npmjs.com/search?q="
  ["🐍 PyPI"]="https://pypi.org/search/?q="
  ["⚙️ GitLab"]="https://gitlab.com/search?search="

  # Paket Yöneticileri
  ["📦 AUR"]="https://aur.archlinux.org/packages?K="
  ["🎁 Flathub"]="https://flathub.org/apps/search/"
  ["📱 F-Droid"]="https://search.f-droid.org/?q="
  ["🪟 Snap Store"]="https://snapcraft.io/search?q="

  # Bilgi & Eğitim
  ["📖 Wikipedia"]="https://en.wikipedia.org/wiki/Special:Search?search="
  ["🎓 Google Scholar"]="https://scholar.google.com/scholar?q="
  ["📚 arXiv"]="https://arxiv.org/search/?query="
  ["🧪 PubMed"]="https://pubmed.ncbi.nlm.nih.gov/?term="
  ["📖 Medium"]="https://medium.com/search?q="

  # Müzik & Ses
  ["🎵 Spotify"]="https://open.spotify.com/search/"
  ["🎧 SoundCloud"]="https://soundcloud.com/search?q="
  ["🎼 Last.fm"]="https://www.last.fm/search?q="
  ["🎵 Deezer"]="https://www.deezer.com/search/"
  ["🎹 MuseScore"]="https://musescore.com/sheetmusic?text="

  # Oyun Platformları
  ["🎮 Steam"]="https://store.steampowered.com/search/?term="
  ["🎲 GOG"]="https://www.gog.com/games?search="
  ["🎮 Epic Games"]="https://store.epicgames.com/browse?q="
  ["🎮 itch.io"]="https://itch.io/search?q="
  ["🎲 ProtonDB"]="https://www.protondb.com/search?q="

  # Haritalar & Konum
  ["🗺️ OpenStreetMap"]="https://www.openstreetmap.org/search?query="
  ["📍 Google Maps"]="https://www.google.com/maps/search/"
  ["🚗 Waze"]="https://www.waze.com/live-map/directions?q="
  ["🌍 Wikivoyage"]="https://en.wikivoyage.org/w/index.php?search="

  # Alışveriş
  ["🛒 Amazon"]="https://www.amazon.com/s?k="
  ["🛍️ eBay"]="https://www.ebay.com/sch/i.html?_nkw="
  ["🛍️ AliExpress"]="https://www.aliexpress.com/wholesale?SearchText="
  ["🛒 Trendyol"]="https://www.trendyol.com/sr?q="
  ["🛍️ Hepsiburada"]="https://www.hepsiburada.com/ara?q="

  # Resim & Tasarım
  ["🖼️ DeviantArt"]="https://www.deviantart.com/search?q="
  ["📸 Unsplash"]="https://unsplash.com/s/photos/"
  ["🎨 ArtStation"]="https://www.artstation.com/search?q="
  ["📸 Flickr"]="https://www.flickr.com/search/?text="
  ["🎨 Behance"]="https://www.behance.net/search?search="

  # Döküman & E-Kitap
  ["📚 LibGen"]="https://libgen.is/search.php?req="
  ["📖 Project Gutenberg"]="https://www.gutenberg.org/ebooks/search/?query="
  ["📚 Google Books"]="https://www.google.com/search?tbm=bks&q="
  ["📑 Scribd"]="https://www.scribd.com/search?query="
  ["📚 Z-Library"]="https://z-lib.org/s/"
)

# URL encode fonksiyonu
url_encode() {
  python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$1"
}

# Kategorileri göster
generate_categories() {
  echo ">>> 🔍 General Search"
  for site in "${!SITES[@]}"; do
    case "$site" in
    *"Google"* | *"DuckDuckGo"* | *"Brave"* | *"Bing"*) echo "$site" ;;
    esac
  done
  echo ""

  echo ">>> 📹 Video & Media"
  for site in "${!SITES[@]}"; do
    case "$site" in
    *"YouTube"* | *"Odysee"* | *"Vimeo"* | *"IMDb"* | *"FilmIzle"*) echo "$site" ;;
    esac
  done
  echo ""

  echo ">>> 👥 Social Media"
  for site in "${!SITES[@]}"; do
    case "$site" in
    *"Reddit"* | *"Twitter"* | *"Instagram"* | *"Mastodon"* | *"Pinterest"*) echo "$site" ;;
    esac
  done
  echo ""

  echo ">>> 💻 Development"
  for site in "${!SITES[@]}"; do
    case "$site" in
    *"GitHub"* | *"Stack Overflow"* | *"DevDocs"* | *"ArchWiki"* | *"Docker"* | *"NPM"* | *"PyPI"* | *"GitLab"*) echo "$site" ;;
    esac
  done
  echo ""

  echo ">>> 📦 Package Managers"
  for site in "${!SITES[@]}"; do
    case "$site" in
    *"AUR"* | *"Flathub"* | *"F-Droid"* | *"Snap"*) echo "$site" ;;
    esac
  done
  echo ""

  echo ">>> 📚 Knowledge"
  for site in "${!SITES[@]}"; do
    case "$site" in
    *"Wikipedia"* | *"Scholar"* | *"arXiv"* | *"PubMed"* | *"Medium"*) echo "$site" ;;
    esac
  done
  echo ""

  echo ">>> 🎵 Music"
  for site in "${!SITES[@]}"; do
    case "$site" in
    *"Spotify"* | *"SoundCloud"* | *"Last.fm"* | *"Deezer"* | *"MuseScore"*) echo "$site" ;;
    esac
  done
  echo ""

  echo ">>> 🎮 Gaming"
  for site in "${!SITES[@]}"; do
    case "$site" in
    *"Steam"* | *"GOG"* | *"Epic"* | *"itch.io"* | *"ProtonDB"*) echo "$site" ;;
    esac
  done
  echo ""

  echo ">>> 🗺️ Maps"
  for site in "${!SITES[@]}"; do
    case "$site" in
    *"OpenStreetMap"* | *"Maps"* | *"Waze"* | *"Wikivoyage"*) echo "$site" ;;
    esac
  done
  echo ""

  echo ">>> 🛒 Shopping"
  for site in "${!SITES[@]}"; do
    case "$site" in
    *"Amazon"* | *"eBay"* | *"AliExpress"* | *"Trendyol"* | *"Hepsiburada"*) echo "$site" ;;
    esac
  done
  echo ""

  echo ">>> 🎨 Art & Images"
  for site in "${!SITES[@]}"; do
    case "$site" in
    *"DeviantArt"* | *"Unsplash"* | *"ArtStation"* | *"Flickr"* | *"Behance"*) echo "$site" ;;
    esac
  done
  echo ""

  echo ">>> 📚 Books & Documents"
  for site in "${!SITES[@]}"; do
    case "$site" in
    *"LibGen"* | *"Gutenberg"* | *"Books"* | *"Scribd"* | *"Z-Library"*) echo "$site" ;;
    esac
  done
}

# Arama motorunu seç
select_search_engine() {
  generate_categories | wofi \
    --dmenu \
    --style "$WOFI_DIR/styles/style.css" \
    --conf "$WOFI_DIR/configs/search" \
    --prompt "Search Engine:" \
    --cache-file=/dev/null \
    --insensitive \
    --matching=fuzzy
}

# Arama sorgusunu al
get_search_query() {
  local engine="$1"
  local cache_file="$CACHE_DIR/${engine// /_}.txt"
  local prompt="Search $engine:"

  if [[ -f "$cache_file" ]]; then
    (
      tail -n 10 "$cache_file"
      echo ""
    ) | wofi \
      --dmenu \
      --style "$WOFI_DIR/styles/style.css" \
      --conf "$WOFI_DIR/configs/search" \
      --prompt "$prompt" \
      --cache-file=/dev/null \
      --insensitive
  else
    wofi --dmenu \
      --style "$WOFI_DIR/styles/style.css" \
      --conf "$WOFI_DIR/configs/search" \
      --prompt "$prompt" \
      --cache-file=/dev/null \
      --insensitive
  fi
}

# Aramayı gerçekleştir
perform_search() {
  local engine="$1"
  local query="$2"
  local cache_file="$CACHE_DIR/${engine// /_}.txt"

  # Sorguyu önbelleğe kaydet
  if [[ -n "$query" ]] && ! grep -Fxq "$query" "$cache_file" 2>/dev/null; then
    echo "$query" >>"$cache_file"
    tail -n 100 "$cache_file" >"$cache_file.tmp" && mv "$cache_file.tmp" "$cache_file"
  fi

  # URL'yi encode et ve aç
  local encoded_query=$(url_encode "$query")
  if command -v "$BROWSER" &>/dev/null; then
    "$BROWSER" "${SITES[$engine]}${encoded_query}"
  else
    notify-send "Error" "$BROWSER not found. Using xdg-open instead."
    xdg-open "${SITES[$engine]}${encoded_query}"
  fi
}

main() {
  # Gerekli programları kontrol et
  for cmd in wofi python3 "$BROWSER" notify-send; do
    if ! command -v "$cmd" &>/dev/null; then
      notify-send "Warning" "$cmd is not installed"
    fi
  done

  # Önbellek dizinini oluştur
  mkdir -p "$CACHE_DIR"

  # Arama motorunu seç
  local engine
  if ! engine=$(select_search_engine); then
    exit 0
  fi

  # Kategori başlığı seçildiyse atla
  if [[ "$engine" == ">>> "* ]]; then
    exit 0
  fi

  # Sorguyu al
  local query
  if ! query=$(get_search_query "$engine"); then
    exit 0
  fi

  # Boş sorgu kontrolü
  if [[ -z "$query" ]]; then
    exit 0
  fi

  # Aramayı gerçekleştir
  perform_search "$engine" "$query"
}

# Programı çalıştır
main
