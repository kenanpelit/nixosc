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

# Manuel açma komutlarını göster
show_manual_commands() {
	echo -e "${BLUE}Manuel Açma Komutları${NC}"
	echo "Not: Önce dosya tipini kontrol edin:"
	echo -e "${GREEN}file dot.enc.tar.gz${NC}"
	echo
	echo "Age ile şifrelenmiş dosyayı açmak için:"
	echo -e "${GREEN}age -d -i ~/.config/sops/age/keys.txt -o - dot.enc.tar.gz | tar xzf -${NC}"
	echo
	echo "GPG ile şifrelenmiş dosyayı açmak için:"
	echo -e "${GREEN}gpg --decrypt dot.enc.tar.gz | tar xzf -${NC}"
	echo
	echo "OpenSSL ile şifrelenmiş dosyayı açmak için:"
	echo -e "${GREEN}openssl enc -d -aes-256-cbc -salt -pbkdf2 -in dot.enc.tar.gz | tar xzf -${NC}"
	echo
	echo "İlerleme çubuğu görmek için komutların ortasına pv ekleyin:"
	echo -e "${GREEN}gpg --decrypt dot.enc.tar.gz | pv | tar xzf -${NC}"
}

# Yardım mesajı
usage() {
	echo "Kullanım: $0 [-d] [-e|-a] {backup|restore|list|cron|manual}"
	echo
	echo "Komutlar:"
	echo "  backup  : Dot dosyalarını yedekle ve şifrele"
	echo "  restore : Şifrelenmiş yedeği geri yükle"
	echo "  list    : Yedeklenecek dosyaları listele"
	echo "  cron    : Cronjob kurulumu"
	echo "  manual  : Manuel açma komutlarını göster"
	echo
	echo "Seçenekler:"
	echo "  -d      : Yedekleme sonrası orijinal tar dosyasını sil"
	echo "  -e      : GPG ile şifrele (manuel parola ile)"
	echo "  -a      : Age ile şifrele (public key ile)"
	echo "  -h      : Bu yardım mesajını göster"
	exit 1
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
	local age_key="$HOME/.config/sops/age/keys.txt"

	if [ "$USE_GPG" = "true" ]; then
		# GPG ile şifreli tar oluşturma
		echo "GPG şifreleme için parola girin:"
		tar czf - "${source_files[@]}" 2>/dev/null |
			pv -s "$total_size" |
			gpg --symmetric --cipher-algo AES256 --output "$BACKUP_DIR/$ENCRYPTED_FILE" -
	elif [ "$USE_AGE" = "true" ]; then
		# Age ile şifreli tar oluşturma
		if [ -f "$age_key" ]; then
			tar czf - "${source_files[@]}" 2>/dev/null |
				pv -s "$total_size" |
				age -R "$age_key" -o "$BACKUP_DIR/$ENCRYPTED_FILE"
		else
			error "Age public key bulunamadı ($age_key)"
		fi
	else
		# OpenSSL ile şifreli tar oluşturma
		echo "Arşiv için şifre girin:"
		read -s password
		echo
		echo "Şifreyi tekrar girin:"
		read -s password2
		echo

		if [ "$password" != "$password2" ]; then
			error "Şifreler eşleşmiyor!"
		fi

		tar czf - "${source_files[@]}" 2>/dev/null |
			pv -s "$total_size" |
			openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$password" -out "$BACKUP_DIR/$ENCRYPTED_FILE"
	fi
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
	local cron_cmd="0 0 * * * $script_path backup > $LOG_DIR/cron_backup.log 2>&1"

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
	local age_key="$HOME/.config/sops/age/keys.txt"

	# Şifre çözme ve arşiv içeriğini görüntüleme
	if file "$ENCRYPTED_FILE" | grep -q "GPG"; then
		success "GPG şifresi çözülüyor..."
		gpg --decrypt "$ENCRYPTED_FILE" | tar tvf - || error "GPG şifre çözme başarısız"
	elif file "$ENCRYPTED_FILE" | grep -q "age"; then
		success "Age şifresi çözülüyor..."
		if [ -f "$age_key" ]; then
			age -d -i "$age_key" -o - "$ENCRYPTED_FILE" | tar tvf - || error "Age şifre çözme başarısız"
		else
			error "Age private key bulunamadı ($age_key)"
		fi
	else
		success "OpenSSL şifresi çözülüyor..."
		echo "Arşiv şifresini girin:"
		openssl enc -aes-256-cbc -d -salt -pbkdf2 -in "$ENCRYPTED_FILE" | tar tvf - || error "OpenSSL şifre çözme başarısız"
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
	elif file "$BACKUP_DIR/$ENCRYPTED_FILE" | grep -q "age"; then
		age -d -i "$age_key" -o - "$BACKUP_DIR/$ENCRYPTED_FILE" | pv | tar xzf - || error "Age ile geri yükleme başarısız"
	else
		echo "Arşiv şifresini girin:"
		openssl enc -aes-256-cbc -d -salt -pbkdf2 -in "$BACKUP_DIR/$ENCRYPTED_FILE" | pv | tar xzf - || error "OpenSSL ile geri yükleme başarısız"
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

# Parametre analizi
while getopts "deah" opt; do
	case $opt in
	d) DELETE_ORIGINAL=true ;;
	e) USE_GPG=true ;;
	a) USE_AGE=true ;;
	h) usage ;;
	\?) usage ;;
	esac
done
shift $((OPTIND - 1))

# Komut analizi
case "$1" in
"backup")
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
"manual")
	show_manual_commands
	;;
*)
	usage
	;;
esac
