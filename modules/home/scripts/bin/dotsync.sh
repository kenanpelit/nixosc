#!/usr/bin/env bash

# Renkli çıktı için ANSI renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Yapılandırma
BACKUP_DIR="$HOME/.nixosc/assets"
BACKUP_STORE="$HOME/.backup"
LOG_DIR="$HOME/.logs"
BACKUP_FILE="dot.tar.gz"
ENCRYPTED_FILE="dot.enc.tar.gz"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/backup_$TIMESTAMP.log"

# pv ve gpg kontrolü
command -v pv >/dev/null 2>&1 || {
	echo "pv paketi gerekli. Lütfen yükleyin."
	exit 1
}
command -v gpg >/dev/null 2>&1 || {
	echo "gpg paketi gerekli. Lütfen yükleyin."
	exit 1
}

# Asset Listesi
ASSET_DIRS=(
	"mpv"
	"oh-my-tmux"
	"tmux"
)

# Yedeklenecek dizinler (relative paths)
BACKUP_PATHS=(
	".anote"
	".anydesk"
	".back"
	".config/sops"
	".config/nix"
	".config/github"
	".config/zsh/history"
	".gnupg"
	".kenp"
	".keep"
	".keys"
	".nix"
	".pass"
	".podman"
	".ssh"
	".vpn"
)

# Log fonksiyonu
log() {
	local level=$1
	shift
	local message="[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*"
	mkdir -p "$LOG_DIR"
	echo -e "$message" | tee -a "$LOG_FILE"
}

# Asset yönetimi
manage_assets() {
	local command=$1

	# "list" veya parametre yoksa liste göster
	if [ -z "$command" ] || [ "$command" = "list" ]; then
		echo -e "${BLUE}Mevcut Asset'ler:${NC}"
		echo "------------------------"
		for asset in "${ASSET_DIRS[@]}"; do
			echo -ne "${GREEN}$asset${NC}\t"
			if [ -f "$BACKUP_DIR/$asset.enc.tar.gz" ]; then
				local timestamp=$(date -r "$BACKUP_DIR/$asset.enc.tar.gz" "+%Y-%m-%d %H:%M")
				local size=$(du -h "$BACKUP_DIR/$asset.enc.tar.gz" | cut -f1)
				echo -e "${GREEN}[Yedek var: $timestamp - $size]${NC}"
			else
				echo -e "${YELLOW}[Yedeklenmemiş]${NC}"
			fi
		done
		return
	fi

	# Geçerli asset kontrolü
	if [[ ! " ${ASSET_DIRS[@]} " =~ " ${command} " ]]; then
		error "Geçersiz asset: $command"
	fi

	if [ ! -d "$BACKUP_DIR/$command" ]; then
		error "Asset dizini bulunamadı: $BACKUP_DIR/$command"
	fi

	local backup_name="${command}.tar.gz"
	local encrypted_name="${command}.enc.tar.gz"

	success "$command asset'i yedekleniyor..."

	cd "$BACKUP_DIR" || error "Backup dizinine geçilemedi"

	# Önceki dosyaları temizle
	rm -f "$backup_name" "$encrypted_name"

	# Tar oluştur ve şifrele
	success "Tar arşivi oluşturuluyor ve şifreleniyor..."
	tar czf "$backup_name" "$command" || error "Tar oluşturulamadı"
	sops -e "$backup_name" >"$encrypted_name" || error "Şifreleme başarısız"
	rm -f "$backup_name"

	local size=$(du -h "$encrypted_name" | cut -f1)
	success "Asset başarıyla yedeklendi: $encrypted_name (Boyut: $size)"
}

# Hata mesajı fonksiyonu
error() {
	log "ERROR" "$1"
	echo -e "${RED}ERROR: $1${NC}" >&2
	exit 1
}

# Başarı mesajı fonksiyonu
success() {
	log "INFO" "$1"
	echo -e "${GREEN}==> $1${NC}"
}

