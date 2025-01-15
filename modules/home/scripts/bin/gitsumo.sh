#!/usr/bin/env bash

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

# Temel yardımcı fonksiyonlar
print_info() { echo -e "${COLORS[BLUE]}ℹ️  $1${COLORS[NC]}"; }
print_success() { echo -e "${COLORS[GREEN]}✅ $1${COLORS[NC]}"; }
print_warning() { echo -e "${COLORS[YELLOW]}⚠️  $1${COLORS[NC]}"; }
print_error() { echo -e "${COLORS[RED]}❌ $1${COLORS[NC]}"; }

# Dosya durumunu formatlayan fonksiyon
format_file_status() {
  local status=$1
  local file=$2
  local counter=$3

  case "$status" in
  "??") echo -e "${counter}) ${COLORS[PURPLE]}${file}${COLORS[NC]} ${COLORS[GRAY]}(Yeni dosya)${COLORS[NC]}" ;;
  "M") echo -e "${counter}) ${COLORS[YELLOW]}${file}${COLORS[NC]} ${COLORS[GRAY]}(Değiştirildi)${COLORS[NC]}" ;;
  "D") echo -e "${counter}) ${COLORS[RED]}${file}${COLORS[NC]} ${COLORS[GRAY]}(Silindi)${COLORS[NC]}" ;;
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

# Branch yönetimi
manage_branches() {
  echo -e "\n${COLORS[BOLD]}🌿 Branch İşlemleri${COLORS[NC]}"
  echo "1) Branch listesi (local)"
  echo "2) Branch listesi (remote)"
  echo "3) Branch oluştur"
  echo "4) Branch sil (local)"
  echo "5) Branch sil (remote)"
  echo "6) Branch'leri merge et"
  echo "0) Geri dön"

  read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz (0-6):${COLORS[NC]} ")" branch_choice

  case "$branch_choice" in
  1)
    echo -e "\n${COLORS[BOLD]}Local Branchler:${COLORS[NC]}"
    git branch
    ;;
  2)
    echo -e "\n${COLORS[BOLD]}Remote Branchler:${COLORS[NC]}"
    git branch -r
    ;;
  3)
    echo -e "\n${COLORS[BOLD]}Yeni branch adını girin:${COLORS[NC]}"
    read -r new_branch
    if [[ -n "$new_branch" ]]; then
      git checkout -b "$new_branch" && print_success "Branch '$new_branch' oluşturuldu ve geçiş yapıldı."
    else
      print_error "Branch adı boş olamaz."
    fi
    ;;
  4)
    echo -e "\n${COLORS[BOLD]}Silinecek local branch adını girin:${COLORS[NC]}"
    read -r branch_to_delete
    if [[ -n "$branch_to_delete" ]] && git show-ref --verify --quiet "refs/heads/$branch_to_delete"; then
      if get_confirmation "Bu branch silinecek. Emin misiniz?"; then
        git branch -d "$branch_to_delete" && print_success "Branch başarıyla silindi."
      fi
    else
      print_error "Branch bulunamadı."
    fi
    ;;
  5)
    echo -e "\n${COLORS[BOLD]}Silinecek remote branch adını girin:${COLORS[NC]}"
    read -r remote_branch
    if [[ -n "$remote_branch" ]]; then
      if get_confirmation "Bu remote branch silinecek. Emin misiniz?"; then
        git push origin --delete "$remote_branch" && print_success "Remote branch başarıyla silindi."
      fi
    else
      print_error "Branch adı boş olamaz."
    fi
    ;;
  6)
    echo -e "\n${COLORS[BOLD]}Merge edilecek branch adını girin:${COLORS[NC]}"
    read -r branch_to_merge
    if [[ -n "$branch_to_merge" ]] && git show-ref --verify --quiet "refs/heads/$branch_to_merge"; then
      if get_confirmation "Bu branch merge edilecek. Emin misiniz?"; then
        git merge "$branch_to_merge" && print_success "Branch başarıyla merge edildi."
      fi
    else
      print_error "Branch bulunamadı."
    fi
    ;;
  0) return ;;
  *) print_error "Geçersiz seçim." ;;
  esac
}

