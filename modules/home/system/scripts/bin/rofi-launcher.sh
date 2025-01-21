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
	-drun-display-format "{name} [<span weight='light' size='small'><i>({generic})</i></span>]")

# ==============================================================================
# Seçim İşleme
# ==============================================================================
if [ -n "$SELECTED" ]; then
	# Seçilen uygulamayı frekans listesine ekle
	rofi-frecency --add "$SELECTED"
	# Seçilen uygulamayı çalıştır
	eval "$SELECTED"
fi
