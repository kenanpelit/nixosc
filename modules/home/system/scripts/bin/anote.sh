#!/usr/bin/env bash

# =================================================================
# anote.sh - Terminal Tabanlı Not Alma ve Snippet Yönetim Sistemi
# =================================================================
#
# Bu betik, terminal üzerinden hızlı not alma, kodlama snippet'leri ve
# cheatsheet'leri organize etmek için geliştirilmiş bir araçtır.
# fzf ile interaktif arama, bat ile güzel görüntüleme ve çeşitli
# terminal araçlarıyla zengin bir deneyim sunar.
#
# Geliştiren: Kenan Pelit
# Repository: github.com/kenanpelit

# İlham kaynağı: notekami projesi (https://github.com/gotbletu/fzf-nova)
# Versiyon: 2.1
# Lisans: GPLv3

# Katı mod - hataları daha iyi yakalamak için
set -eo pipefail

# =================================================================
# KONFİGÜRASYON DEĞİŞKENLERİ
# =================================================================

# Temel dizinler
ANOTE_DIR="${ANOTE_DIR:-$HOME/.anote}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/anote"
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/anote/config"

# Alt dizinler
CHEAT_DIR="$ANOTE_DIR/cheats"
SNIPPETS_DIR="$ANOTE_DIR/snippets"
SCRATCH_DIR="$ANOTE_DIR/scratch"

# Varsayılan ayarlar
EDITOR="${EDITOR:-nvim}"
TIMESTAMP="$(date +%Y-%m-%d\ %H:%M:%S)"
SCRATCH_FILE="$SCRATCH_DIR/$(date +%Y-%m).txt"
HISTORY_FILE="$CACHE_DIR/history.json"
CLEANUP_INTERVAL=$((7 * 24 * 60 * 60)) # 7 gün

# Varsayılan fzf ayarları
export FZF_DEFAULT_OPTS="-e -i --info=hidden --layout=reverse --scroll-off=5 --tiebreak=index"
FZF_DEFAULT_OPTS+=" --bind 'home:first,end:last,ctrl-k:preview-page-up,ctrl-j:preview-page-down'"
FZF_DEFAULT_OPTS+=" --bind 'ctrl-y:preview-up,ctrl-e:preview-down,ctrl-/:change-preview-window(hidden|)'"

# Varsa konfigürasyon dosyasını yükle
if [[ -f "$CONFIG_FILE" ]]; then
	# shellcheck source=/dev/null
	source "$CONFIG_FILE"
fi

# =================================================================
# YARDIMCI FONKSİYONLAR
# =================================================================

# Yardım menüsü
show_anote_help() {
	cat <<'EOF'
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                        ANOTE - Terminal Not Yöneticisi                        ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

  AÇIKLAMA:   Terminal üzerinde basit cheatsheet, snippet, karalama ve not alma
              yöneticisi.

  BAĞIMLILIKLAR:  fzf, bat, jq, grep, sed, awk ve bir clipboard aracı
                  (xsel, xclip, wl-copy, pbcopy, veya tmux)

KULLANIM: anote.sh <seçenekler>

SEÇENEKLER:
  Seçenek olmadan çalıştır  → İnteraktif menüyü başlatır
  -a, --auto <metin>        → Not defterine otomatik giriş ekler
  -A, --audit               → Not defterini metin editöründe açar
  -e, --edit [dosya]        → Dosya düzenler veya oluşturur
  -l, --list                → Tüm dosyaları listeler
  -d, --dir                 → Tüm dizinleri listeler
  -p, --print [dosya]       → Dosya içeriğini gösterir
  -s, --search [kelime]     → Tüm dosyalarda arar
  -t, --snippet             → Snippet'i panoya kopyalar ve gösterir
  -i, --info                → Bu bilgi sayfasını gösterir
  -h, --help                → Bu yardım sayfasını gösterir
  -S, --single-snippet      → Tek satır snippet modunu başlatır
  -M, --multi-snippet       → Çok satırlı snippet modunu başlatır
  -c, --config              → Konfigürasyon dosyasını düzenler
      --scratch               → Karalama defterini açar

TUŞ KISAYOLLARI (FZF içinde):
  Tab / Shift+Tab          → Aşağı/yukarı gezinme
  Ctrl+K / Ctrl+J          → Önizleme sayfası yukarı/aşağı
  Ctrl+E                   → Seçili dosyayı düzenle
  Ctrl+F                   → Dosyayı düzenle
  Ctrl+R                   → Listeyi yenile
  Esc                      → Geri/Çıkış
  Enter                    → Seç/Uygula

ÖRNEKLER:
  anote.sh                          → İnteraktif menü
  anote.sh -e notlar/linux/awk.sh   → Belirli bir dosyayı düzenle
  anote.sh -a "Bugün yapılacaklar"  → Not defterine hızlıca not ekle
  anote.sh -s "regexp"              → "regexp" kelimesini ara
  anote.sh -t                       → Snippet kopyalama modunu başlat

KAYIT DİZİNİ: ~/.anote
EOF
}

# Bilgi menüsü (snippet formatları hakkında)
show_snippet_info() {
	cat <<'EOF'
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                         ANOTE - Snippet Formatları                            ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

SNIPPET FORMATLARI:

1. Tek-satır snippetler (snippetrc dosyası içinde):
   komut_adı;; komut açıklaması

   Örnek:
   ls -la;; Tüm dosyaları detaylı göster
   find . -name "*.txt";; Metin dosyalarını bul

2. Çok-satırlı snippetler (ayrı dosyalarda):
   ####; Snippet Başlığı
   
   Snippet içeriği buraya gelir.
   Birden fazla satır olabilir.
   
   ###; Açıklama (opsiyonel)
   Snippet hakkında açıklama yazabilirsiniz.
   
   ##; Kullanım Örnekleri (opsiyonel)
   Örnek kullanımlar burada gösterilebilir.

NOTLAR:
- ####; ile başlayan satırlar snippet başlığını belirtir
- ###; ile başlayan satırlar açıklama bölümünü belirtir
- ##; ile başlayan satırlar örnek kullanım bölümünü belirtir
- Bu işaretleyiciler panoya kopyalanmaz, sadece içerik kopyalanır

ÖNERİLER:
- Her snippet için anlamlı başlıklar kullanın
- Karmaşık komutlar için açıklama ekleyin
- Örneklerle kullanımı gösterin
EOF
}

