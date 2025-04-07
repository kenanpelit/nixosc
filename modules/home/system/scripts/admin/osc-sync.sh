#!/usr/bin/env bash
#===============================================================================
#
#   Project: NixOS Configuration Suite (nixosc)
#   Version: 2.0.0
#   Date: 2024-01-23
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Comprehensive NixOS configuration management suite with
#                VPN-aware workspace session handling and automated tooling
#
#   Components:
#   - Hybrid Workspace Session Launcher
#   - Configuration Backup System
#   - Admin Script Generator
#   - VPN-aware Session Management
#
#   Features:
#   - Automated configuration backup and restoration
#   - Dynamic session management with VPN awareness
#   - Modular admin script integration
#   - Home-manager integration
#   - Extensible plugin architecture
#
#   License: MIT
#
#===============================================================================
# Renkli çıktı için ANSI renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Temel yapılandırma
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR="$HOME/.nixosc"
BACKUP_DIR="$SCRIPT_DIR/hay"
ASSET_DIR="$SCRIPT_DIR/assets"
LOG_DIR="$HOME/.logs/oscsync"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/sync_${TIMESTAMP}.log"

# Dosya isimleri
DOT_BACKUP="dotfiles.tar.gz"
DOT_ENCRYPTED="dotfiles.enc.tar.gz"
ASSET_BACKUP="asset.tar.gz"
ASSET_ENCRYPTED="enc.tar.gz"

# Gerekli paketler
REQUIRED_PACKAGES=(
	"pv"
	"gpg"
	"sops"
	"age"
	"openssl"
	"file"
)

# Asset listesi
ASSET_DIRS=(
	"mpv"
	"oh-my-tmux"
	"tmux"
)

# Dot dizinleri
DOT_PATHS=(
	".anote"
	".anydesk"
	".apps"
	".backups"
	".config/github"
	".config/google-chrome"
	".config/hblock"
	".config/nix"
	".config/sops"
	".config/subliminal"
	".config/ulauncher"
	".config/walker"
	".config/zsh/history"
	".gnupg"
	".iptv"
	".keep"
	".kenp"
	".keys"
	".local/share/ulauncher"
	".mozilla"
	".notes"
	".pass"
	".podman"
	".ssh"
	".todo"
	".vir"
	".vnc"
	".vpn"
	".zen"
)

# Log fonksiyonları
log() {
	local level=$1
	shift
	local message="[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*"
	mkdir -p "$LOG_DIR"
	echo -e "$message" | tee -a "$LOG_FILE"
}

error() {
	log "ERROR" "$1"
	echo -e "${RED}HATA: $1${NC}" >&2
	exit 1
}

success() {
	log "INFO" "$1"
	echo -e "${GREEN}==> $1${NC}"
}

warn() {
	log "WARN" "$1"
	echo -e "${YELLOW}UYARI: $1${NC}"
}

# Temel kontroller
check_dependencies() {
	local missing_packages=()
	for package in "${REQUIRED_PACKAGES[@]}"; do
		if ! command -v "$package" >/dev/null 2>&1; then
			missing_packages+=("$package")
		fi
	done
	[[ ${#missing_packages[@]} -ne 0 ]] && error "Eksik paketler: ${missing_packages[*]}"
}

prepare_directories() {
	local dirs=("$SCRIPT_DIR" "$BACKUP_DIR" "$ASSET_DIR" "$LOG_DIR")
	for dir in "${dirs[@]}"; do
		mkdir -p "$dir" || error "Dizin oluşturulamadı: $dir"
	done
}

check_disk_space() {
	local required_space=$((1024 * 1024 * 100))
	local available_space=$(df -B1 "$BACKUP_DIR" | awk 'NR==2 {print $4}')
	[[ "$available_space" -lt "$required_space" ]] && error "Yetersiz disk alanı (min. 100MB)"
}

check_file_type() {
	local file="$1"
	local file_type=$(file "$file")
	case "$file_type" in
	*"GPG"*) echo "gpg" ;;
	*"openssl"*) echo "openssl" ;;
	*) echo "age" ;;
	esac
}

