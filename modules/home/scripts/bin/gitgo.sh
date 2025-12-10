#!/usr/bin/env bash
# gitgo.sh - Etkileşimli Git araç kutusu
# Branch yönetimi, stash/rebase/merge, diff/clean ve kurtarma akışlarını
# menü tabanlı arayüzle hızlandıran kapsamlı yardımcı.

#   Version: 1.1.0
#   Date: 2025-04-18
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc

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

# Trap tanımla - CTRL+C ve diğer sinyaller için temiz çıkış
trap 'cleanup_and_exit 1 "${COLORS[RED]}❌ İşlem kullanıcı tarafından iptal edildi.${COLORS[NC]}"' INT TERM HUP

# Git kontrollerini yapan fonksiyon
check_git_setup() {
	[[ ! -d .git ]] && cleanup_and_exit 1 "${COLORS[RED]}❌ Bu dizin bir git deposu değil.${COLORS[NC]}"
	command -v git &>/dev/null || cleanup_and_exit 1 "${COLORS[RED]}❌ Git kurulu değil.${COLORS[NC]}"
	git remote get-url origin &>/dev/null || print_warning "Uzak depo ayarlanmamış. Bazı işlevler çalışmayabilir."

	# Git versiyonunu kontrol et
	local git_version
	git_version=$(git --version | sed -E 's/git version ([0-9]+\.[0-9]+).*/\1/')
	if (($(echo "$git_version < 2.23" | bc -l))); then
		print_warning "Git versiyonunuz ($git_version) eski olabilir. Bazı özellikler çalışmayabilir."
	fi
}

