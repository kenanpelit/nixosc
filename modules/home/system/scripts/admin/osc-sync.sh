#!/usr/bin/env bash

# Renkli çıktı için ANSI renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Temel yapılandırma
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR="$HOME/.nixosc"
BACKUP_DIR="$SCRIPT_DIR/hay" # Değiştirildi
ASSET_DIR="$SCRIPT_DIR/assets"
LOG_DIR="$HOME/.logs/oscsync"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/sync_${TIMESTAMP}.log"

# Dosya isimleri
DOT_BACKUP="dotfiles.tar.gz"
DOT_ENCRYPTED="dotfiles.enc.tar.gz"
ASSET_BACKUP="asset.tar.gz"
ASSET_ENCRYPTED="enc.tar.gz"

# Gerekli paketlerin kontrolü
REQUIRED_PACKAGES=(
	"pv"      # Progress viewer
	"gpg"     # GPG encryption
	"sops"    # Mozilla SOPS
	"age"     # Age encryption
	"openssl" # OpenSSL
)

# Asset listesi
ASSET_DIRS=(
	"mpv"
	"oh-my-tmux"
	"tmux"
)

# Dot dizinleri (relative paths)
DOT_PATHS=(
	".config/sops"
	".config/nix"
	".config/github"
	".config/hblock"
	".config/zsh/history"
	".backups"
	".gnupg"
	".ssh"
	".vpn"
	".keys"
	".kenp"
	".pass"
	".podman"
	".todo"
	".zen"
	".wall"
)

# Log fonksiyonu
log() {
	local level=$1
	shift
	local message="[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*"
	mkdir -p "$LOG_DIR"
	echo -e "$message" | tee -a "$LOG_FILE"
}

# Hata yönetimi
error() {
	log "ERROR" "$1"
	echo -e "${RED}HATA: $1${NC}" >&2
	exit 1
}

# Başarı mesajı
success() {
	log "INFO" "$1"
	echo -e "${GREEN}==> $1${NC}"
}

# Uyarı mesajı
warn() {
	log "WARN" "$1"
	echo -e "${YELLOW}UYARI: $1${NC}"
}

# Gerekli paketlerin kontrolü
check_dependencies() {
	local missing_packages=()

	for package in "${REQUIRED_PACKAGES[@]}"; do
		if ! command -v "$package" >/dev/null 2>&1; then
			missing_packages+=("$package")
		fi
	done

	if [ ${#missing_packages[@]} -ne 0 ]; then
		error "Aşağıdaki paketler eksik: ${missing_packages[*]}"
	fi
}

# Dizin yapısını hazırla
prepare_directories() {
	local dirs=(
		"$SCRIPT_DIR"
		"$BACKUP_DIR"
		"$ASSET_DIR"
		"$LOG_DIR"
	)

	for dir in "${dirs[@]}"; do
		mkdir -p "$dir" || error "Dizin oluşturulamadı: $dir"
	done
}

# Disk alanı kontrolü
check_disk_space() {
	local required_space=$((1024 * 1024 * 100)) # 100MB minimum
	local available_space=$(df -B1 "$BACKUP_DIR" | awk 'NR==2 {print $4}')

	if [ "$available_space" -lt "$required_space" ]; then
		error "Yetersiz disk alanı. En az 100MB gerekli."
	fi
}

# Şifreleme tipi kontrolü ve ayarlanması
setup_encryption() {
	case "$ENCRYPTION_TYPE" in
	gpg)
		encrypt_file() {
			gpg --symmetric --cipher-algo AES256 --output "$2" "$1"
		}
		decrypt_file() {
			gpg --decrypt "$1"
		}
		;;
	age)
		encrypt_file() {
			local sops_config="${HOME}/.nixosc/.sops.yaml"
			if [[ ! -f "$sops_config" ]]; then
				error "SOPS yapılandırma dosyası bulunamadı: $sops_config"
			fi
			export SOPS_CONFIG_FILE="$sops_config"

			local age_key_file="${HOME}/.config/sops/age/keys.txt"
			if [[ ! -f "$age_key_file" ]]; then
				error "Age key dosyası bulunamadı"
			fi

			local age_public_key=$(grep "^# public key: " "$age_key_file" | cut -d: -f2 | tr -d ' ')
			if [[ -z "$age_public_key" ]]; then
				error "Public key bulunamadı"
			fi

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
			read -s password
			echo
			echo "Şifreyi tekrar girin:"
			read -s password2
			echo

			if [ "$password" != "$password2" ]; then
				error "Şifreler eşleşmiyor!"
			fi

			openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$password" -in "$1" -out "$2"
		}
		decrypt_file() {
			openssl enc -d -aes-256-cbc -salt -pbkdf2 -in "$1"
		}
		;;
	*)
		error "Geçersiz şifreleme tipi: $ENCRYPTION_TYPE"
		;;
	esac
}

