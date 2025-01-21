#!/usr/bin/env bash

show_help() {
  echo "Usage: $0 [OPTION]"
  echo "  -p, --path PATH    Dizin yolu (varsayılan: mevcut dizin)"
  echo "  -d, --debug        Debug bilgileri"
  echo "  -h, --help         Yardım"
}

SEARCH_PATH="."
DEBUG=0

while [ "$1" != "" ]; do
  case $1 in
  -p | --path)
    shift
    SEARCH_PATH=$1
    ;;
  -d | --debug)
    DEBUG=1
    ;;
  -h | --help)
    show_help
    exit
    ;;
  *)
    show_help
    exit 1
    ;;
  esac
  shift
done

[ ! -d "$SEARCH_PATH" ] && {
  echo "Hata: '$SEARCH_PATH' dizini bulunamadı"
  exit 1
}

TMP_FILE=$(mktemp)
[ $DEBUG -eq 1 ] && echo "Geçici dosya: $TMP_FILE"

find "$SEARCH_PATH" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -exec md5sum {} + | sort >"$TMP_FILE"

declare -A SEEN
FOUND_DUPLICATES=0

while IFS=' ' read -r hash file; do
  if [ -n "${SEEN[$hash]}" ]; then
    FOUND_DUPLICATES=1
    echo -e "\nBulundu:"
    echo "1: ${SEEN[$hash]}"
    echo "2: $file"
    read -p "2 numaralı dosya silinsin mi? (e/h): " answer
    if [ "$answer" = "e" ]; then
      rm -v "$file"
    fi
  else
    SEEN[$hash]="$file"
  fi
done <"$TMP_FILE"

[ $FOUND_DUPLICATES -eq 0 ] && echo "Duplicate dosya bulunamadı."

rm "$TMP_FILE"