# Uyarı mesajı fonksiyonu
warn() {
	log "WARN" "$1"
	echo -e "${YELLOW}UYARI: $1${NC}"
}

# Manuel açma komutlarını göster
show_manual_commands() {
	echo -e "${BLUE}Manuel Açma Komutları${NC}"
	echo "Not: Önce dosya tipini kontrol edin:"
	echo -e "${GREEN}file dot.enc.tar.gz${NC}"
	echo
	echo "SOPS ile şifrelenmiş dosyayı açmak için:"
	echo -e "${GREEN}sops -d file.enc.tar.gz | tar xzf -${NC}"
	echo
	echo "GPG ile şifrelenmiş dosyayı açmak için:"
	echo -e "${GREEN}gpg --decrypt dot.enc.tar.gz | tar xzf -${NC}"
	echo
	echo "OpenSSL ile şifrelenmiş dosyayı açmak için:"
	echo -e "${GREEN}openssl enc -d -aes-256-cbc -salt -pbkdf2 -in dot.enc.tar.gz | tar xzf -${NC}"
	echo
	echo "İlerleme çubuğu görmek için komutların ortasına pv ekleyin:"
	echo -e "${GREEN}sops -d file.enc.tar.gz | pv | tar xzf -${NC}"
}

# Yardım mesajı
usage() {
	echo "Kullanım: $0 [-d] [-e|-a|-o] {backup|restore|list|cron|manual|help|asset}"
	echo
	echo "Komutlar:"
	echo "  backup  : Dot dosyalarını yedekle ve şifrele"
	echo "  restore : Şifrelenmiş yedeği geri yükle"
	echo "  list    : Yedeklenecek dosyaları listele"
	echo "  cron    : Cronjob kurulumu"
	echo "  manual  : Manuel açma komutlarını göster"
	echo "  help    : Detaylı yardım göster"
	echo "  asset   : Asset yönetimi (mpv, tmux, oh-my-tmux)"
	echo
	echo "Seçenekler:"
	echo "  -d      : Yedekleme sonrası orijinal tar dosyasını sil"
	echo "  -e      : GPG ile şifrele (manuel parola ile)"
	echo "  -a      : Age ile şifrele (public key ile)"
	echo "  -o      : OpenSSL ile şifrele (manuel parola ile)"
	echo "  -h      : Bu yardım mesajını göster"
	exit 1
}

# Help mesajı
show_help() {
	echo "Dotfiles Yedekleme Aracı"
	echo "------------------------"
	echo "Bu script, dot dosyalarınızı ve önemli asset'lerinizi yedeklemenize ve şifrelemenize yardımcı olur."
	echo
	echo "Temel Özellikler:"
	echo "  - Çoklu şifreleme desteği (GPG, Age, OpenSSL)"
	echo "  - Asset yönetimi (mpv, tmux, oh-my-tmux)"
	echo "  - İlerleme çubuğu gösterimi"
	echo "  - Otomatik yedekleme (cronjob)"
	echo "  - Detaylı loglama sistemi"
	echo
	echo "Kullanım Örnekleri:"
	echo "  $0 -e backup         : GPG ile şifreli yedek al"
	echo "  $0 -a backup         : Age ile şifreli yedek al"
	echo "  $0 -o backup         : OpenSSL ile şifreli yedek al"
	echo "  $0 asset mpv        : mpv asset'ini yedekle"
	echo "  $0 asset            : Tüm asset'leri listele"
	echo "  $0 manual           : Manuel komutları göster"
	echo
	echo "Not: Şifreleme yöntemi seçilmeden yedekleme yapılamaz."
}

# Disk alanı kontrolü
check_disk_space() {
	local required_space=$((1024 * 1024 * 100)) # 100MB minimum
	local available_space=$(df -B1 "$BACKUP_DIR" | awk 'NR==2 {print $4}')

	if [ "$available_space" -lt "$required_space" ]; then
		error "Yetersiz disk alanı. En az 100MB gerekli."
	fi
}