# Branch yönetimi
manage_branches() {
	echo -e "\n${COLORS[BOLD]}🌿 Branch İşlemleri${COLORS[NC]}"
	echo "1) Branch listesi (local)"
	echo "2) Branch listesi (remote)"
	echo "3) Branch oluştur"
	echo "4) Branch değiştir"
	echo "5) Branch sil (local)"
	echo "6) Branch sil (remote)"
	echo "7) Branch'leri merge et"
	echo "8) Branch yeniden adlandır"
	echo "0) Geri dön"

	read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz (0-8):${COLORS[NC]} ")" branch_choice

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
			if git --no-pager show-ref --verify --quiet "refs/heads/$new_branch"; then
				print_error "Bu isimde bir branch zaten var."
			else
				git checkout -b "$new_branch" && print_success "Branch '$new_branch' oluşturuldu ve geçiş yapıldı."
			fi
		else
			print_error "Branch adı boş olamaz."
		fi
		;;
	4)
		echo -e "\n${COLORS[BOLD]}Mevcut Branchler:${COLORS[NC]}"
		git branch
		echo -e "\n${COLORS[BOLD]}Geçiş yapılacak branch adını girin:${COLORS[NC]}"
		read -r switch_branch
		if [[ -n "$switch_branch" ]]; then
			if git --no-pager show-ref --verify --quiet "refs/heads/$switch_branch"; then
				git switch "$switch_branch" && print_success "Branch '$switch_branch'e geçiş yapıldı."
			else
				print_error "Branch bulunamadı."
			fi
		else
			print_error "Branch adı boş olamaz."
		fi
		;;
	5)
		echo -e "\n${COLORS[BOLD]}Silinecek local branch adını girin:${COLORS[NC]}"
		read -r branch_to_delete
		if [[ -n "$branch_to_delete" ]] && git --no-pager show-ref --verify --quiet "refs/heads/$branch_to_delete"; then
			local current_branch
			current_branch=$(git branch --show-current)
			if [[ "$current_branch" == "$branch_to_delete" ]]; then
				print_error "Aktif branch silinemez. Önce başka bir branch'e geçiş yapın."
				return
			fi

			if get_confirmation "Bu branch silinecek. Emin misiniz?"; then
				if ! git branch -d "$branch_to_delete" 2>/dev/null; then
					print_warning "Bu branch merge edilmemiş değişiklikler içeriyor."
					if get_confirmation "Yine de branch silinsin mi? (force)"; then
						git branch -D "$branch_to_delete" && print_success "Branch zorla silindi."
					fi
				else
					print_success "Branch başarıyla silindi."
				fi
			fi
		else
			print_error "Branch bulunamadı."
		fi
		;;
	6)
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
	7)
		echo -e "\n${COLORS[BOLD]}Merge edilecek branch adını girin:${COLORS[NC]}"
		read -r branch_to_merge
		if [[ -n "$branch_to_merge" ]] && git --no-pager show-ref --verify --quiet "refs/heads/$branch_to_merge"; then
			local current_branch
			current_branch=$(git branch --show-current)
			echo -e "Merge işlemi: $branch_to_merge -> $current_branch"

			if get_confirmation "Bu branch merge edilecek. Emin misiniz?"; then
				if ! git merge "$branch_to_merge"; then
					print_error "Merge işlemi çakışmalarla karşılaştı."
					if get_confirmation "Merge işlemi iptal edilsin mi?"; then
						git merge --abort && print_warning "Merge işlemi iptal edildi."
					else
						print_info "Çakışmaları çözün ve sonra commit edin."
					fi
				else
					print_success "Branch başarıyla merge edildi."
				fi
			fi
		else
			print_error "Branch bulunamadı."
		fi
		;;
	8)
		echo -e "\n${COLORS[BOLD]}Yeniden adlandırılacak branch adını girin:${COLORS[NC]}"
		read -r old_name
		if [[ -n "$old_name" ]] && git --no-pager show-ref --verify --quiet "refs/heads/$old_name"; then
			echo -e "${COLORS[BOLD]}Yeni branch adını girin:${COLORS[NC]}"
			read -r new_name
			if [[ -n "$new_name" ]]; then
				git branch -m "$old_name" "$new_name" && print_success "Branch '$old_name' -> '$new_name' olarak yeniden adlandırıldı."
			else
				print_error "Yeni branch adı boş olamaz."
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
manage_clean() {
	echo -e "\n${COLORS[BOLD]}🧹 Git Clean İşlemleri${COLORS[NC]}"
	echo "1) Takip edilmeyen dosyaları listele"
	echo "2) Takip edilmeyen dosyaları temizle"
	echo "3) Takip edilmeyen dizinleri temizle"
	echo "4) Git ignore yönetimi"
	echo "0) Geri dön"

	read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz (0-4):${COLORS[NC]} ")" clean_choice

	case "$clean_choice" in
	1)
		echo -e "\n${COLORS[BOLD]}Takip Edilmeyen Dosyalar:${COLORS[NC]}"
		git clean -n
		;;
	2)
		if get_confirmation "Takip edilmeyen tüm dosyalar silinecek. Emin misiniz?"; then
			git clean -f && print_success "Takip edilmeyen dosyalar temizlendi."
		fi
		;;
	3)
		if get_confirmation "Takip edilmeyen tüm dizinler silinecek. Emin misiniz?"; then
			git clean -fd && print_success "Takip edilmeyen dizinler temizlendi."
		fi
		;;
	4)
		echo -e "\n${COLORS[BOLD]}Git Ignore İşlemleri:${COLORS[NC]}"
		echo "1) .gitignore dosyasını görüntüle"
		echo "2) .gitignore'a yeni pattern ekle"
		echo "3) Git ignore durumunu kontrol et"
		echo "0) Geri dön"

		read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz (0-3):${COLORS[NC]} ")" ignore_choice

		case "$ignore_choice" in
		1)
			# Git repo kök dizinini bul
			local git_root
			git_root=$(git rev-parse --show-toplevel)
			if [[ -f "$git_root/.gitignore" ]]; then
				echo -e "\n${COLORS[BOLD]}.gitignore İçeriği:${COLORS[NC]}"
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
		3)
			echo -e "\n${COLORS[BOLD]}Kontrol edilecek dosya adını girin:${COLORS[NC]}"
			read -r check_file
			if [[ -n "$check_file" ]]; then
				if git check-ignore -v "$check_file"; then
					print_info "Bu dosya ignore edilmiş."
				else
					print_info "Bu dosya ignore edilmemiş."
				fi
			else
				print_error "Dosya adı boş olamaz."
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
	echo "5) Config değeri ayarla"
	echo "0) Geri dön"

	read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz (0-5):${COLORS[NC]} ")" config_choice

	case "$config_choice" in
	1)
		echo -e "\n${COLORS[BOLD]}Git Config:${COLORS[NC]}"
		echo -e "\n${COLORS[BOLD]}Global Config:${COLORS[NC]}"
		git config --global --list
		echo -e "\n${COLORS[BOLD]}Yerel Config:${COLORS[NC]}"
		git config --local --list
		;;
	2)
		echo -e "\n${COLORS[BOLD]}Kullanıcı adını girin:${COLORS[NC]}"
		read -r git_username
		echo -e "${COLORS[BOLD]}E-posta adresini girin:${COLORS[NC]}"
		read -r git_email
		if [[ -n "$git_username" ]] && [[ -n "$git_email" ]]; then
			echo -e "\n${COLORS[BOLD]}Kapsam seçin:${COLORS[NC]}"
			echo "1) Global (tüm repolar için)"
			echo "2) Yerel (sadece bu repo için)"
			read -r scope_choice

			local scope="--global"
			[[ "$scope_choice" == "2" ]] && scope="--local"

			git config "$scope" user.name "$git_username"
			git config "$scope" user.email "$git_email"
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
			echo -e "\n${COLORS[BOLD]}Kapsam seçin:${COLORS[NC]}"
			echo "1) Global (tüm repolar için)"
			echo "2) Yerel (sadece bu repo için)"
			read -r scope_choice

			local scope="--global"
			[[ "$scope_choice" == "2" ]] && scope="--local"

			git config "$scope" alias."$alias_name" "$alias_command"
			print_success "Alias başarıyla eklendi."
		else
			print_error "Alias adı veya komut boş olamaz."
		fi
		;;
	4)
		echo -e "\n${COLORS[BOLD]}Silinecek alias adını girin:${COLORS[NC]}"
		read -r alias_to_remove
		if [[ -n "$alias_to_remove" ]]; then
			echo -e "\n${COLORS[BOLD]}Kapsam seçin:${COLORS[NC]}"
			echo "1) Global (tüm repolar için)"
			echo "2) Yerel (sadece bu repo için)"
			read -r scope_choice

			local scope="--global"
			[[ "$scope_choice" == "2" ]] && scope="--local"

			git config "$scope" --unset alias."$alias_to_remove"
			print_success "Alias başarıyla silindi."
		else
			print_error "Alias adı boş olamaz."
		fi
		;;
	5)
		echo -e "\n${COLORS[BOLD]}Config anahtarını girin:${COLORS[NC]}"
		read -r config_key
		echo -e "${COLORS[BOLD]}Config değerini girin:${COLORS[NC]}"
		read -r config_value

		if [[ -n "$config_key" ]]; then
			echo -e "\n${COLORS[BOLD]}Kapsam seçin:${COLORS[NC]}"
			echo "1) Global (tüm repolar için)"
			echo "2) Yerel (sadece bu repo için)"
			read -r scope_choice

			local scope="--global"
			[[ "$scope_choice" == "2" ]] && scope="--local"

			git config "$scope" "$config_key" "$config_value"
			print_success "Config değeri ayarlandı."
		else
			print_error "Config anahtarı boş olamaz."
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
	echo "6) Remote repo'dan fetch"
	echo "0) Geri dön"

	read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz (0-6):${COLORS[NC]} ")" remote_choice

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
	6)
		echo -e "\n${COLORS[BOLD]}Fetch yapılacak remote adını girin (boş bırakırsanız tüm remoteler fetch edilecek):${COLORS[NC]}"
		read -r remote_to_fetch

		if [[ -n "$remote_to_fetch" ]]; then
			git fetch "$remote_to_fetch" && print_success "$remote_to_fetch fetch edildi."
		else
			git fetch --all && print_success "Tüm remoteler fetch edildi."
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
	echo "5) Belirli dosyaları stash'e kaydet"
	echo "0) Geri dön"

	read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz (0-5):${COLORS[NC]} ")" stash_choice

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
		echo ""
		if get_confirmation "Stash detaylarını görmek ister misiniz?"; then
			echo -e "\n${COLORS[BOLD]}Görmek istediğiniz stash index'ini girin:${COLORS[NC]}"
			read -r stash_index
			if [[ "$stash_index" =~ ^[0-9]+$ ]]; then
				git stash show -p "stash@{$stash_index}"
			else
				print_error "Geçersiz stash index."
			fi
		fi
		;;
	3)
		echo -e "\n${COLORS[BOLD]}Stash Listesi:${COLORS[NC]}"
		git stash list
		echo -e "\n${COLORS[BOLD]}Geri yüklenecek stash index'ini girin:${COLORS[NC]}"
		read -r stash_index
		if [[ "$stash_index" =~ ^[0-9]+$ ]]; then
			echo -e "\n${COLORS[BOLD]}Uygulama yöntemi seçin:${COLORS[NC]}"
			echo "1) Apply (stash korunur)"
			echo "2) Pop (stash silinir)"
			read -r apply_method

			if [[ "$apply_method" == "1" ]]; then
				git stash apply "stash@{$stash_index}" && print_success "Stash başarıyla uygulandı ve korundu."
			elif [[ "$apply_method" == "2" ]]; then
				git stash pop "stash@{$stash_index}" && print_success "Stash başarıyla uygulandı ve silindi."
			else
				print_error "Geçersiz seçim."
			fi
		else
			print_error "Geçersiz stash index."
		fi
		;;
	4)
		echo -e "\n${COLORS[BOLD]}Stash Listesi:${COLORS[NC]}"
		git stash list
		echo -e "\n${COLORS[BOLD]}Silinecek stash index'ini girin (tümünü silmek için 'all' yazın):${COLORS[NC]}"
		read -r stash_index

		if [[ "$stash_index" == "all" ]]; then
			if get_confirmation "TÜM stash'ler silinecek. Emin misiniz?"; then
				git stash clear && print_success "Tüm stash'ler başarıyla silindi."
			fi
		elif [[ "$stash_index" =~ ^[0-9]+$ ]]; then
			if get_confirmation "Bu stash silinecek. Emin misiniz?"; then
				git stash drop "stash@{$stash_index}" && print_success "Stash başarıyla silindi."
			fi
		else
			print_error "Geçersiz stash index."
		fi
		;;
	5)
		echo -e "\n${COLORS[BOLD]}Stash'e kaydedilecek dosya/dizin adını girin:${COLORS[NC]}"
		read -r stash_path

		if [[ -n "$stash_path" ]]; then
			echo -e "\n${COLORS[BOLD]}Stash mesajını girin (opsiyonel):${COLORS[NC]}"
			read -r stash_msg

			if [[ -n "$stash_msg" ]]; then
				git stash push -m "$stash_msg" -- "$stash_path" && print_success "Belirtilen dosya/dizin stash'e kaydedildi."
			else
				git stash push -- "$stash_path" && print_success "Belirtilen dosya/dizin stash'e kaydedildi."
			fi
		else
			print_error "Dosya/dizin adı boş olamaz."
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
	echo "6) Tag detayını görüntüle"
	echo "0) Geri dön"

	read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz (0-6):${COLORS[NC]} ")" tag_choice

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
			echo -e "\n${COLORS[BOLD]}Tag türü seçin:${COLORS[NC]}"
			echo "1) Annotated tag (açıklamalı, önerilir)"
			echo "2) Lightweight tag (basit)"
			read -r tag_type

			if [[ "$tag_type" == "1" ]]; then
				git tag -a "$tag_name" -m "$tag_message" && print_success "Tag başarıyla oluşturuldu."
			elif [[ "$tag_type" == "2" ]]; then
				git tag "$tag_name" && print_success "Lightweight tag başarıyla oluşturuldu."
			else
				print_error "Geçersiz seçim."
			fi
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
		echo -e "\n${COLORS[BOLD]}Push edilecek tag seçeneğini belirtin:${COLORS[NC]}"
		echo "1) Tüm tag'leri push et"
		echo "2) Belirli bir tag'i push et"
		read -r tag_push_choice

		if [[ "$tag_push_choice" == "1" ]]; then
			if get_confirmation "Tüm tag'ler push edilecek. Emin misiniz?"; then
				git push origin --tags && print_success "Tag'ler başarıyla push edildi."
			fi
		elif [[ "$tag_push_choice" == "2" ]]; then
			echo -e "\n${COLORS[BOLD]}Push edilecek tag adını girin:${COLORS[NC]}"
			read -r tag_to_push
			if [[ -n "$tag_to_push" ]]; then
				git push origin refs/tags/"$tag_to_push" && print_success "Tag başarıyla push edildi."
			else
				print_error "Tag adı boş olamaz."
			fi
		else
			print_error "Geçersiz seçim."
		fi
		;;
	6)
		echo -e "\n${COLORS[BOLD]}Detayını görmek istediğiniz tag adını girin:${COLORS[NC]}"
		read -r tag_to_show
		if [[ -n "$tag_to_show" ]]; then
			git show "$tag_to_show"
		else
			print_error "Tag adı boş olamaz."
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