# Bağımlılık kontrolü
check_dependencies() {
	local missing_deps=()
	local required_deps=("fzf" "bat" "jq" "grep" "sed" "awk")

	for dep in "${required_deps[@]}"; do
		if ! command -v "$dep" &>/dev/null; then
			missing_deps+=("$dep")
		fi
	done

	# En az bir clipboard yardımcı programı gerekli
	if ! command -v wl-copy &>/dev/null &&
		! command -v xsel &>/dev/null &&
		! command -v xclip &>/dev/null &&
		! command -v pbcopy &>/dev/null &&
		! command -v clip &>/dev/null &&
		[[ "$TERM_PROGRAM" != tmux ]] && [[ -z "$TMUX" ]]; then
		missing_deps+=("wl-copy/xclip/xsel/pbcopy/clip/tmux")
	fi

	if [[ ${#missing_deps[@]} -gt 0 ]]; then
		echo "HATA: Aşağıdaki bağımlılıklar eksik:" >&2
		printf "  - %s\n" "${missing_deps[@]}" >&2
		echo "Lütfen bu paketleri yükleyin ve tekrar deneyin." >&2
		exit 1
	fi
}

# Dizinleri oluştur
create_required_directories() {
	mkdir -p "$ANOTE_DIR" "$CHEAT_DIR" "$SNIPPETS_DIR" "$SCRATCH_DIR" "$CACHE_DIR"

	# Dizinler boş ise örnek dosyalar oluştur
	if [[ ! "$(ls -A "$SNIPPETS_DIR" 2>/dev/null)" ]]; then
		echo "####; Örnek Bash Komutu" >"$SNIPPETS_DIR/ornek.sh"
		echo "" >>"$SNIPPETS_DIR/ornek.sh"
		echo "echo \"Merhaba, dünya!\"" >>"$SNIPPETS_DIR/ornek.sh"
		echo "" >>"$SNIPPETS_DIR/ornek.sh"
		echo "###; Açıklama" >>"$SNIPPETS_DIR/ornek.sh"
		echo "Bu basit bir bash komutu örneğidir." >>"$SNIPPETS_DIR/ornek.sh"
	fi

	if [[ ! "$(ls -A "$CHEAT_DIR" 2>/dev/null)" ]]; then
		echo "ls -la;; Dizin içeriğini ayrıntılı listele" >"$CHEAT_DIR/snippetrc"
		echo "cd -;; Önceki dizine git" >>"$CHEAT_DIR/snippetrc"
		echo "mkdir -p;; İç içe dizinler oluştur" >>"$CHEAT_DIR/snippetrc"
	fi
}

# Kayıt işlemleri
update_history() {
	local dir="$1"
	local file="$2"
	local timestamp=$(date +%s)
	local temp_file="$CACHE_DIR/history.tmp"

	# history.json dosyası yoksa oluştur
	[[ ! -f "$HISTORY_FILE" ]] && echo "{}" >"$HISTORY_FILE"

	# Dizin ve dosya yollarında özel karakterleri escape et
	local esc_dir
	local esc_file
	esc_dir=$(echo "$dir" | sed 's/\\/\\\\/g; s/"/\\"/g')
	esc_file=$(echo "$file" | sed 's/\\/\\\\/g; s/"/\\"/g')

	# Dizin geçmişte varsa güncelle, yoksa ekle
	if jq -e "has(\"$esc_dir\")" "$HISTORY_FILE" >/dev/null; then
		jq --arg dir "$esc_dir" \
			--arg file "$esc_file" \
			--arg time "$timestamp" \
			'.[$dir] = (.[$dir] | map(select(.file != $file)) + [{
                "file": $file,
                "time": $time | tonumber
             }] | sort_by(-.time)[0:100])' "$HISTORY_FILE" >"$temp_file"
	else
		jq --arg dir "$esc_dir" \
			--arg file "$esc_file" \
			--arg time "$timestamp" \
			'.[$dir] = [{
                "file": $file,
                "time": $time | tonumber
            }]' "$HISTORY_FILE" >"$temp_file"
	fi

	mv "$temp_file" "$HISTORY_FILE"
}

# Geçmiş dosyaları sıralar (en son kullanılanlar önce)
get_sorted_files() {
	local dir="$1"
	local recent_files=""

	# Geçmişte kayıtlı dosyaları al
	if [[ -f "$HISTORY_FILE" ]] && jq -e "has(\"$dir\")" "$HISTORY_FILE" >/dev/null 2>&1; then
		recent_files=$(jq -r --arg dir "$dir" '.[$dir][].file' "$HISTORY_FILE" 2>/dev/null)
	fi

	# Önce geçmiş dosyaları göster
	while IFS= read -r file; do
		[[ -f "$file" ]] && echo "$file"
	done < <(echo "$recent_files")

	# Sonra diğer dosyaları göster (geçmişte olmayanlar)
	find "$dir" -type f 2>/dev/null | while IFS= read -r file; do
		if [[ -n "$recent_files" ]]; then
			echo "$recent_files" | grep -Fxq "$file" || echo "$file"
		else
			echo "$file"
		fi
	done
}

# Geçmiş temizleme (silinmiş dosyaları geçmişten kaldır)
clean_history() {
	local temp_file="$CACHE_DIR/history.tmp"

	if [[ -f "$HISTORY_FILE" ]]; then
		# Var olmayan dosya referanslarını temizle
		jq 'to_entries | map(
           .value = (.value | map(select(.file | test("^/") | not or (.file | test("^" + env.HOME) | not) or ((.file) | test("e")))))
           ) | from_entries' "$HISTORY_FILE" >"$temp_file"

		# Düzeltilmiş kontrol: gerçek dosyaları tut
		jq 'to_entries | map(
           .value = (.value | map(select(.file | halt_error(1) as $_ | input_filename | capture("^(?<fn>.*)$") | .fn as $fn | $fn | test("e") )))
           ) | from_entries' "$HISTORY_FILE" >"$temp_file"

		if [[ $? -eq 0 ]]; then
			mv "$temp_file" "$HISTORY_FILE"
		else
			# jq hatası durumunda boş geçmişle başla
			echo "{}" >"$HISTORY_FILE"
		fi

		# Boş dizin kayıtlarını temizle
		jq 'to_entries | map(select(.value != [])) | from_entries' "$HISTORY_FILE" >"$temp_file"
		mv "$temp_file" "$HISTORY_FILE"
	fi
}