# Progress bar ile şifreli tar oluşturma
create_encrypted_tar() {
	local source_files=("$@")
	local total_size=$(du -bc "${source_files[@]}" 2>/dev/null | tail -n1 | cut -f1)
	local password

	# Tar oluştur
	tar czf "$BACKUP_DIR/$BACKUP_FILE" "${source_files[@]}" || error "Tar oluşturulamadı"

	cd "$BACKUP_DIR" || error "Backup dizinine geçilemedi"

	# Şifreleme yöntemine göre işlem yap
	if [ "$USE_GPG" = "true" ]; then
		gpg --symmetric --cipher-algo AES256 --output "$ENCRYPTED_FILE" "$BACKUP_FILE"
	elif [ "$USE_AGE" = "true" ]; then
		sops -e "$BACKUP_FILE" >"$ENCRYPTED_FILE" || error "Şifreleme başarısız"
	elif [ "$USE_OPENSSL" = "true" ]; then
		echo "Arşiv için şifre girin:"
		read -s password
		echo
		echo "Şifreyi tekrar girin:"
		read -s password2
		echo

		if [ "$password" != "$password2" ]; then
			error "Şifreler eşleşmiyor!"
		fi

		openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$password" -in "$BACKUP_FILE" -out "$ENCRYPTED_FILE"
	fi

	# Yedek dosyayı sil
	rm -f "$BACKUP_FILE"
}