# Gelişmiş dosya değişikliği görüntüleme
view_changes() {
	echo -e "\n${COLORS[BOLD]}🔍 Değişiklik Görüntüleme${COLORS[NC]}"
	echo "1) Çalışma dizini değişiklikleri (git diff)"
	echo "2) Staged değişiklikler (git diff --staged)"
	echo "3) Tüm değişiklikler (staged ve unstaged)"
	echo "4) Dosya bazlı değişiklikler"
	echo "5) İki commit arasındaki farklar"
	echo "0) Geri dön"

	read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz (0-5):${COLORS[NC]} ")" diff_choice

	case "$diff_choice" in
	1)
		git diff
		;;
	2)
		git diff --staged
		;;
	3)
		git diff HEAD
		;;
	4)
		echo -e "\n${COLORS[BOLD]}Değişiklikleri görmek istediğiniz dosyanın adını girin:${COLORS[NC]}"
		read -r file_to_diff
		if [[ -n "$file_to_diff" ]]; then
			if git ls-files --error-unmatch "$file_to_diff" &>/dev/null; then
				git diff -- "$file_to_diff"
			else
				print_error "Dosya bulunamadı veya git tarafından takip edilmiyor."
			fi
		else
			print_error "Dosya adı boş olamaz."
		fi
		;;
	5)
		echo -e "\n${COLORS[BOLD]}İlk commit (eski) ID veya ref girin:${COLORS[NC]}"
		read -r old_commit
		echo -e "${COLORS[BOLD]}İkinci commit (yeni) ID veya ref girin (boş bırakırsanız HEAD kullanılacak):${COLORS[NC]}"
		read -r new_commit

		if [[ -n "$old_commit" ]]; then
			if [[ -n "$new_commit" ]]; then
				git diff "$old_commit".."$new_commit"
			else
				git diff "$old_commit"..HEAD
			fi
		else
			print_error "İlk commit ID boş olamaz."
		fi
		;;
	0) return ;;
	*) print_error "Geçersiz seçim." ;;
	esac
}