# Git clean işlemleri
# Git clean işlemleri
manage_clean() {
  echo -e "\n${COLORS[BOLD]}🧹 Git Clean İşlemleri${COLORS[NC]}"
  echo "1) Takip edilmeyen dosyaları listele"
  echo "2) Takip edilmeyen dosyaları temizle"
  echo "3) Git ignore yönetimi"
  echo "0) Geri dön"

  read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz (0-3):${COLORS[NC]} ")" clean_choice

  case "$clean_choice" in
  1)
    echo -e "\n${COLORS[BOLD]}Takip Edilmeyen Dosyalar:${COLORS[NC]}"
    git clean -n
    ;;
  2)
    if get_confirmation "Takip edilmeyen tüm dosyalar silinecek. Emin misiniz?"; then
      git clean -fd && print_success "Takip edilmeyen dosyalar temizlendi."
    fi
    ;;
  3)
    echo -e "\n${COLORS[BOLD]}Git Ignore İşlemleri:${COLORS[NC]}"
    echo "1) .gitignore dosyasını görüntüle"
    echo "2) .gitignore'a yeni pattern ekle"
    echo "0) Geri dön"

    read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz (0-2):${COLORS[NC]} ")" ignore_choice

    case "$ignore_choice" in
    1)
      # Git repo kök dizinini bul
      local git_root
      git_root=$(git rev-parse --show-toplevel)
      if [[ -f "$git_root/.gitignore" ]]; then
        cat "$git_root/.gitignore"
      else
        print_warning ".gitignore dosyası bulunamadı."
        if get_confirmation "Yeni .gitignore dosyası oluşturulsun mu?"; then
          touch "$git_root/.gitignore"
          print_success ".gitignore dosyası oluşturuldu."
        fi
      fi
      ;;
    2)
      echo -e "\n${COLORS[BOLD]}Eklenecek pattern'i girin:${COLORS[NC]}"
      read -r ignore_pattern
      if [[ -n "$ignore_pattern" ]]; then
        local git_root
        git_root=$(git rev-parse --show-toplevel)
        echo "$ignore_pattern" >>"$git_root/.gitignore"
        print_success "Pattern .gitignore dosyasına eklendi."
      else
        print_error "Pattern boş olamaz."
      fi
      ;;
    0) return ;;
    *) print_error "Geçersiz seçim." ;;
    esac
    ;;
  0) return ;;
  *) print_error "Geçersiz seçim." ;;
  esac
}

# Git config işlemleri
manage_config() {
  echo -e "\n${COLORS[BOLD]}⚙️  Git Config İşlemleri${COLORS[NC]}"
  echo "1) Mevcut config'i görüntüle"
  echo "2) Kullanıcı bilgilerini güncelle"
  echo "3) Alias ekle"
  echo "4) Alias sil"
  echo "0) Geri dön"

  read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz (0-4):${COLORS[NC]} ")" config_choice

  case "$config_choice" in
  1)
    echo -e "\n${COLORS[BOLD]}Git Config:${COLORS[NC]}"
    git config --list
    ;;
  2)
    echo -e "\n${COLORS[BOLD]}Kullanıcı adını girin:${COLORS[NC]}"
    read -r git_username
    echo -e "${COLORS[BOLD]}E-posta adresini girin:${COLORS[NC]}"
    read -r git_email
    if [[ -n "$git_username" ]] && [[ -n "$git_email" ]]; then
      git config --global user.name "$git_username"
      git config --global user.email "$git_email"
      print_success "Kullanıcı bilgileri güncellendi."
    else
      print_error "Kullanıcı adı veya e-posta boş olamaz."
    fi
    ;;
  3)
    echo -e "\n${COLORS[BOLD]}Alias adını girin:${COLORS[NC]}"
    read -r alias_name
    echo -e "${COLORS[BOLD]}Komut dizisini girin:${COLORS[NC]}"
    read -r alias_command
    if [[ -n "$alias_name" ]] && [[ -n "$alias_command" ]]; then
      git config --global alias."$alias_name" "$alias_command"
      print_success "Alias başarıyla eklendi."
    else
      print_error "Alias adı veya komut boş olamaz."
    fi
    ;;
  4)
    echo -e "\n${COLORS[BOLD]}Silinecek alias adını girin:${COLORS[NC]}"
    read -r alias_to_remove
    if [[ -n "$alias_to_remove" ]]; then
      git config --global --unset alias."$alias_to_remove"
      print_success "Alias başarıyla silindi."
    else
      print_error "Alias adı boş olamaz."
    fi
    ;;
  0) return ;;
  *) print_error "Geçersiz seçim." ;;
  esac
}