# Yolları kontrol et
check_paths() {
	local missing_paths=()
	local existing_paths=()

	for path in "${BACKUP_PATHS[@]}"; do
		if [[ -e "$HOME/$path" ]]; then
			existing_paths+=("$path")
		else
			missing_paths+=("$HOME/$path")
		fi
	done

	if [ ${#missing_paths[@]} -ne 0 ]; then
		warn "Aşağıdaki dosya/dizinler mevcut değil:"
		printf '%s\n' "${missing_paths[@]}"
		echo
		echo "Yedeklenecek mevcut dosyalar:"
		printf '%s\n' "${existing_paths[@]}"
		echo
		read -p "Bu dosyalarla devam edilsin mi? (e/H) " response
		if [[ ! "$response" =~ ^[Ee]$ ]]; then
			error "İşlem iptal edildi"
		fi
		export EXISTING_PATHS=("${existing_paths[@]}")
	else
		export EXISTING_PATHS=("${BACKUP_PATHS[@]}")
	fi
}

# Cronjob kurulumu
setup_cron() {
	local script_path=$(realpath "$0")
	local cron_cmd="0 0 * * * $script_path -a backup > $LOG_DIR/cron_backup.log 2>&1"

	# Mevcut crontab'i kontrol et
	if crontab -l 2>/dev/null | grep -Fq "$script_path"; then
		warn "Cronjob zaten mevcut."
		return
	fi

	# Yeni cronjob ekle
	(
		crontab -l 2>/dev/null
		echo "$cron_cmd"
	) | crontab -
	success "Günlük yedekleme için cronjob eklendi."
}

# Yedekleme işlemi
create_backup() {
	local delete_original=$1

	success "Yedekleme işlemi başlıyor..."
	log "INFO" "Yedekleme başlatıldı"

	# Disk alanı kontrolü
	check_disk_space

	# Yedekleme dizinlerini oluştur
	mkdir -p "$BACKUP_DIR" "$BACKUP_STORE" "$LOG_DIR" || error "Dizinler oluşturulamadı"

	# Ana dizine git
	cd "$HOME" || error "Home dizinine geçilemedi"

	# Şifreli tar arşivi oluştur
	success "Şifreli tar arşivi oluşturuluyor..."
	echo "Arşivlenen dosyalar:"
	printf '%s\n' "${EXISTING_PATHS[@]}"

	create_encrypted_tar "${EXISTING_PATHS[@]}" || error "Şifreli tar arşivi oluşturulamadı"

	# Yedek kopyayı oluştur
	if [ "$delete_original" != "true" ]; then
		cp "$BACKUP_DIR/$ENCRYPTED_FILE" "$BACKUP_STORE/${TIMESTAMP}_${ENCRYPTED_FILE}" || warn "Yedek kopya oluşturulamadı"
		success "Yedek kopya oluşturuldu: $BACKUP_STORE/${TIMESTAMP}_${ENCRYPTED_FILE}"
	fi

	success "İşlem tamamlandı: $BACKUP_DIR/$ENCRYPTED_FILE"
	log "INFO" "Yedekleme başarıyla tamamlandı"
}

# Geri yükleme işlemi
restore_backup() {
	if [[ ! -f "$BACKUP_DIR/$ENCRYPTED_FILE" ]]; then
		error "Şifrelenmiş yedek dosyası bulunamadı"
	fi

	success "Geri yükleme başlıyor..."
	log "INFO" "Geri yükleme başlatıldı"

	cd "$BACKUP_DIR" || error "Backup dizinine geçilemedi"

	# Şifre çözme ve arşiv içeriğini görüntüleme
	if file "$ENCRYPTED_FILE" | grep -q "GPG"; then
		success "GPG şifresi çözülüyor..."
		gpg --decrypt "$ENCRYPTED_FILE" | tar tvf - || error "GPG şifre çözme başarısız"
	else
		success "Sops şifresi çözülüyor..."
		sops -d "$ENCRYPTED_FILE" | tar tvf - || error "Sops şifre çözme başarısız"
	fi

	echo
	read -p "Bu dosyaları geri yüklemek istiyor musunuz? (e/H) " response
	if [[ ! "$response" =~ ^[Ee]$ ]]; then
		error "İşlem iptal edildi"
	fi

	# Arşivi aç ve dosyaları geri yükle
	success "Dosyalar geri yükleniyor..."
	cd "$HOME" || error "Home dizinine geçilemedi"

	if file "$BACKUP_DIR/$ENCRYPTED_FILE" | grep -q "GPG"; then
		gpg --decrypt "$BACKUP_DIR/$ENCRYPTED_FILE" | pv | tar xzf - || error "GPG ile geri yükleme başarısız"
	else
		sops -d "$BACKUP_DIR/$ENCRYPTED_FILE" | pv | tar xzf - || error "Sops ile geri yükleme başarısız"
	fi

	# Özel izinleri ayarla
	chmod 700 "$HOME/.ssh" "$HOME/.gnupg" 2>/dev/null || true
	success "Geri yükleme tamamlandı"
	log "INFO" "Geri yükleme başarıyla tamamlandı"
}

# Dosya listesini göster
list_files() {
	echo "Yedeklenecek dosya ve dizinler:"
	printf '%s\n' "${BACKUP_PATHS[@]}"
}

# Ana program
DELETE_ORIGINAL=false
USE_GPG=false
USE_AGE=false
USE_OPENSSL=false
ENCRYPTION_SET=false

# Parametre analizi
while getopts "deaoh" opt; do
	case $opt in
	d) DELETE_ORIGINAL=true ;;
	e)
		USE_GPG=true
		ENCRYPTION_SET=true
		;;
	a)
		USE_AGE=true
		ENCRYPTION_SET=true
		;;
	o)
		USE_OPENSSL=true
		ENCRYPTION_SET=true
		;;
	h) usage ;;
	\?) usage ;;
	esac
done
shift $((OPTIND - 1))

# Komut analizi
case "$1" in
"backup")
	if [ "$ENCRYPTION_SET" = "false" ]; then
		error "Şifreleme yöntemi seçilmedi. (-e, -a veya -o kullanın)"
	fi
	check_paths
	create_backup "$DELETE_ORIGINAL"
	;;
"restore")
	restore_backup
	;;
"list")
	list_files
	;;
"cron")
	setup_cron
	;;
"manual" | "manuel")
	show_manual_commands
	;;
"help")
	show_help
	;;
"asset")
	manage_assets "$2" # $2 boş olabilir, fonksiyon bunu kontrol ediyor
	;;
*)
	usage
	;;
esac
