#!/usr/bin/env bash

# gitgo.sh - Interactive Git workflow helper script
#
# Description: This script provides an interactive interface for Git operations,
# including file selection, commit message input, and push functionality with
# colorful status indicators and emoji support.
#
# Author: [Your name]
# Created: [Date]
# Version: 1.0

# Hata ayıklama için strict mode
set -euo pipefail

# Renkler ve stiller
declare -A COLORS=(
  ["RED"]='\033[0;31m'
  ["GREEN"]='\033[0;32m'
  ["YELLOW"]='\033[1;33m'
  ["BLUE"]='\033[0;34m'
  ["PURPLE"]='\033[0;35m'
  ["CYAN"]='\033[0;36m'
  ["GRAY"]='\033[0;90m'
  ["NC"]='\033[0m'
  ["BOLD"]='\033[1m'
)

# Mesaj fonksiyonları
print_info() { echo -e "${COLORS[BLUE]}ℹ️  $1${COLORS[NC]}"; }
print_success() { echo -e "${COLORS[GREEN]}✅ $1${COLORS[NC]}"; }
print_warning() { echo -e "${COLORS[YELLOW]}⚠️  $1${COLORS[NC]}"; }
print_error() { echo -e "${COLORS[RED]}❌ $1${COLORS[NC]}"; }

# Çıkış fonksiyonu
cleanup_and_exit() {
  local exit_code=$1
  local message=$2
  [[ -n "$message" ]] && echo -e "$message"
  exit "$exit_code"
}

# Git kontrollerini yapan fonksiyon
check_git_setup() {
  [[ ! -d .git ]] && cleanup_and_exit 1 "${COLORS[RED]}❌ Bu dizin bir git deposu değil.${COLORS[NC]}"
  command -v git &>/dev/null || cleanup_and_exit 1 "${COLORS[RED]}❌ Git kurulu değil.${COLORS[NC]}"
  git remote get-url origin &>/dev/null || cleanup_and_exit 1 "${COLORS[RED]}❌ Uzak depo ayarlanmamış.${COLORS[NC]}"
}

# Dosya durumunu formatlayan fonksiyon
format_file_status() {
  local status=$1
  local file=$2
  local counter=$3

  case "${status:0:1}" in
  "R")
    # Rename durumu için özel işleme
    local old_file=${file% -> *}
    local new_file=${file#* -> }
    echo -e "${counter}) ${COLORS[CYAN]}${old_file}${COLORS[NC]} → ${COLORS[GREEN]}${new_file}${COLORS[NC]} ${COLORS[GRAY]}(Yeniden adlandırıldı)${COLORS[NC]}"
    ;;
  "?") echo -e "${counter}) ${COLORS[PURPLE]}${file}${COLORS[NC]} ${COLORS[GRAY]}(Yeni dosya)${COLORS[NC]}" ;;
  "M") echo -e "${counter}) ${COLORS[YELLOW]}${file}${COLORS[NC]} ${COLORS[GRAY]}(Değiştirildi)${COLORS[NC]}" ;;
  "D") echo -e "${counter}) ${COLORS[RED]}${file}${COLORS[NC]} ${COLORS[GRAY]}(Silindi)${COLORS[NC]}" ;;
  "A") echo -e "${counter}) ${COLORS[GREEN]}${file}${COLORS[NC]} ${COLORS[GRAY]}(Eklendi)${COLORS[NC]}" ;;
  *) echo -e "${counter}) ${COLORS[CYAN]}${file}${COLORS[NC]} ${COLORS[GRAY]}($status)${COLORS[NC]}" ;;
  esac
}

# Kullanıcı onayı alan fonksiyon
get_confirmation() {
  local prompt=$1
  local default=${2:-false}

  echo -e "\n${COLORS[YELLOW]}$prompt ${COLORS[NC]}${COLORS[GRAY]}(e/H)${COLORS[NC]}"
  read -r confirm
  [[ "$confirm" =~ ^[Ee]$ ]]
}