# Önbellek bakımı
maintain_cache() {
	local last_clean_file="$CACHE_DIR/last_clean"
	local current_time=$(date +%s)

	# Düzenli aralıklarla cache temizliği yap
	if [[ ! -f "$last_clean_file" ]] ||
		[[ $((current_time - $(cat "$last_clean_file"))) -gt $CLEANUP_INTERVAL ]]; then
		clean_history
		echo "$current_time" >"$last_clean_file"
	fi
}

# Önbellek güncelleme (snippet kullanım geçmişi için)
update_cache() {
	local item="$1"
	local cache_file="$2"

	# Cache dosyasının varlığından emin ol
	[[ ! -f "$cache_file" ]] && touch "$cache_file"

	# Girdiyi en başa ekle ve tekrarları kaldır
	echo "$item" | cat - "$cache_file" | awk '!seen[$0]++' | head -n 100 >"$CACHE_DIR/temp_cache"
	mv "$CACHE_DIR/temp_cache" "$cache_file"
}

# Panoya kopyalama (platform bağımsız ve geliştirilmiş)
copy_to_clipboard() {
	local content="$1"
	local success=false
	local clipboard_tool=""
	local error_output=""

	# Clipboard araçlarını ve uygunluklarını kontrol et
	if [[ -n "$WAYLAND_DISPLAY" ]] && command -v wl-copy >/dev/null 2>&1; then
		clipboard_tool="wl-copy"
		if printf '%s' "$content" | wl-copy 2>/dev/null; then
			success=true
		else
			error_output="wl-copy hatası"
		fi
	elif [[ -n "$DISPLAY" ]]; then
		if command -v xsel >/dev/null 2>&1; then
			clipboard_tool="xsel"
			if printf '%s' "$content" | xsel -b 2>/dev/null; then
				success=true
			else
				error_output="xsel hatası"
			fi
		elif command -v xclip >/dev/null 2>&1; then
			clipboard_tool="xclip"
			if printf '%s' "$content" | xclip -selection clipboard -r 2>/dev/null; then
				success=true
			else
				error_output="xclip hatası"
			fi
		fi
	elif [[ "$OSTYPE" == "darwin"* ]] && command -v pbcopy >/dev/null 2>&1; then
		clipboard_tool="pbcopy"
		if printf '%s' "$content" | pbcopy 2>/dev/null; then
			success=true
		else
			error_output="pbcopy hatası"
		fi
	elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]] && command -v clip >/dev/null 2>&1; then
		clipboard_tool="clip"
		if printf '%s' "$content" | clip 2>/dev/null; then
			success=true
		else
			error_output="clip hatası"
		fi
	fi

	# Tmux içindeyse tmux tamponuna kopyala (ek güvenlik olarak)
	if [[ "$TERM_PROGRAM" == "tmux" || -n "$TMUX" ]]; then
		if printf '%s' "$content" | tmux load-buffer - 2>/dev/null; then
			# Diğer yöntemler başarısız olduysa tmux'u kullan
			if [[ "$success" != "true" ]]; then
				success=true
				clipboard_tool="tmux buffer"
			fi
		fi
	fi

	# Hiçbir clipboard aracı bulunamadı veya çalışmadıysa, dosyaya yaz
	if [[ "$success" != "true" ]]; then
		mkdir -p "$CACHE_DIR"
		printf '%s' "$content" >"$CACHE_DIR/clipboard_content"
		echo "⚠️ Panoya kopyalama başarısız! Kullanılabilir clipboard aracı bulunamadı."
		echo "⚠️ İçerik $CACHE_DIR/clipboard_content dosyasına yazıldı."
		echo "⚠️ Hata: $error_output"
		# Kopyalanamadığını belirtmek için hata kodu döndür
		return 1
	fi

	# İçerik uzunluğuna göre bildirim şekli
	local content_length=${#content}
	local preview=""

	if [[ $content_length -gt 100 ]]; then
		# Uzun içerik için ilk 50 ve son 30 karakteri göster
		preview=$(echo "${content:0:50}...${content: -30}" | tr -d '\n')
	else
		# Kısa içerik için tamamını göster (yeni satırları temizleyerek)
		preview=$(echo "$content" | tr -d '\n')
	fi

	echo "✓ İçerik $(tput setaf 2)başarıyla$(tput sgr0) panoya kopyalandı (${clipboard_tool})"
	echo "$(tput setaf 8)Önizleme: ${preview}$(tput sgr0)"

	# Başarılı durumda 0 dön
	return 0
}

# =================================================================
# KULLANICI ARAYÜZÜ FONKSİYONLARI
# =================================================================

# Ana menü
list_anote_options() {
	cat <<EOF
snippet| -- snippets'ten panoya kopyala
single| -- tek satır snippet modunu başlat
multi| -- çok satırlı snippet modunu başlat
cheats| -- cheats'ten panoya kopyala
copy| -- dosya içeriğini panoya kopyala  
edit| -- dosyayı düzenle
create| -- yeni dosya oluştur
search| -- tümünde ara
scratch| -- karalama kağıdı
info| -- bilgi sayfası
EOF
}

# Ana TUI (Terminal Kullanıcı Arayüzü)
show_anote_tui() {
	local selected
	selected=$(list_anote_options | column -s '|' -t |
		fzf --header 'Esc:çıkış C-n/p:aşağı/yukarı Enter:seç' \
			--prompt="anote > " | cut -d ' ' -f1)

	[[ -z "$selected" ]] && exit 0

	case $selected in
	snippet)
		snippet_mode
		;;
	single)
		single_mode
		;;
	multi)
		multi_mode
		;;
	cheats)
		cheats_mode
		;;
	copy)
		copy_mode
		;;
	edit)
		edit_mode
		;;
	create)
		create_mode
		;;
	search)
		search_mode
		;;
	scratch)
		scratch_mode
		;;
	info)
		show_snippet_info | less -R
		;;
	esac
}