# Dosya tipini kontrol et
check_file_type() {
	local file="$1"
	local file_type=$(file "$file")

	case "$file_type" in
	*"GPG"*)
		echo "gpg"
		;;
	*"openssl"*)
		echo "openssl"
		;;
	*)
		echo "age"
		;;
	esac
}

# Dot dosyaları yedekle
backup_dots() {
	success "Dot dosyaları yedekleniyor..."

	# Mevcut yolları kontrol et
	local existing_paths=()
	for path in "${DOT_PATHS[@]}"; do
		if [[ -e "$HOME/$path" ]]; then
			existing_paths+=("$path")
		else
			warn "Dosya/dizin mevcut değil: $HOME/$path"
		fi
	done

	if [ ${#existing_paths[@]} -eq 0 ]; then
		error "Yedeklenecek dot dosyası bulunamadı"
	fi

	# Yedekleme dizinini oluştur
	mkdir -p "$BACKUP_DIR" || error "Yedekleme dizini oluşturulamadı"

	# Ana dizine git
	cd "$HOME" || error "Home dizinine geçilemedi"

	# Tar oluştur
	success "Tar arşivi oluşturuluyor..."
	tar czf "$BACKUP_DIR/$DOT_BACKUP" "${existing_paths[@]}" || error "Tar oluşturulamadı"

	# Şifrele
	success "Arşiv şifreleniyor..."
	encrypt_file "$BACKUP_DIR/$DOT_BACKUP" "$BACKUP_DIR/$DOT_ENCRYPTED" || error "Şifreleme başarısız"

	# Geçici dosyayı temizle
	rm -f "$BACKUP_DIR/$DOT_BACKUP"

	success "Dot dosyaları yedeklendi: $BACKUP_DIR/$DOT_ENCRYPTED"
}

# Asset yedekle
backup_asset() {
	local asset_name="$1"

	# Asset kontrolü
	if [[ ! " ${ASSET_DIRS[@]} " =~ " ${asset_name} " ]]; then
		error "Geçersiz asset: $asset_name"
	fi

	if [ ! -d "$ASSET_DIR/$asset_name" ]; then
		error "Asset dizini bulunamadı: $ASSET_DIR/$asset_name"
	fi

	success "$asset_name yedekleniyor..."

	cd "$ASSET_DIR" || error "Asset dizinine geçilemedi"

	# Tar oluştur
	tar czf "$ASSET_BACKUP" "$asset_name" || error "Tar oluşturulamadı"

	# Şifrele
	encrypt_file "$ASSET_BACKUP" "${asset_name}.enc.tar.gz" || error "Şifreleme başarısız"

	# Geçici dosyayı temizle
	rm -f "$ASSET_BACKUP"

	success "Asset yedeklendi: ${asset_name}.${ASSET_ENCRYPTED}"
}

# Dot dosyalarını geri yükle
restore_dots() {
	local encrypted_file="$BACKUP_DIR/$DOT_ENCRYPTED"

	if [[ ! -f "$encrypted_file" ]]; then
		error "Şifrelenmiş yedek dosyası bulunamadı: $encrypted_file"
	fi

	success "Dot dosyaları geri yükleniyor..."

	# Her zaman $HOME dizinine geri yükleme yapılacak
	local restore_dir="$HOME"

	# Şifreleme tipini belirle
	ENCRYPTION_TYPE=$(check_file_type "$encrypted_file")
	setup_encryption

	# Önce içeriği göster
	echo "Arşiv içeriği:"
	decrypt_file "$encrypted_file" | tar tzvf - || error "Arşiv içeriği okunamadı"

	echo
	read -p "Bu dosyaları geri yüklemek istiyor musunuz? (e/H) " response
	if [[ ! "$response" =~ ^[Ee]$ ]]; then
		error "İşlem iptal edildi"
	fi

	# Mevcut dosyaları yedekle
	local backup_suffix="backup_$TIMESTAMP"
	for path in "${DOT_PATHS[@]}"; do
		if [[ -e "$HOME/$path" ]]; then
			mv "$HOME/$path" "$HOME/$path.$backup_suffix"
			success "Yedeklendi: $path -> $path.$backup_suffix"
		fi
	done

	# Geri yükle
	cd "$restore_dir" || error "Home dizinine geçilemedi"
	decrypt_file "$encrypted_file" | pv | tar xzf - || error "Geri yükleme başarısız"
	success "Dosyalar $restore_dir dizinine geri yüklendi"

	# İzinleri ayarla
	chmod 700 "$HOME/.ssh" "$HOME/.gnupg" 2>/dev/null || true

	success "Dot dosyaları geri yüklendi"
}

# Asset geri yükle
restore_asset() {
	local asset_name="$1"
	local encrypted_file="$ASSET_DIR/${asset_name}.${ASSET_ENCRYPTED}"

	if [[ ! -f "$encrypted_file" ]]; then
		error "Şifrelenmiş asset dosyası bulunamadı: $encrypted_file"
	fi

	success "$asset_name geri yükleniyor..."

	# Şifreleme tipini belirle
	ENCRYPTION_TYPE=$(check_file_type "$encrypted_file")
	setup_encryption

	# Önce içeriği göster
	echo "Arşiv içeriği:"
	decrypt_file "$encrypted_file" | tar tvf - || error "Arşiv içeriği okunamadı"

	echo
	read -p "Bu asset'i geri yüklemek istiyor musunuz? (e/H) " response
	if [[ ! "$response" =~ ^[Ee]$ ]]; then
		error "İşlem iptal edildi"
	fi

	# Mevcut asset'i yedekle
	if [ -d "$ASSET_DIR/$asset_name" ]; then
		mv "$ASSET_DIR/$asset_name" "$ASSET_DIR/$asset_name.backup_$TIMESTAMP"
		success "Mevcut asset yedeklendi"
	fi

	# Geri yükle
	cd "$ASSET_DIR" || error "Asset dizinine geçilemedi"
	decrypt_file "$encrypted_file" | pv | tar xzf - || error "Geri yükleme başarısız"

	success "$asset_name geri yüklendi"
}

# Asset'leri listele
list_assets() {
	local mode="${1:-simple}" # simple veya detailed

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
			# Asset dizin boyutu
			if [ -d "$ASSET_DIR/$asset" ]; then
				local dir_size=$(du -sh "$ASSET_DIR/$asset" 2>/dev/null | cut -f1)
				local file_count=$(find "$ASSET_DIR/$asset" -type f | wc -l)
				echo -ne "${GREEN}[Dizin: $dir_size, Dosya sayısı: $file_count]${NC}"
			fi
			# Yedek dosyası kontrolü
			if [ -f "$ASSET_DIR/$asset.enc.tar.gz" ]; then
				local timestamp=$(date -r "$ASSET_DIR/$asset.enc.tar.gz" "+%Y-%m-%d %H:%M")
				local backup_size=$(du -h "$ASSET_DIR/$asset.enc.tar.gz" | cut -f1)
				echo -e " ${BLUE}[Son yedek: $timestamp - $backup_size]${NC}"
			else
				echo -e " ${YELLOW}[Yedeklenmemiş]${NC}"
			fi
		done
		;;
	*)
		error "Geçersiz listeleme modu: $mode"
		;;
	esac
}

# Yardım mesajı
show_help() {
	cat <<EOF
OSC Sync - Dot Dosyaları ve Asset Yedekleme Aracı
Kullanım: $SCRIPT_NAME [seçenekler] KOMUT [argümanlar]

Komutlar:
    dots backup              : Dot dosyalarını yedekle
    dots restore            : Dot dosyalarını geri yükle
    dots list [-d|--detailed]: Dot dosyalarını listele (basit veya detaylı)
    
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

# Ana program
main() {
	# Varsayılan değerler
	ENCRYPTION_TYPE="gpg"

	# Gerekli kontroller
	check_dependencies
	prepare_directories
	check_disk_space

	# Parametre analizi
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

	# Şifreleme ayarlarını yap
	setup_encryption

	# Komut analizi
	case "${1:-}" in
	"dots")
		case "${2:-}" in
		"backup")
			backup_dots
			;;
		"restore")
			restore_dots
			;;
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
		*)
			error "Geçersiz dots komutu. Kullanım: dots {backup|restore|list}"
			;;
		esac
		;;
	"asset")
		case "${2:-}" in
		"backup")
			if [ -z "${3:-}" ]; then
				error "Asset adı belirtilmedi. Kullanım: asset backup ASSET_ADI"
			fi
			backup_asset "$3"
			;;
		"restore")
			if [ -z "${3:-}" ]; then
				error "Asset adı belirtilmedi. Kullanım: asset restore ASSET_ADI"
			fi
			restore_asset "$3"
			;;
		"list")
			case "${3:-}" in
			"-d" | "--detailed")
				list_assets "detailed"
				;;
			*)
				list_assets "simple"
				;;
			esac
			;;
		*)
			error "Geçersiz asset komutu. Kullanım: asset {backup|restore|list} [ASSET_ADI]"
			;;
		esac
		;;
	*)
		show_help
		exit 1
		;;
	esac
}

# Trap sinyalleri yakala
trap 'error "İşlem kullanıcı tarafından iptal edildi"' INT TERM

# Programı çalıştır
main "$@"
