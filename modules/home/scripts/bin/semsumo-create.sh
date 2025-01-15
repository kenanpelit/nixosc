#!/usr/bin/env bash

#######################################
# ... (mevcut yorum başlığı aynen kalacak)
#######################################

# Hata yönetimi
set -e

# Yapılandırma
config_file="${XDG_CONFIG_HOME:-$HOME/.config}/sem/config.json"
scripts_dir="$HOME/.nixosc/modules/home/scripts/start"
SEMSUMO_PATH="semsumo"

# Geçici dizin yönetimi
TMP_BASE="${TMPDIR:-/tmp}/sem"
mkdir -p "$TMP_BASE"
chmod 700 "$TMP_BASE"

# Dizin kontrol
if [[ ! -f "$config_file" ]]; then
	echo "Config dosyası bulunamadı: $config_file"
	exit 1
fi

# Scripts dizinini oluştur
mkdir -p "$scripts_dir"
echo "Script oluşturma başlıyor..."
echo "--------------------------"

# Her profil için scriptleri oluştur
jq -r '.sessions | keys[]' "$config_file" | while read -r profile; do
	echo "Profil işleniyor: $profile"

	# Her mod için ayrı script
	for mode in always never default; do
		script_file="$scripts_dir/start-${profile,,}-${mode}.sh"
		cat >"$script_file" <<EOF
#!/usr/bin/env bash
# Geçici dizin ayarı
export TMPDIR="$TMP_BASE"
# Hata yönetimi
set -e

$SEMSUMO_PATH start $profile $mode
EOF
		chmod +x "$script_file"
		echo "  ✓ Oluşturuldu: start-${profile,,}-${mode}.sh"
	done
	echo ""
done

echo "--------------------------"
echo "Script oluşturma tamamlandı!"
echo "Kullanım örnekleri:"
echo "  $scripts_dir/start-zen-kenp-always.sh"
echo "  $scripts_dir/start-zen-kenp-never.sh"
echo "  $scripts_dir/start-zen-kenp-default.sh"