# Dosya seçme fonksiyonu
select_files() {
  echo -e "${COLORS[BOLD]}📋 Değişiklik yapılan dosyalar:${COLORS[NC]}"
  local -a files=()
  local -a statuses=()
  local counter=1

  # Staged ve modified dosyaları al
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      local status=${line:0:2}
      local file=${line:3}
      files+=("$file")
      statuses+=("$status")
      format_file_status "$status" "$file" "$counter"
      ((counter++))
    fi
  done < <(git status --porcelain)

  [[ ${#files[@]} -eq 0 ]] && cleanup_and_exit 1 "${COLORS[RED]}❌ Eklenecek dosya yok.${COLORS[NC]}"

  echo -e "\n${COLORS[BOLD]}💡 Eklemek istediğiniz dosyaların numaralarını girin ${COLORS[GRAY]}(örn: 1 3 5)${COLORS[NC]}"
  echo -e "${COLORS[GRAY]}💡 Tüm dosyaları eklemek için 'a' yazın"
  echo -e "💡 İşlemi iptal etmek için 'q' yazın${COLORS[NC]}"
  read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz:${COLORS[NC]} ")" choices

  case "$choices" in
  [qQ]) cleanup_and_exit 0 "${COLORS[RED]}❌ İşlem iptal edildi.${COLORS[NC]}" ;;
  [aA])
    get_confirmation "Tüm dosyalar eklenecek. Emin misiniz?" || cleanup_and_exit 0 "${COLORS[RED]}❌ İşlem iptal edildi.${COLORS[NC]}"
    git add .
    return
    ;;
  *)
    local -a selected=()
    for num in $choices; do
      if [[ "$num" =~ ^[0-9]+$ ]] && ((num > 0 && num <= ${#files[@]})); then
        if [[ "${statuses[$((num - 1))]}" == "R"* ]]; then
          # Rename durumunda yeni dosya adını kullan
          local new_file=${files[$((num - 1))]#* -> }
          git add "$new_file"
          selected+=("$new_file")
        else
          git add "${files[$((num - 1))]}"
          selected+=("${files[$((num - 1))]}")
        fi
      fi
    done

    if [[ ${#selected[@]} -gt 0 ]]; then
      print_success "\nSeçilen dosyalar eklendi:"
      printf "${COLORS[CYAN]}%s${COLORS[NC]}\n" "${selected[@]}"

      get_confirmation "\nSeçiminiz doğru mu?" || {
        git restore --staged "${selected[@]}"
        cleanup_and_exit 0 "${COLORS[RED]}❌ İşlem iptal edildi.${COLORS[NC]}"
      }
    else
      cleanup_and_exit 1 "${COLORS[RED]}❌ Hiçbir dosya seçilmedi.${COLORS[NC]}"
    fi
    ;;
  esac
}

# Ana fonksiyon
main() {
  check_git_setup

  # Güncel değişiklikleri kontrol et
  print_info "📥 Uzak depodaki değişiklikler kontrol ediliyor..."
  git fetch

  # Uzak depodan geri miyiz?
  local behind_count
  behind_count=$(git rev-list HEAD..@{u} --count 2>/dev/null || echo "0")
  if ((behind_count > 0)); then
    print_warning "Dalınız $behind_count commit geride."
    if get_confirmation "📝 Değişiklikler çekilsin mi?"; then
      git pull || cleanup_and_exit 1 "${COLORS[RED]}❌ Pull başarısız oldu.${COLORS[NC]}"
    fi
  fi

  # Dosya seçimi yap
  select_files

  # Commit mesajını iste
  echo -e "\n${COLORS[BOLD]}💭 Commit mesajını girin:${COLORS[NC]}"
  read -r commit_msg

  [[ -z "$commit_msg" ]] && cleanup_and_exit 1 "${COLORS[RED]}❌ Commit mesajı boş olamaz.${COLORS[NC]}"

  # Son kontrol ve commit
  get_confirmation "📝 Commit yapılsın mı?" || {
    git restore --staged .
    cleanup_and_exit 0 "${COLORS[RED]}❌ İşlem iptal edildi.${COLORS[NC]}"
  }

  print_info "💾 Commit yapılıyor..."
  git commit -m "$commit_msg"

  # Push işlemi
  if get_confirmation "☁️  Push yapılsın mı?"; then
    if git push origin "$(git rev-parse --abbrev-ref HEAD)"; then
      print_success "✨ Tamamlandı! Değişiklikler başarıyla gönderildi."
    else
      cleanup_and_exit 1 "${COLORS[RED]}❌ Push başarısız oldu.${COLORS[NC]}"
    fi
  else
    print_warning "Push işlemi iptal edildi."
  fi
}

# Scripti çalıştır
main "$@"