# Remote repo işlemleri
manage_remotes() {
  echo -e "\n${COLORS[BOLD]}🌐 Remote Repo İşlemleri${COLORS[NC]}"
  echo "1) Remote repo listesi"
  echo "2) Remote repo ekle"
  echo "3) Remote repo sil"
  echo "4) Remote repo URL güncelle"
  echo "5) Remote branch'leri temizle"
  echo "0) Geri dön"

  read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz (0-5):${COLORS[NC]} ")" remote_choice

  case "$remote_choice" in
  1)
    echo -e "\n${COLORS[BOLD]}Remote Repo Listesi:${COLORS[NC]}"
    git remote -v
    ;;
  2)
    echo -e "\n${COLORS[BOLD]}Remote repo adını girin:${COLORS[NC]}"
    read -r remote_name
    echo -e "${COLORS[BOLD]}Remote repo URL'sini girin:${COLORS[NC]}"
    read -r remote_url
    if [[ -n "$remote_name" ]] && [[ -n "$remote_url" ]]; then
      git remote add "$remote_name" "$remote_url" && print_success "Remote repo başarıyla eklendi."
    else
      print_error "Remote repo adı veya URL boş olamaz."
    fi
    ;;
  3)
    echo -e "\n${COLORS[BOLD]}Silinecek remote repo adını girin:${COLORS[NC]}"
    read -r remote_to_remove
    if [[ -n "$remote_to_remove" ]]; then
      if get_confirmation "Bu remote repo silinecek. Emin misiniz?"; then
        git remote remove "$remote_to_remove" && print_success "Remote repo başarıyla silindi."
      fi
    else
      print_error "Remote repo adı boş olamaz."
    fi
    ;;
  4)
    echo -e "\n${COLORS[BOLD]}Güncellenecek remote repo adını girin:${COLORS[NC]}"
    read -r remote_to_update
    echo -e "${COLORS[BOLD]}Yeni URL'yi girin:${COLORS[NC]}"
    read -r new_url
    if [[ -n "$remote_to_update" ]] && [[ -n "$new_url" ]]; then
      git remote set-url "$remote_to_update" "$new_url" && print_success "Remote repo URL'si başarıyla güncellendi."
    else
      print_error "Remote repo adı veya URL boş olamaz."
    fi
    ;;
  5)
    if get_confirmation "Silinmiş remote branch'ler temizlenecek. Emin misiniz?"; then
      git remote prune origin && print_success "Remote branch'ler temizlendi."
    fi
    ;;
  0) return ;;
  *) print_error "Geçersiz seçim." ;;
  esac
}

# Stash işlemleri
manage_stash() {
  echo -e "\n${COLORS[BOLD]}📦 Stash İşlemleri${COLORS[NC]}"
  echo "1) Değişiklikleri stash'e kaydet"
  echo "2) Stash listesini görüntüle"
  echo "3) Stash'ten değişiklikleri geri yükle"
  echo "4) Stash sil"
  echo "0) Geri dön"

  read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz (0-4):${COLORS[NC]} ")" stash_choice

  case "$stash_choice" in
  1)
    echo -e "\n${COLORS[BOLD]}Stash mesajını girin (opsiyonel):${COLORS[NC]}"
    read -r stash_msg
    if [[ -n "$stash_msg" ]]; then
      git stash push -m "$stash_msg" && print_success "Değişiklikler stash'e kaydedildi."
    else
      git stash push && print_success "Değişiklikler stash'e kaydedildi."
    fi
    ;;
  2)
    echo -e "\n${COLORS[BOLD]}Stash Listesi:${COLORS[NC]}"
    git stash list
    ;;
  3)
    echo -e "\n${COLORS[BOLD]}Stash Listesi:${COLORS[NC]}"
    git stash list
    echo -e "\n${COLORS[BOLD]}Geri yüklenecek stash index'ini girin:${COLORS[NC]}"
    read -r stash_index
    if [[ "$stash_index" =~ ^[0-9]+$ ]]; then
      git stash apply "stash@{$stash_index}" && print_success "Stash başarıyla uygulandı."
    else
      print_error "Geçersiz stash index."
    fi
    ;;
  4)
    echo -e "\n${COLORS[BOLD]}Stash Listesi:${COLORS[NC]}"
    git stash list
    echo -e "\n${COLORS[BOLD]}Silinecek stash index'ini girin:${COLORS[NC]}"
    read -r stash_index
    if [[ "$stash_index" =~ ^[0-9]+$ ]]; then
      if get_confirmation "Bu stash silinecek. Emin misiniz?"; then
        git stash drop "stash@{$stash_index}" && print_success "Stash başarıyla silindi."
      fi
    else
      print_error "Geçersiz stash index."
    fi
    ;;
  0) return ;;
  *) print_error "Geçersiz seçim." ;;
  esac
}