# Snippet Modu - çok satırlı snippet seçimi ve kopyalama
snippet_mode() {
	local selected
	while true; do
		selected=$(grep -nrH '^####; ' "$SNIPPETS_DIR"/* 2>/dev/null | sort -t: -k1,1 |
			fzf -d ' ' --with-nth 2.. \
				--prompt="anote > snippet: " \
				--bind "ctrl-f:execute:$EDITOR \$(echo {} | cut -d: -f1)" \
				--bind "ctrl-e:execute:$EDITOR +\$(echo {} | cut -d: -f2) \$(echo {} | cut -d: -f1)" \
				--bind "ctrl-r:reload(grep -nrH '^####; ' $SNIPPETS_DIR/*)" \
				--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
				--header 'ESC:Geri C-e:satır-düzenle C-f:dosya-düzenle' \
				--preview-window 'down' \
				--preview '
                   file=$(echo {} | cut -d: -f1)
                   line=$(echo {} | cut -d: -f2)
                   title=$(echo {} | cut -d " " -f2-)
                   ext=${file##*.}
                   awk -v title="$title" "BEGIN{RS=\"\"} \$0 ~ title" "$file" | 
                       bat --color=always -pp -l "$ext" 2>/dev/null || 
                       awk -v title="$title" "BEGIN{RS=\"\"} \$0 ~ title" "$file"
               ')

		# Geri gitme isteği geldi mi kontrol et
		if [[ -f /tmp/anote_nav ]]; then
			rm /tmp/anote_nav
			show_anote_tui
			break
		fi

		[[ -z "$selected" ]] && exit 0

		# Seçilen snippet'i işle
		file_name="$(echo "$selected" | cut -d: -f1)"
		dir=$(dirname "$file_name")
		update_history "$dir" "$file_name"
		snippet_title="$(echo "$selected" | cut -d " " -f2-)"

		# Snippet içeriğini ayıkla (başlık ve açıklama satırlarını çıkar)
		selected=$(awk -v title="$snippet_title" 'BEGIN{RS=""} $0 ~ title' "$file_name" |
			sed -e '/^####;/d' -e '/^###;/d' -e '/^##;/d')

		# Panoya kopyala
		copy_to_clipboard "$selected"

		# Önizleme göster
		echo -e "\n--- Kopyalanan Snippet ---"
		if command -v bat >/dev/null 2>&1; then
			echo "$selected" | bat --color=always -pp -l "${file_name##*.}" 2>/dev/null || echo "$selected"
		else
			echo "$selected"
		fi
		echo -e "\n"

		read -n 1 -p "Başka bir snippet seçmek ister misiniz? (e/h) [h]: " yn
		echo
		[[ -z "$yn" ]] && yn="h" # Enter'a basılırsa varsayılan 'h' olsun
		[[ "$yn" != "e" && "$yn" != "E" ]] && break
	done
}

# Tek Satır Snippet Modu
single_mode() {
	local SNIPPET_CACHE="$CACHE_DIR/snippetrc"
	local SNIPPET_FILE="$CHEAT_DIR/snippetrc"
	touch "$SNIPPET_FILE" "$SNIPPET_CACHE"

	local selected
	selected="$(cat "$SNIPPET_CACHE" "$SNIPPET_FILE" 2>/dev/null | awk '!seen[$0]++' |
		sed '/^$/d' |
		fzf -e -i \
			--prompt="Snippet > " \
			--info=default \
			--layout=reverse \
			--tiebreak=index \
			--header="CTRL+E: Düzenle | ESC: Çıkış | ENTER: Kopyala" \
			--bind "ctrl-e:execute($EDITOR $SNIPPET_FILE < /dev/tty > /dev/tty)" |
		sed -e 's/;;.*$//' |
		sed 's/^[ \t]*//;s/[ \t]*$//' |
		tr -d '\n')"

	[[ -z "$selected" ]] && exit 0

	update_cache "$selected" "$SNIPPET_CACHE"
	copy_to_clipboard "$selected"

	# Kullanıcıya geri bildirim
	echo -e "\nPanoya kopyalanan: $selected"
	sleep 1
}

# Çok Satırlı Snippet Dosyası Seçme Modu
multi_mode() {
	local MULTI_CACHE="$CACHE_DIR/multi"
	mkdir -p "$CACHE_DIR"
	touch "$MULTI_CACHE"

	while true; do
		local selected
		selected="$({
			cat "$MULTI_CACHE" 2>/dev/null
			find "$CHEAT_DIR" -type f -not -name ".*" 2>/dev/null
		} |
			awk '!seen[$0]++' |
			sort |
			fzf -e -i \
				--delimiter / \
				--with-nth -2,-1 \
				--preview 'bat --color=always -pp {} 2>/dev/null || cat {}' \
				--preview-window='right:60%:wrap' \
				--prompt="Metin bloğu > " \
				--header="ESC: Çıkış | ENTER: Kopyala | CTRL+E: Düzenle" \
				--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
				--bind "ctrl-e:execute($EDITOR {} < /dev/tty > /dev/tty)")"

		if [[ -f /tmp/anote_nav ]]; then
			rm /tmp/anote_nav
			show_anote_tui
			break
		fi

		[[ -z "$selected" ]] && exit 0

		dir=$(dirname "$selected")
		update_history "$dir" "$selected"
		update_cache "$selected" "$MULTI_CACHE"

		# Dosyanın içeriğini panoya kopyala
		content="$(cat "$selected")"
		copy_to_clipboard "$content"

		# Önizleme göster
		echo -e "\n--- Kopyalanan İçerik ---"
		if command -v bat >/dev/null 2>&1; then
			bat --color=always -pp "$selected" 2>/dev/null || cat "$selected"
		else
			cat "$selected"
		fi
		echo -e "\n"

		read -n 1 -p "Başka bir dosya seçmek ister misiniz? (e/h) [h]: " yn
		echo
		[[ -z "$yn" ]] && yn="h" # Enter'a basılırsa varsayılan 'h' olsun
		[[ "$yn" != "e" && "$yn" != "E" ]] && break
	done
}