# Git log görüntüleme
view_logs() {
	echo -e "\n${COLORS[BOLD]}📋 Log Görüntüleme${COLORS[NC]}"
	echo "1) Detaylı log görüntüleme"
	echo "2) Branch bazlı log görüntüleme"
	echo "3) Dosya/klasör bazlı log görüntüleme"
	echo "4) Grafik görünümü"
	echo "5) Arama bazlı log görüntüleme"
	echo "6) Son n commit'i görüntüle"
	echo "7) Tarih aralığına göre log görüntüleme"
	echo "0) Geri dön"

	read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz (0-7):${COLORS[NC]} ")" log_choice

	# Ortak pretty format
	local pretty_format="%C(yellow)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) %C(cyan)[%an]%Creset"

	case "$log_choice" in
	1)
		git log --pretty=format:"$pretty_format" --abbrev-commit
		;;
	2)
		echo -e "\n${COLORS[BOLD]}Branch adını girin (boş bırakırsanız tüm branchler gösterilecek):${COLORS[NC]}"
		read -r branch_name
		if [[ -n "$branch_name" ]]; then
			git log "$branch_name" --pretty=format:"$pretty_format" --abbrev-commit
		else
			git log --all --pretty=format:"$pretty_format" --abbrev-commit
		fi
		;;
	3)
		echo -e "\n${COLORS[BOLD]}Dosya/klasör yolunu girin:${COLORS[NC]}"
		read -r file_path
		if [[ -e "$file_path" ]]; then
			git log --follow --pretty=format:"$pretty_format" --abbrev-commit -- "$file_path"
		else
			print_error "Dosya/klasör bulunamadı."
		fi
		;;
	4)
		echo -e "\n${COLORS[BOLD]}Gösterilecek commit sayısını girin (boş bırakırsanız tümü gösterilecek):${COLORS[NC]}"
		read -r commit_count

		if [[ -n "$commit_count" ]] && [[ "$commit_count" =~ ^[0-9]+$ ]]; then
			git log --graph --pretty=format:"$pretty_format" --abbrev-commit -n "$commit_count"
		else
			git log --graph --pretty=format:"$pretty_format" --abbrev-commit
		fi
		;;
	5)
		echo -e "\n${COLORS[BOLD]}Aranacak metni girin:${COLORS[NC]}"
		read -r search_text

		if [[ -n "$search_text" ]]; then
			echo -e "\n${COLORS[BOLD]}Arama türünü seçin:${COLORS[NC]}"
			echo "1) Commit mesajlarında ara"
			echo "2) Commit içeriklerinde ara (yavaş olabilir)"
			echo "3) Commit yazarlarında ara"
			read -r search_type

			case "$search_type" in
			1)
				git log --pretty=format:"$pretty_format" --abbrev-commit --grep="$search_text"
				;;
			2)
				git log --pretty=format:"$pretty_format" --abbrev-commit -p -S"$search_text"
				;;
			3)
				git log --pretty=format:"$pretty_format" --abbrev-commit --author="$search_text"
				;;
			*)
				print_error "Geçersiz seçim."
				;;
			esac
		else
			print_error "Arama metni boş olamaz."
		fi
		;;
	6)
		echo -e "\n${COLORS[BOLD]}Gösterilecek commit sayısını girin:${COLORS[NC]}"
		read -r n_commits

		if [[ -n "$n_commits" ]] && [[ "$n_commits" =~ ^[0-9]+$ ]]; then
			git log --pretty=format:"$pretty_format" --abbrev-commit -n "$n_commits"
		else
			print_error "Geçerli bir sayı girmelisiniz."
		fi
		;;
	7)
		echo -e "\n${COLORS[BOLD]}Başlangıç tarihini girin (YYYY-MM-DD):${COLORS[NC]}"
		read -r start_date
		echo -e "${COLORS[BOLD]}Bitiş tarihini girin (YYYY-MM-DD):${COLORS[NC]}"
		read -r end_date

		if [[ -n "$start_date" ]] && [[ -n "$end_date" ]]; then
			git log --pretty=format:"$pretty_format" --abbrev-commit --after="$start_date" --before="$end_date"
		else
			print_error "Tarih alanları boş olamaz."
		fi
		;;
	0) return ;;
	*) print_error "Geçersiz seçim." ;;
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

	# Commit türü sorusu
	echo -e "\n${COLORS[BOLD]}Commit türünü seçin:${COLORS[NC]}"
	echo "1) Normal commit"
	echo "2) Signed commit (GPG ile imzalı)"
	echo "3) Amend commit (son commit'i değiştir)"
	read -r commit_type

	# Son kontrol ve commit
	get_confirmation "📝 Commit yapılsın mı?" || {
		git restore --staged .
		cleanup_and_exit 0 "${COLORS[RED]}❌ İşlem iptal edildi.${COLORS[NC]}"
	}

	print_info "💾 Commit yapılıyor..."

	case "$commit_type" in
	1)
		git commit -m "$commit_msg"
		;;
	2)
		git commit -S -m "$commit_msg"
		;;
	3)
		if get_confirmation "Son commit değiştirilecek. Bu işlem geçmişi değiştirecek. Emin misiniz?"; then
			git commit --amend -m "$commit_msg"
		else
			git commit -m "$commit_msg"
		fi
		;;
	*)
		# Varsayılan olarak normal commit yap
		git commit -m "$commit_msg"
		;;
	esac

	# Push işlemi
	if get_confirmation "☁️  Push yapılsın mı?"; then
		# Push türü sorusu
		echo -e "\n${COLORS[BOLD]}Push türünü seçin:${COLORS[NC]}"
		echo "1) Normal push"
		echo "2) Force push (geçmişi değiştirecek, dikkatli kullanın!)"
		read -r push_type

		local current_branch
		current_branch=$(git rev-parse --abbrev-ref HEAD)

		case "$push_type" in
		1)
			if git push origin "$current_branch"; then
				print_success "✨ Tamamlandı! Değişiklikler başarıyla gönderildi."
			else
				cleanup_and_exit 1 "${COLORS[RED]}❌ Push başarısız oldu.${COLORS[NC]}"
			fi
			;;
		2)
			if get_confirmation "❗ Force push, uzak repodaki geçmişi değiştirecek ve takım üyelerinde sorunlara yol açabilir. Emin misiniz?"; then
				if git push --force origin "$current_branch"; then
					print_success "✨ Tamamlandı! Değişiklikler zorla gönderildi."
				else
					cleanup_and_exit 1 "${COLORS[RED]}❌ Force push başarısız oldu.${COLORS[NC]}"
				fi
			else
				if get_confirmation "Normal push denemek ister misiniz?"; then
					if git push origin "$current_branch"; then
						print_success "✨ Tamamlandı! Değişiklikler başarıyla gönderildi."
					else
						cleanup_and_exit 1 "${COLORS[RED]}❌ Push başarısız oldu.${COLORS[NC]}"
					fi
				else
					print_warning "Push işlemi iptal edildi."
				fi
			fi
			;;
		*)
			if git push origin "$current_branch"; then
				print_success "✨ Tamamlandı! Değişiklikler başarıyla gönderildi."
			else
				cleanup_and_exit 1 "${COLORS[RED]}❌ Push başarısız oldu.${COLORS[NC]}"
			fi
			;;
		esac
	else
		print_warning "Push işlemi iptal edildi."
	fi
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
	echo "9) Değişiklik Görüntüleme"
	echo "0) Çıkış"

	read -r -p "$(echo -e "${COLORS[BOLD]}Seçiminiz (0-9):${COLORS[NC]} ")" menu_choice

	case "$menu_choice" in
	1) perform_commit_push ;;
	2) manage_stash ;;
	3) view_logs ;;
	4) manage_branches ;;
	5) manage_tags ;;
	6) manage_remotes ;;
	7) manage_config ;;
	8) manage_clean ;;
	9) view_changes ;;
	0) cleanup_and_exit 0 "${COLORS[GREEN]}👋 Güle güle!${COLORS[NC]}" ;;
	*) print_error "Geçersiz seçim." ;;
	esac
}