# Şifreleme fonksiyonları
setup_encryption() {
	case "$ENCRYPTION_TYPE" in
	gpg)
		encrypt_file() { gpg --symmetric --cipher-algo AES256 --output "$2" "$1"; }
		decrypt_file() { gpg --decrypt "$1"; }
		;;
	age)
		encrypt_file() {
			local sops_config="${HOME}/.nixosc/.sops.yaml"
			local age_key_file="${HOME}/.config/sops/age/keys.txt"
			[[ ! -f "$sops_config" ]] && error "SOPS yapılandırma dosyası yok: $sops_config"
			[[ ! -f "$age_key_file" ]] && error "Age key dosyası yok"

			local age_public_key=$(grep "^# public key: " "$age_key_file" | cut -d: -f2 | tr -d ' ')
			[[ -z "$age_public_key" ]] && error "Public key bulunamadı"

			export SOPS_CONFIG_FILE="$sops_config"
			sops --encrypt --age "$age_public_key" "$1" >"$2" || return 1
		}
		decrypt_file() {
			export SOPS_CONFIG_FILE="${HOME}/.nixosc/.sops.yaml"
			sops --decrypt "$1" || return 1
		}
		;;
	openssl)
		encrypt_file() {
			local password
			echo "Şifre girin:"
			read -rs password
			echo
			echo "Şifreyi tekrar girin:"
			read -rs password2
			echo
			[[ "$password" != "$password2" ]] && error "Şifreler eşleşmiyor!"
			openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$password" -in "$1" -out "$2"
		}
		decrypt_file() {
			openssl enc -d -aes-256-cbc -salt -pbkdf2 -in "$1"
		}
		;;
	*) error "Geçersiz şifreleme tipi: $ENCRYPTION_TYPE" ;;
	esac
}