# Cheats Modu (cheatsheet'ten kopyalama)
cheats_mode() {
	while true; do
		selected=$(grep -nrH '^####; ' "$CHEAT_DIR"/* 2>/dev/null | sort -t: -k1,1 |
			fzf -d ' ' --with-nth 2.. \
				--prompt="anote > cheat: " \
				--bind "ctrl-f:execute:$EDITOR \$(echo {} | cut -d: -f1)" \
				--bind "ctrl-e:execute:$EDITOR +\$(echo {} | cut -d: -f2) \$(echo {} | cut -d: -f1)" \
				--bind "ctrl-r:reload(grep -nrH '^####; ' $CHEAT_DIR/*)" \
				--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
				--header 'ESC:Geri C-e:satır-düzenle C-f:dosya-düzenle' \
				--preview-window 'down' \
				--preview '
                   file=$(echo {} | cut -d: -f1)
                   line=$(echo {} | cut -d: -f2)
                   title=$(echo {} | cut -d " " -f2-)
                   ext=${file##*.}
                   awk -v title="$title" "BEGIN{RS=\"\"} \$0 ~ title" "$file" |
                       bat --color=always -pp -l "$ext" 2>/dev/null || 
                       awk -v title="$title" "BEGIN{RS=\"\"} \$0 ~ title" "$file"
               ')

		if [[ -f /tmp/anote_nav ]]; then
			rm /tmp/anote_nav
			show_anote_tui
			break
		fi

		[[ -z "$selected" ]] && exit 0

		file_name="$(echo "$selected" | cut -d: -f1)"
		dir=$(dirname "$file_name")
		update_history "$dir" "$file_name"
		snippet_title="$(echo "$selected" | cut -d " " -f2-)"

		selected=$(awk -v title="$snippet_title" 'BEGIN{RS=""} $0 ~ title' "$file_name" |
			sed -e '/^####;/d' -e '/^###;/d' -e '/^##;/d')

		copy_to_clipboard "$selected"

		# Önizleme göster
		echo -e "\n--- Kopyalanan Cheat ---"
		if command -v bat >/dev/null 2>&1; then
			echo "$selected" | bat --color=always -pp -l "${file_name##*.}" 2>/dev/null || echo "$selected"
		else
			echo "$selected"
		fi
		echo -e "\n"

		read -n 1 -p "Başka bir snippet seçmek ister misiniz? (e/h) [h]: " yn
		echo
		[[ -z "$yn" ]] && yn="h" # Enter'a basılırsa varsayılan 'h' olsun
		[[ "$yn" != "e" && "$yn" != "E" ]] && break
	done
}

# Dosya İçeriği Kopyalama Modu
copy_mode() {
	while true; do
		selected=$(
			find "$ANOTE_DIR"/ -type f 2>/dev/null | sort |
				fzf -d / --with-nth -2.. \
					--preview 'bat --color=always -pp {} 2>/dev/null || cat {}' \
					--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
					--header 'ESC:Geri ENTER:Kopyala' \
					--prompt="anote > kopyala: "
		)
		if [[ -f /tmp/anote_nav ]]; then
			rm /tmp/anote_nav
			show_anote_tui
			break
		fi
		[[ -z "$selected" ]] && exit 0
		dir=$(dirname "$selected")
		update_history "$dir" "$selected"

		# Dosya içeriğini oku ve panoya kopyala
		content="$(cat "$selected")"
		copy_to_clipboard "$content"

		# Önizleme göster
		echo -e "\n--- Kopyalanan İçerik ---"
		if command -v bat >/dev/null 2>&1; then
			bat --color=always -pp "$selected" 2>/dev/null || cat "$selected"
		else
			cat "$selected"
		fi
		echo -e "\n"

		read -n 1 -p "Başka bir dosya seçmek ister misiniz? (e/h) [h]: " yn
		echo
		[[ -z "$yn" ]] && yn="h" # Enter'a basılırsa varsayılan 'h' olsun
		[[ "$yn" != "e" && "$yn" != "E" ]] && break
	done
}

# Dosya Düzenleme Modu
edit_mode() {
	while true; do
		if [[ "$TERM_PROGRAM" = tmux ]] || [[ -n "$TMUX" ]]; then
			selected=$(find "$ANOTE_DIR"/ -type f 2>/dev/null | sort |
				fzf -m -d / --with-nth -2.. \
					--bind "tab:down,shift-tab:up" \
					--bind "shift-delete:execute:rm -i {} >/dev/tty" \
					--bind "ctrl-v:execute:qmv -f do {} >/dev/tty 2>/dev/null || echo 'qmv bulunamadı'" \
					--bind "ctrl-r:reload:find '$ANOTE_DIR'/ -type f | sort" \
					--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
					--header 'ESC:Geri C-v:yeniden-adlandır C-r:yenile S-del:sil' \
					--preview 'bat --color=always -pp {} 2>/dev/null || cat {}' \
					--prompt="anote > düzenle: ")
			if [[ -f /tmp/anote_nav ]]; then
				rm /tmp/anote_nav
				show_anote_tui
				break
			fi
			[[ -z "$selected" ]] && exit 0
			# Çoklu seçimde her dosyayı ayrı pencerede düzenle
			while IFS= read -r line; do
				filename="$(basename "$line")"
				tmux new-window -n "${filename}" "$EDITOR $line"
			done < <(echo "$selected")
		else
			# Önce bir dizin veya dosya yolu alın
			read -e -p "Dosya yolu (tab ile tamamlayabilirsiniz): " -i "$ANOTE_DIR/" file_path

			if [[ -d "$file_path" ]]; then
				# Eğer bir dizin seçildiyse, o dizindeki dosyaları listele
				selected=$(find "$file_path" -type f 2>/dev/null | sort |
					fzf -d / --with-nth -2.. \
						--preview 'bat --color=always -pp {} 2>/dev/null || cat {}' \
						--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
						--header 'ESC:Geri ENTER:Düzenle' \
						--prompt="anote > düzenle: ")
			elif [[ -f "$file_path" ]]; then
				# Eğer doğrudan bir dosya seçildiyse, o dosyayı kullan
				selected="$file_path"
			else
				# Ne dizin ne de dosya ise
				if [[ ! -e "$(dirname "$file_path")" ]]; then
					mkdir -p "$(dirname "$file_path")"
					selected="$file_path"
				else
					selected="$file_path"
				fi
			fi

			if [[ -f /tmp/anote_nav ]]; then
				rm /tmp/anote_nav
				show_anote_tui
				break
			fi

			[[ -z "$selected" ]] && exit 0
			dir=$(dirname "$selected")
			update_history "$dir" "$selected"
			"$EDITOR" "$selected"
		fi
		break
	done
}

# Dosya Arama Modu
search_mode() {
	while true; do
		selected=$(grep -rnv '^[[:space:]]*$' "$ANOTE_DIR"/* 2>/dev/null |
			fzf -d : --with-nth 1,2,3 \
				--prompt="anote > ara: " \
				--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
				--header "ESC:Geri ENTER:Seç" \
				--preview '
                    file=$(echo {} | cut -d: -f1)
                    line=$(echo {} | cut -d: -f2)
                    bat --color=always --highlight-line "$line" "$file" 2>/dev/null || 
                    cat "$file" | nl -w4 -s": " | grep -A 5 -B 5 "^[ ]*$line:"
                ')

		if [[ -f /tmp/anote_nav ]]; then
			rm /tmp/anote_nav
			show_anote_tui
			break
		fi

		[[ -z "$selected" ]] && exit 0
		file_name=$(echo "$selected" | cut -d ':' -f1)
		file_num=$(echo "$selected" | cut -d ':' -f2)
		dir=$(dirname "$file_name")
		update_history "$dir" "$file_name"

		if [[ "$TERM_PROGRAM" = tmux ]] || [[ -n "$TMUX" ]]; then
			tmux new-window -n "ara-sonucu" "$EDITOR +$file_num $file_name"
		else
			"$EDITOR" +"$file_num" "$file_name"
		fi
		break
	done
}

# Yeni Dosya Oluşturma Modu - Geliştirilmiş ve Kullanıcı Dostu
create_mode() {
	local file_path
	local file_ext
	local dir_path

	while true; do
		clear
		echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
		echo "┃                             YENİ DOSYA OLUŞTUR                               ┃"
		echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
		echo
		echo "  1) Tam dosya yolu gir (tab ile tamamlanabilir)"
		echo "  2) Önce dizin seç, sonra dosya adı gir"
		echo "  3) Sık kullanılan dizinleri göster"
		echo "  4) Son oluşturulan dosyaları göster"
		echo "  5) Ana Menüye Dön"
		echo
		read -p "  Seçiminiz (1-5): " choice

		case $choice in
		1)
			echo
			echo "Dosya yolu girin (Tab tuşu ile tamamlanabilir):"
			read -e -p "  > " -i "$ANOTE_DIR/" file_path

			if [[ -z "$file_path" ]]; then
				continue
			fi

			# Tam dizin yolunu al
			dir_path=$(dirname "$file_path")

			# Dizin yoksa sor ve oluştur
			if [[ ! -d "$dir_path" ]]; then
				read -p "  Dizin '$dir_path' mevcut değil. Oluşturulsun mu? (e/h): " confirm
				if [[ "$confirm" != "e" && "$confirm" != "E" ]]; then
					continue
				fi
				mkdir -p "$dir_path"
				echo "  ✓ Dizin oluşturuldu: $dir_path"
			fi

			# Dosya uzantısını kontrol et
			file_ext="${file_path##*.}"
			if [[ "$file_path" == "$file_ext" ]]; then
				echo "  ⚠️ Dosya uzantısı belirtilmedi. Önerilen uzantılar: .md, .txt, .sh"
				read -p "  Devam etmek istiyor musunuz? (e/h): " confirm
				if [[ "$confirm" != "e" && "$confirm" != "E" ]]; then
					continue
				fi
			fi

			# Geçmişe ekle
			update_history "$dir_path" "$file_path"

			# Dosyayı düzenle
			if [[ "$TERM_PROGRAM" = tmux ]] || [[ -n "$TMUX" ]]; then
				tmux new-window -n "${file_path##*/}" "$EDITOR $file_path"
			else
				"$EDITOR" "$file_path"
			fi
			return
			;;
		2)
			echo
			echo "Önce dizin seçin (Tab tuşu ile tamamlanabilir):"
			read -e -p "  > " -i "$ANOTE_DIR/" dir_path

			if [[ -z "$dir_path" ]]; then
				continue
			fi

			# Dizin yoksa sor ve oluştur
			if [[ ! -d "$dir_path" ]]; then
				read -p "  Dizin '$dir_path' mevcut değil. Oluşturulsun mu? (e/h): " confirm
				if [[ "$confirm" != "e" && "$confirm" != "E" ]]; then
					continue
				fi
				mkdir -p "$dir_path"
				echo "  ✓ Dizin oluşturuldu: $dir_path"
			fi

			# Dizindeki dosyaları göster
			if [[ "$(ls -A "$dir_path" 2>/dev/null)" ]]; then
				echo
				echo "  Dizindeki mevcut dosyalar:"
				ls -1 "$dir_path" | while read line; do
					echo "    - $line"
				done
				echo
			fi

			# Dosya adını iste
			echo "Şimdi dosya adını girin:"
			read -p "  > " file_name

			if [[ -z "$file_name" ]]; then
				continue
			fi

			# Tam dosya yolunu oluştur
			file_path="${dir_path%/}/$file_name"

			# Dosya uzantısını kontrol et
			file_ext="${file_name##*.}"
			if [[ "$file_name" == "$file_ext" ]]; then
				echo "  ⚠️ Dosya uzantısı belirtilmedi. Önerilen uzantılar: .md, .txt, .sh"
				read -p "  Devam etmek istiyor musunuz? (e/h): " confirm
				if [[ "$confirm" != "e" && "$confirm" != "E" ]]; then
					continue
				fi
			fi

			# Geçmişe ekle
			update_history "$dir_path" "$file_path"

			# Dosyayı düzenle
			if [[ "$TERM_PROGRAM" = tmux ]] || [[ -n "$TMUX" ]]; then
				tmux new-window -n "$file_name" "$EDITOR $file_path"
			else
				"$EDITOR" "$file_path"
			fi
			return
			;;
		3)
			echo
			echo "Sık kullanılan dizinler:"
			echo
			find "$ANOTE_DIR" -maxdepth 2 -type d | sort | while read dir; do
				echo "  - $dir"
			done
			echo
			read -p "Devam etmek için Enter'a basın..." dummy
			;;
		4)
			echo
			if [[ -f "$HISTORY_FILE" ]]; then
				echo "Son oluşturulan dosyalar:"
				echo
				jq -r 'to_entries | .[].value[0:5] | .[].file' "$HISTORY_FILE" 2>/dev/null |
					sort | uniq | head -10 | while read file; do
					if [[ -f "$file" ]]; then
						echo "  - $file ($(stat -c %y "$file" | cut -d' ' -f1))"
					fi
				done
			else
				echo "Henüz kayıtlı geçmiş bulunmuyor."
			fi
			echo
			read -p "Devam etmek için Enter'a basın..." dummy
			;;
		5)
			show_anote_tui
			return
			;;
		*)
			echo
			echo "⚠️ Geçersiz seçim! Lütfen 1-5 arası bir sayı girin."
			sleep 1
			;;
		esac
	done
}