# Tag işlemleri
manage_tags() {
  echo -e "\n${COLORS[BOLD]}🏷️  Tag İşlemleri${COLORS[NC]}"
  echo "1) Tag listesi"
  echo "2) Yeni tag oluştur"
  echo "3) Tag sil (local)"
  echo "4) Tag sil (remote)"
  echo "5) Tag'leri push et"
  echo "0) Geri dön"

  read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz (0-5):${COLORS[NC]} ")" tag_choice

  case "$tag_choice" in
  1)
    echo -e "\n${COLORS[BOLD]}Tag Listesi:${COLORS[NC]}"
    git tag -n
    ;;
  2)
    echo -e "\n${COLORS[BOLD]}Yeni tag adını girin:${COLORS[NC]}"
    read -r tag_name
    echo -e "${COLORS[BOLD]}Tag açıklamasını girin:${COLORS[NC]}"
    read -r tag_message
    if [[ -n "$tag_name" ]]; then
      git tag -a "$tag_name" -m "$tag_message" && print_success "Tag başarıyla oluşturuldu."
    else
      print_error "Tag adı boş olamaz."
    fi
    ;;
  3)
    echo -e "\n${COLORS[BOLD]}Silinecek tag adını girin:${COLORS[NC]}"
    read -r tag_to_delete
    if [[ -n "$tag_to_delete" ]]; then
      if get_confirmation "Bu tag silinecek. Emin misiniz?"; then
        git tag -d "$tag_to_delete" && print_success "Tag başarıyla silindi."
      fi
    else
      print_error "Tag adı boş olamaz."
    fi
    ;;
  4)
    echo -e "\n${COLORS[BOLD]}Silinecek remote tag adını girin:${COLORS[NC]}"
    read -r remote_tag
    if [[ -n "$remote_tag" ]]; then
      if get_confirmation "Bu remote tag silinecek. Emin misiniz?"; then
        git push origin :refs/tags/"$remote_tag" && print_success "Remote tag başarıyla silindi."
      fi
    else
      print_error "Tag adı boş olamaz."
    fi
    ;;
  5)
    if get_confirmation "Tüm tag'ler push edilecek. Emin misiniz?"; then
      git push origin --tags && print_success "Tag'ler başarıyla push edildi."
    fi
    ;;
  0) return ;;
  *) print_error "Geçersiz seçim." ;;
  esac
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
        git add "${files[$((num - 1))]}"
        selected+=("${files[$((num - 1))]}")
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

# Commit ve push işlemi fonksiyonu
perform_commit_push() {
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
        git add "${files[$((num - 1))]}"
        selected+=("${files[$((num - 1))]}")
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

# Git log görüntüleme
view_logs() {
  echo -e "\n${COLORS[BOLD]}📋 Log Görüntüleme${COLORS[NC]}"
  echo "1) Detaylı log görüntüleme"
  echo "2) Branch bazlı log görüntüleme"
  echo "3) Dosya/klasör bazlı log görüntüleme"
  echo "4) Grafik görünümü"
  echo "0) Geri dön"

  read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz (0-4):${COLORS[NC]} ")" log_choice

  case "$log_choice" in
  1)
    git log --pretty=format:"%C(yellow)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) %C(cyan)[%an]%Creset" --abbrev-commit
    ;;
  2)
    echo -e "\n${COLORS[BOLD]}Branch adını girin (boş bırakırsanız tüm branchler gösterilecek):${COLORS[NC]}"
    read -r branch_name
    if [[ -n "$branch_name" ]]; then
      git log "$branch_name" --pretty=format:"%C(yellow)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) %C(cyan)[%an]%Creset" --abbrev-commit
    else
      git log --all --pretty=format:"%C(yellow)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) %C(cyan)[%an]%Creset" --abbrev-commit
    fi
    ;;
  3)
    echo -e "\n${COLORS[BOLD]}Dosya/klasör yolunu girin:${COLORS[NC]}"
    read -r file_path
    if [[ -e "$file_path" ]]; then
      git log --follow --pretty=format:"%C(yellow)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) %C(cyan)[%an]%Creset" --abbrev-commit -- "$file_path"
    else
      print_error "Dosya/klasör bulunamadı."
    fi
    ;;
  4)
    git log --graph --pretty=format:"%C(yellow)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) %C(cyan)[%an]%Creset" --abbrev-commit
    ;;
  0) return ;;
  *) print_error "Geçersiz seçim." ;;
  esac
}

# Ana menü
show_menu() {
  echo -e "\n${COLORS[BOLD]}🔧 Git İşlemleri${COLORS[NC]}"
  echo "1) Commit ve Push"
  echo "2) Stash İşlemleri"
  echo "3) Log Görüntüleme"
  echo "4) Branch İşlemleri"
  echo "5) Tag İşlemleri"
  echo "6) Remote Repo İşlemleri"
  echo "7) Git Config İşlemleri"
  echo "8) Git Clean İşlemleri"
  echo "9) Çıkış"

  read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz (1-9):${COLORS[NC]} ")" menu_choice

  case "$menu_choice" in
  1) perform_commit_push ;;
  2) manage_stash ;;
  3) view_logs ;;
  4) manage_branches ;;
  5) manage_tags ;;
  6) manage_remotes ;;
  7) manage_config ;;
  8) manage_clean ;;
  9) cleanup_and_exit 0 "${COLORS[GREEN]}👋 Güle güle!${COLORS[NC]}" ;;
  *) print_error "Geçersiz seçim." ;;
  esac
}

# Ana fonksiyon
main() {
  check_git_setup
  while true; do
    show_menu
  done
}

# Scripti çalıştır
main "$@"