# Yedekleme fonksiyonları
backup_dots() {
	success "Dot dosyaları yedekleniyor..."
	local existing_paths=()

	for path in "${DOT_PATHS[@]}"; do
		if [[ -e "$HOME/$path" ]]; then
			existing_paths+=("$path")
		else
			warn "Mevcut değil: $HOME/$path"
		fi
	done

	[[ ${#existing_paths[@]} -eq 0 ]] && error "Yedeklenecek dot dosyası yok"

	mkdir -p "$BACKUP_DIR" || error "Yedekleme dizini oluşturulamadı"
	cd "$HOME" || error "Home dizinine geçilemedi"

	success "Tar arşivi oluşturuluyor..."
	tar czf "$BACKUP_DIR/$DOT_BACKUP" "${existing_paths[@]}" || error "Tar oluşturulamadı"

	success "Arşiv şifreleniyor..."
	if encrypt_file "$BACKUP_DIR/$DOT_BACKUP" "$BACKUP_DIR/$DOT_ENCRYPTED"; then
		rm -f "$BACKUP_DIR/$DOT_BACKUP"
		success "Dot dosyaları yedeklendi: $BACKUP_DIR/$DOT_ENCRYPTED"
	else
		rm -f "$BACKUP_DIR/$DOT_BACKUP" "$BACKUP_DIR/$DOT_ENCRYPTED"
		error "Şifreleme başarısız"
	fi
}

restore_dots() {
	local encrypted_file="$BACKUP_DIR/$DOT_ENCRYPTED"
	[[ ! -f "$encrypted_file" ]] && error "Şifrelenmiş yedek dosyası bulunamadı: $encrypted_file"

	success "Dot dosyaları geri yükleniyor..."
	local restore_dir="$HOME"
	local temp_file="/tmp/dotfiles_${TIMESTAMP}.tar.gz"

	ENCRYPTION_TYPE=$(check_file_type "$encrypted_file")
	setup_encryption

	# Şifreyi çöz
	if [[ "$ENCRYPTION_TYPE" == "openssl" ]]; then
		openssl enc -d -aes-256-cbc -salt -pbkdf2 -in "$encrypted_file" -out "$temp_file" || error "Şifre çözme başarısız"
	else
		decrypt_file "$encrypted_file" >"$temp_file" || error "Şifre çözme başarısız"
	fi

	# İçerik göster
	tar tvf "$temp_file" || error "Arşiv içeriği okunamadı"

	read -rp "Bu dosyaları geri yüklemek istiyor musunuz? (e/H) " response
	[[ ! "$response" =~ ^[Ee]$ ]] && {
		rm -f "$temp_file"
		error "İşlem iptal edildi"
	}

	# Yedekle
	local backup_suffix="backup_$TIMESTAMP"
	for path in "${DOT_PATHS[@]}"; do
		if [[ -e "$HOME/$path" ]]; then
			mv "$HOME/$path" "$HOME/$path.$backup_suffix"
			success "Yedeklendi: $path -> $path.$backup_suffix"
		fi
	done

	cd "$restore_dir" || error "Home dizinine geçilemedi"
	pv "$temp_file" | tar xzf - || error "Geri yükleme başarısız"
	rm -f "$temp_file"

	chmod 700 "$HOME/.ssh" "$HOME/.gnupg" 2>/dev/null || true
	success "Dot dosyaları geri yüklendi"
}

backup_asset() {
	local asset_name="$1"
	[[ ! " ${ASSET_DIRS[@]} " =~ " ${asset_name} " ]] && error "Geçersiz asset: $asset_name"
	[[ ! -d "$ASSET_DIR/$asset_name" ]] && error "Asset dizini bulunamadı: $ASSET_DIR/$asset_name"

	success "$asset_name yedekleniyor..."
	cd "$ASSET_DIR" || error "Asset dizinine geçilemedi"

	tar czf "$ASSET_BACKUP" "$asset_name" || error "Tar oluşturulamadı"
	if encrypt_file "$ASSET_BACKUP" "${asset_name}.enc.tar.gz"; then
		rm -f "$ASSET_BACKUP"
		success "Asset yedeklendi: ${asset_name}.${ASSET_ENCRYPTED}"
	else
		rm -f "$ASSET_BACKUP" "${asset_name}.enc.tar.gz"
		error "Şifreleme başarısız"
	fi
}

restore_asset() {
	local asset_name="$1"
	local encrypted_file="$ASSET_DIR/${asset_name}.${ASSET_ENCRYPTED}"
	[[ ! -f "$encrypted_file" ]] && error "Şifrelenmiş asset dosyası bulunamadı: $encrypted_file"

	success "$asset_name geri yükleniyor..."
	local temp_file="/tmp/asset_${TIMESTAMP}.tar.gz"

	ENCRYPTION_TYPE=$(check_file_type "$encrypted_file")
	setup_encryption

	if [[ "$ENCRYPTION_TYPE" == "openssl" ]]; then
		openssl enc -d -aes-256-cbc -salt -pbkdf2 -in "$encrypted_file" -out "$temp_file" || error "Şifre çözme başarısız"
	else
		decrypt_file "$encrypted_file" >"$temp_file" || error "Şifre çözme başarısız"
	fi

	tar tvf "$temp_file" || error "Arşiv içeriği okunamadı"

	read -rp "Bu asset'i geri yüklemek istiyor musunuz? (e/H) " response
	[[ ! "$response" =~ ^[Ee]$ ]] && {
		rm -f "$temp_file"
		error "İşlem iptal edildi"
	}

	[[ -d "$ASSET_DIR/$asset_name" ]] && {
		mv "$ASSET_DIR/$asset_name" "$ASSET_DIR/$asset_name.backup_$TIMESTAMP"
		success "Mevcut asset yedeklendi"
	}

	cd "$ASSET_DIR" || error "Asset dizinine geçilemedi"
	pv "$temp_file" | tar xzf - || error "Geri yükleme başarısız"
	rm -f "$temp_file"

	success "$asset_name geri yüklendi"
}

list_assets() {
	local mode="${1:-simple}"
	case "$mode" in
	"simple")
		echo "Mevcut Asset'ler:"
		printf '%s\n' "${ASSET_DIRS[@]}"
		;;
	"detailed")
		echo -e "${BLUE}Mevcut Asset'ler:${NC}"
		echo "------------------------"
		for asset in "${ASSET_DIRS[@]}"; do
			echo -ne "${GREEN}$asset${NC}\t"
			if [[ -d "$ASSET_DIR/$asset" ]]; then
				local dir_size=$(du -sh "$ASSET_DIR/$asset" 2>/dev/null | cut -f1)
				local file_count=$(find "$ASSET_DIR/$asset" -type f | wc -l)
				echo -ne "${GREEN}[Dizin: $dir_size, Dosya sayısı: $file_count]${NC}"
			fi
			if [[ -f "$ASSET_DIR/$asset.enc.tar.gz" ]]; then
				local timestamp=$(date -r "$ASSET_DIR/$asset.enc.tar.gz" "+%Y-%m-%d %H:%M")
				local backup_size=$(du -h "$ASSET_DIR/$asset.enc.tar.gz" | cut -f1)
				echo -e " ${BLUE}[Son yedek: $timestamp - $backup_size]${NC}"
			else
				echo -e " ${YELLOW}[Yedeklenmemiş]${NC}"
			fi
		done
		;;
	*) error "Geçersiz listeleme modu: $mode" ;;
	esac
}