# Karalama Kağıdı Modu
scratch_mode() {
	# Önce dizini ve dosyayı hazırla
	mkdir -p "$(dirname "$SCRATCH_FILE")"
	touch "$SCRATCH_FILE"

	# Not defterinin başlığını ve ilk satırlarını kontrol et
	local first_line=""
	if [[ -s "$SCRATCH_FILE" ]]; then
		first_line=$(head -n 1 "$SCRATCH_FILE")
		# Eğer son satır boş değilse boş satır ekle
		if [[ "$(tail -c 1 "$SCRATCH_FILE")" != "" ]]; then
			echo "" >>"$SCRATCH_FILE"
		fi
	fi

	# Eğer dosya boşsa veya doğru başlık yoksa, scratch dosyası başlığını ekle
	if [[ -z "$first_line" || "$first_line" != "# Scratch Notes - $USER" ]]; then
		{
			echo "# Scratch Notes - $USER"
			echo "# Bu dosya $ANOTE_DIR içinde otomatik olarak oluşturulmuş karalama notları içerir."
			echo "# Her yeni giriş bir tarih/saat başlığı ile ayrılır."
			echo ""
		} >"$SCRATCH_FILE.tmp"

		# Mevcut içeriği koru
		if [[ -s "$SCRATCH_FILE" ]]; then
			cat "$SCRATCH_FILE" >>"$SCRATCH_FILE.tmp"
		fi

		mv "$SCRATCH_FILE.tmp" "$SCRATCH_FILE"
	fi

	# Yeni not başlığını ekle
	printf "\n#### %s\n\n" "$(date "+%Y-%m-%d %H:%M:%S")" >>"$SCRATCH_FILE"

	# Backups dizini varsa, bir yedek al (günde bir kez)
	local backup_dir="$ANOTE_DIR/backups"
	local today=$(date +%Y%m%d)
	local backup_file="$backup_dir/scratch_$today.bak"

	if [[ -d "$backup_dir" && ! -f "$backup_file" ]]; then
		cp "$SCRATCH_FILE" "$backup_file"
	fi

	# Editörde aç - daha iyi cursor pozisyonlama
	if [[ "$TERM_PROGRAM" = tmux ]] || [[ -n "$TMUX" ]]; then
		tmux new-window -n "scratch" "$EDITOR \"+normal G$\" $SCRATCH_FILE"
	else
		if [[ "$EDITOR" == *"nvim"* || "$EDITOR" == *"nvim"* ]]; then
			# Vim ve NeoVim için en altta konumlan
			$EDITOR "+normal G$" "$SCRATCH_FILE"
		else
			# Diğer editörler için
			$EDITOR "+$" "$SCRATCH_FILE"
		fi
	fi

	# Çıkış sonrası arayüze dönüş için opsiyonel kod
	if [[ "$1" != "direct" ]]; then
		sleep 0.5 # Editörün kapanmasını bekle
		show_anote_tui
	fi
}