# Git sürüm bilgisini kontrol eden fonksiyon
check_git_version() {
	local git_version
	if command -v git &>/dev/null; then
		git_version=$(git --version | sed -E 's/git version ([0-9]+\.[0-9]+).*/\1/')
		if (($(echo "$git_version < 2.23" | bc -l))); then
			print_warning "Git versiyonunuz ($git_version) eski olabilir. Bazı özellikler çalışmayabilir."
			return 1
		fi
	else
		print_error "Git yüklü değil!"
		return 2
	fi
	return 0
}

# Yardım menüsü
show_help() {
	echo -e "\n${COLORS[BOLD]}📚 NixOSC Yardım${COLORS[NC]}"
	echo -e "Kullanım: $(basename "$0") [parametre]"
	echo -e "\nParametreler:"
	echo -e "  -h, --help     : Bu yardım mesajını gösterir"
	echo -e "  -v, --version  : Versiyon bilgisini gösterir"
	echo -e "  --no-color     : Renkli çıktıyı devre dışı bırakır"
	echo -e "\nAçıklama:"
	echo -e "  NixOSC, Git işlemlerini kolaylaştırmak için tasarlanmış bir komut satırı aracıdır."
	echo -e "  Menü tabanlı bir arayüz sunar ve Git işlemlerini daha kullanıcı dostu hale getirir."
	echo -e "\nTemel Komutlar:"
	echo -e "  1) Commit ve Push: Değişiklikleri seçip commit eder ve uzak repoya gönderir"
	echo -e "  2) Stash İşlemleri: Geçici değişiklikleri saklar ve geri getirir"
	echo -e "  3) Log Görüntüleme: Commit geçmişini çeşitli formatlarda görüntüler"
	echo -e "  4) Branch İşlemleri: Branch oluşturma, silme ve geçiş yapma işlemleri"
	echo -e "  5) Tag İşlemleri: Sürüm etiketleme ve yönetimi"
	echo -e "  6) Remote Repo İşlemleri: Uzak repo ayarları ve yönetimi"
	echo -e "  7) Git Config İşlemleri: Git yapılandırma ayarları"
	echo -e "  8) Git Clean İşlemleri: Takip edilmeyen dosyaları yönetme"
	echo -e "  9) Değişiklik Görüntüleme: Dosya değişikliklerini inceleme"
}

# Versiyon bilgisini göster
show_version() {
	echo -e "${COLORS[BOLD]}NixOSC${COLORS[NC]} - Version 1.1.0"
	echo -e "Tarih: 2025-04-18"
	echo -e "Yazar: Kenan Pelit"
	echo -e "Repository: https://github.com/kenanpelit/nixosc"
}

# Renk desteğini devre dışı bırakma
disable_colors() {
	for key in "${!COLORS[@]}"; do
		COLORS["$key"]=""
	done
	print_info "Renkli çıktı devre dışı bırakıldı."
}

# Ana fonksiyon
main() {
	# Komut satırı parametrelerini işle
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			show_help
			exit 0
			;;
		-v | --version)
			show_version
			exit 0
			;;
		--no-color)
			disable_colors
			shift
			;;
		*)
			print_error "Bilinmeyen parametre: $1"
			echo "Yardım için: $(basename "$0") --help"
			exit 1
			;;
		esac
	done

	# Git kurulumunu kontrol et
	check_git_setup

	# Git sürümünü kontrol et
	check_git_version

	while true; do
		show_menu
	done
}

# Scripti çalıştır
main "$@"