show_help() {
	cat <<EOF
OSC Sync - Dot Dosyaları ve Asset Yedekleme Aracı
Kullanım: $SCRIPT_NAME [seçenekler] KOMUT [argümanlar]

Komutlar:
    dots backup              : Dot dosyalarını yedekle
    dots restore            : Dot dosyalarını geri yükle
    dots list [-d|--detailed]: Dot dosyalarını listele

    asset backup ASSET      : Belirtilen asset'i yedekle
    asset restore ASSET     : Belirtilen asset'i geri yükle
    asset list             : Tüm asset'leri listele

Seçenekler:
    -e  : GPG ile şifrele (varsayılan)
    -a  : Age/SOPS ile şifrele
    -o  : OpenSSL ile şifrele
    -h  : Bu yardım mesajını göster

Örnekler:
    $SCRIPT_NAME -e dots backup     : Dot dosyalarını GPG ile yedekle
    $SCRIPT_NAME -a asset backup mpv: mpv asset'ini Age ile yedekle
    $SCRIPT_NAME dots restore       : Dot dosyalarını geri yükle
    $SCRIPT_NAME asset list         : Asset'leri listele
EOF
}

main() {
	ENCRYPTION_TYPE="gpg"

	check_dependencies
	prepare_directories
	check_disk_space

	while getopts "eaoh" opt; do
		case $opt in
		e) ENCRYPTION_TYPE="gpg" ;;
		a) ENCRYPTION_TYPE="age" ;;
		o) ENCRYPTION_TYPE="openssl" ;;
		h)
			show_help
			exit 0
			;;
		\?)
			show_help
			exit 1
			;;
		esac
	done
	shift $((OPTIND - 1))

	setup_encryption

	case "${1:-}" in
	"dots")
		case "${2:-}" in
		"backup") backup_dots ;;
		"restore") restore_dots ;;
		"list")
			if [ "${3:-}" = "-d" ] || [ "${3:-}" = "--detailed" ]; then
				echo "Yedeklenecek dot dosyaları (detaylı):"
				echo "------------------------"
				for path in "${DOT_PATHS[@]}"; do
					echo -ne "${GREEN}$path${NC}\t"
					if [ -e "$HOME/$path" ]; then
						local size=$(du -sh "$HOME/$path" 2>/dev/null | cut -f1)
						if [ -d "$HOME/$path" ]; then
							echo -e "${GREEN}[Dizin: $size]${NC}"
						else
							echo -e "${GREEN}[Dosya: $size]${NC}"
						fi
					else
						echo -e "${YELLOW}[Mevcut değil]${NC}"
					fi
				done

				if [ -f "$BACKUP_DIR/$DOT_ENCRYPTED" ]; then
					echo -e "\n${BLUE}Son Yedek:${NC}"
					local timestamp=$(date -r "$BACKUP_DIR/$DOT_ENCRYPTED" "+%Y-%m-%d %H:%M")
					local size=$(du -h "$BACKUP_DIR/$DOT_ENCRYPTED" | cut -f1)
					echo -e "${GREEN}[Yedek var: $timestamp - $size]${NC}"
				fi
			else
				echo "Yedeklenecek dot dosyaları:"
				printf '%s\n' "${DOT_PATHS[@]}"
			fi
			;;
		*) error "Geçersiz dots komutu. Kullanım: dots {backup|restore|list}" ;;
		esac
		;;
	"asset")
		case "${2:-}" in
		"backup")
			[ -z "${3:-}" ] && error "Asset adı belirtilmedi"
			backup_asset "$3"
			;;
		"restore")
			[ -z "${3:-}" ] && error "Asset adı belirtilmedi"
			restore_asset "$3"
			;;
		"list")
			case "${3:-}" in
			"-d" | "--detailed") list_assets "detailed" ;;
			*) list_assets "simple" ;;
			esac
			;;
		*) error "Geçersiz asset komutu" ;;
		esac
		;;
	*)
		show_help
		exit 1
		;;
	esac
}

trap 'error "İşlem kullanıcı tarafından iptal edildi"' INT TERM

main "$@"