# =================================================================
# ANA PROGRAM
# =================================================================

main() {
	# Bağımlılıkları kontrol et
	check_dependencies

	# Gerekli dizinleri oluştur
	create_required_directories

	# Önbellek bakımını yap
	maintain_cache

	# Komut satırı parametrelerini işle
	case "$1" in
	-h | --help)
		show_anote_help
		exit 0
		;;
	-i | --info)
		show_snippet_info | less -R
		exit 0
		;;
	-A | --audit | --scratch)
		# Not defterini düzenle (audit ve scratch aynı işi yapar)
		scratch_mode "direct"
		;;
	-a | --auto)
		# Not defterine otomatik giriş ekle
		if [[ -z "$2" ]]; then
			echo 'HATA: Not girişi eksik!' >&2
			exit 1
		fi
		mkdir -p "$(dirname "$SCRATCH_FILE")"
		touch "$SCRATCH_FILE"
		shift
		input="$*"
		# Dosyanın sonuna yeni not için başlık ekle eğer dosya boş değilse önce satır başı ekle
		if [[ -s "$SCRATCH_FILE" ]]; then
			echo "" >>"$SCRATCH_FILE"
		fi
		printf "%s\n" "#### $TIMESTAMP" >>"$SCRATCH_FILE"
		printf "%s\n" "$input" >>"$SCRATCH_FILE"
		echo "Not eklendi: $SCRATCH_FILE"
		;;
	-d | --dir)
		# Tüm dizinleri listele
		cd "$ANOTE_DIR" || exit 1
		find . -type d -not -path "*/\.*" -printf "%P\n" | sort
		;;
	-l | --list)
		# Tüm dosyaları listele
		cd "$ANOTE_DIR" || exit 1
		find . -type f -not -path "*/\.*" -printf "%P\n" | sort
		;;
	-e | --edit)
		if [[ -z "$2" ]]; then
			# Dosya belirtilmemişse fzf ile seç
			cd "$ANOTE_DIR" || exit 1
			selected=$(find . -type f -not -path "*/\.*" | sort |
				fzf -e -i --prompt="anote > düzenle: " \
					--preview 'bat --color=always -pp {} 2>/dev/null || cat {}' \
					--info=hidden --layout=reverse --scroll-off=5 \
					--bind 'home:first,end:last,ctrl-k:preview-page-up,ctrl-j:preview-page-down')
			[[ -z "$selected" ]] && exit 0
			"$EDITOR" "$selected"
		elif [[ -f "$ANOTE_DIR/$2" ]]; then
			# Varolan dosyayı düzenle
			"$EDITOR" "$ANOTE_DIR/$2"
		elif [[ -d "$(dirname "$ANOTE_DIR/$2")" ]]; then
			# Ana dizin varsa doğrudan düzenle
			"$EDITOR" "$ANOTE_DIR/$2"
		elif [[ ! -d "$(dirname "$ANOTE_DIR/$2")" ]]; then
			# Dizin yoksa oluşturmayı sor
			read -rp "Dizin '$ANOTE_DIR/$(dirname "$2")' mevcut değil. Oluşturulsun mu? [e/h]: " answer
			printf '\n'
			if [[ $answer =~ ^[Ee]$ ]]; then
				mkdir -p "$(dirname "$ANOTE_DIR/$2")"
				"$EDITOR" "$ANOTE_DIR/$2"
			fi
		fi
		;;
	-s | --search)
		if [[ -z "$2" ]]; then
			# Arama terimi belirtilmemişse interaktif ara
			selected=$(grep -rnv '^[[:space:]]*$' "$ANOTE_DIR"/* 2>/dev/null |
				fzf -d : --with-nth 1,2,3 --prompt="anote > ara: " \
					--preview '
				    file=$(echo {} | cut -d: -f1)
				    line=$(echo {} | cut -d: -f2)
				    bat --color=always --highlight-line "$line" "$file" 2>/dev/null || 
				    cat "$file" | nl -w4 -s": " | grep -A 5 -B 5 "^[ ]*$line:"
				')
			[[ -z "$selected" ]] && exit 0
			file_name=$(echo "$selected" | cut -d ':' -f1)
			file_num=$(echo "$selected" | cut -d ':' -f2)
			dir=$(dirname "$file_name")
			update_history "$dir" "$file_name"
			if [[ "$TERM_PROGRAM" = tmux ]] || [[ -n "$TMUX" ]]; then
				tmux new-window -n "ara-sonucu" "$EDITOR +$file_num $file_name"
			else
				"$EDITOR" +"$file_num" "$file_name"
			fi
		else
			# Belirtilen kelimeyi ara
			cd "$ANOTE_DIR" || exit 1
			shift
			grep --color=auto -rnH "$*" . 2>/dev/null || echo "Sonuç bulunamadı."
		fi
		;;
	-p | --print)
		if [[ -z "$2" ]]; then
			# Dosya belirtilmemişse fzf ile seç
			selected=$(find "$ANOTE_DIR"/ -type f -not -path "*/\.*" 2>/dev/null | sort |
				fzf -d / --with-nth -2.. \
					--preview 'bat --color=always -pp {} 2>/dev/null || cat {}' \
					--prompt="anote > görüntüle: ")
			[[ -z "$selected" ]] && exit 0
			if command -v bat >/dev/null 2>&1; then
				bat --color=always -pp "$selected" 2>/dev/null || cat "$selected"
			else
				cat "$selected"
			fi
		else
			# Belirtilen dosyayı görüntüle
			if [[ -f "$ANOTE_DIR/$2" ]]; then
				if command -v bat >/dev/null 2>&1; then
					bat --color=always -pp "$ANOTE_DIR/$2" 2>/dev/null || cat "$ANOTE_DIR/$2"
				else
					cat "$ANOTE_DIR/$2"
				fi
			else
				echo "HATA: Dosya bulunamadı: $ANOTE_DIR/$2" >&2
				exit 1
			fi
		fi
		;;
	-t | --snippet)
		# Snippet modunu başlat
		snippet_mode
		;;
	-S | --single-snippet)
		# Tek satır snippet modunu başlat
		single_mode
		;;
	-M | --multi-snippet)
		# Çok satırlı snippet modunu başlat
		multi_mode
		;;
	-c | --config)
		# Konfigürasyon dosyasını düzenle
		mkdir -p "$(dirname "$CONFIG_FILE")"
		if [[ ! -f "$CONFIG_FILE" ]]; then
			# Varsayılan konfigürasyon oluştur
			cat >"$CONFIG_FILE" <<EOF
# anote.sh konfigürasyon dosyası

# Ana dizin
ANOTE_DIR="$HOME/.anote"

# Editör
EDITOR="nvim"

# Tarih formatı
DATE_FORMAT="%Y-%m-%d %H:%M:%S"

# Önbellek temizleme aralığı (saniye)
CLEANUP_INTERVAL=604800  # 7 gün

# fzf ayarları
FZF_OPTS="-e -i --info=hidden --layout=reverse --scroll-off=5"
EOF
		fi
		"$EDITOR" "$CONFIG_FILE"
		;;
	"")
		# Parametre yoksa TUI'yı başlat
		show_anote_tui
		;;
	*)
		# Diğer durumlar - dosya adı belirtilmişse içeriğini göster
		if [[ -f "$ANOTE_DIR/$1" ]]; then
			if command -v bat >/dev/null 2>&1; then
				bat --color=always -pp "$ANOTE_DIR/$1" 2>/dev/null || cat "$ANOTE_DIR/$1"
			else
				cat "$ANOTE_DIR/$1"
			fi
		else
			echo "HATA: Dosya bulunamadı: $ANOTE_DIR/$1" >&2
			exit 1
		fi
		;;
	esac
}

# Programı çalıştır
main "$@"
