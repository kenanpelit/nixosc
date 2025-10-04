# modules/home/scripts/bin/rofi-launcher.sh
#!/usr/bin/env bash
# ==============================================================================
# Rofi Uygulama Başlatıcı
# ==============================================================================
# Bu script, rofi'yi uygulama başlatıcı olarak kullanır ve aşağıdaki özellikleri sağlar:
# - Uygulama arama ve başlatma (drun)
# - Komut çalıştırma (run)
# - Pencere değiştirme (window)
# - Dosya gezgini (filebrowser)
# - SSH bağlantıları (ssh)
# - Favori uygulamalar için frekans tabanlı sıralama (frecency)
# ==============================================================================

if ! command -v rofi-frecency &>/dev/null; then
	echo "Uyarı: rofi-frecency bulunamadı. Frekans özelliği çalışmayabilir."
fi

# Tema ve konfigürasyon dosyaları için kontrol
CONFIG_DIR="$HOME/.config/rofi"
THEME_FILE="$CONFIG_DIR/themes/launcher.rasi"

# Özel tema kullanımı (varsa)
THEME_PARAM=""
if [ -f "$THEME_FILE" ]; then
	THEME_PARAM="-theme $THEME_FILE"
fi

# ==============================================================================
# Rofi Başlatma
# ==============================================================================
SELECTED=$(rofi \
	-show combi \
	-combi-modi 'drun,run,window,filebrowser,ssh' \
	-modi "combi,drun,run,window,filebrowser,ssh" \
	-show-icons \
	-matching fuzzy \
	-sort \
	-sorting-method "fzf" \
	-drun-match-fields "name,generic,exec,categories,keywords" \
	-window-match-fields "title,class,name,desktop" \
	-drun-display-format "{name} [<span weight='light' size='small'><i>({generic})</i></span>]" \
	$THEME_PARAM)

# ==============================================================================
# Seçim İşleme
# ==============================================================================
if [ -n "$SELECTED" ]; then
	# Seçilen uygulamayı frekans listesine ekle
	if command -v rofi-frecency &>/dev/null; then
		rofi-frecency --add "$SELECTED"
	fi

	# Seçilen uygulamayı çalıştır (arka planda çalıştır ve hataları yönlendir)
	eval "$SELECTED" >/dev/null 2>&1 &

	# Başlatma durumunu kontrol et
	if [ $? -ne 0 ]; then
		notify-send "Rofi Launcher" "Uygulama başlatılırken hata oluştu: $SELECTED" -i error
	fi
fi

exit 0
