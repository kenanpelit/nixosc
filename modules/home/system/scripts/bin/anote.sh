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
# Versiyon: 2.0
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
EDITOR="${EDITOR:-vim}"
TIMESTAMP="$(date +%Y-%m-%d\ %H:%M:%S)"
SCRATCH_FILE="$SCRATCH_DIR/$(date +%Y-%m).txt"
HISTORY_FILE="$CACHE_DIR/history.json"
CLEANUP_INTERVAL=$((7 * 24 * 60 * 60)) # 7 gün

# Varsayılan fzf ayarları
export FZF_DEFAULT_OPTS="-e -i --info=hidden --layout=reverse --scroll-off=5 --tiebreak=index"
FZF_DEFAULT_OPTS+=" --bind 'home:first,end:last,ctrl-k:preview-page-up,ctrl-j:preview-page-down'"
FZF_DEFAULT_OPTS+=" --bind 'ctrl-y:preview-up,ctrl-e:preview-down,ctrl-/:change-preview-window(hidden|)'"

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
		[[ "$TERM_PROGRAM" != tmux ]]; then
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
	local dir=$1
	local file=$2
	local timestamp=$(date +%s)
	local temp_file="$CACHE_DIR/history.tmp"

	# history.json dosyası yoksa oluştur
	[[ ! -f "$HISTORY_FILE" ]] && echo "{}" >"$HISTORY_FILE"

	# Dizin geçmişte varsa güncelle, yoksa ekle
	if jq -e "has(\"$dir\")" "$HISTORY_FILE" >/dev/null; then
		jq --arg dir "$dir" \
			--arg file "$file" \
			--arg time "$timestamp" \
			'.[$dir] = (.[$dir] | map(select(.file != $file)) + [{
                "file": $file,
                "time": $time | tonumber
             }] | sort_by(-.time)[0:100])' "$HISTORY_FILE" >"$temp_file"
	else
		jq --arg dir "$dir" \
			--arg file "$file" \
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
	local dir=$1
	local recent_files=""

	# Geçmişte kayıtlı dosyaları al
	if [[ -f "$HISTORY_FILE" ]] && jq -e "has(\"$dir\")" "$HISTORY_FILE" >/dev/null; then
		recent_files=$(jq -r --arg dir "$dir" '.[$dir][].file' "$HISTORY_FILE")
	fi

	# Önce geçmiş dosyaları göster
	while IFS= read -r file; do
		[[ -f "$file" ]] && echo "$file"
	done < <(echo "$recent_files")

	# Sonra diğer dosyaları göster (geçmişte olmayanlar)
	find "$dir" -type f | while IFS= read -r file; do
		if [[ -n "$recent_files" ]]; then
			echo "$recent_files" | grep -q "^$file$" || echo "$file"
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
           .value = (.value | map(select((.file | test("^/")) and (.file | test("^" + env.HOME)) and ((env.HOME + .file) | test("e")))))
           ) | from_entries' "$HISTORY_FILE" >"$temp_file"
		mv "$temp_file" "$HISTORY_FILE"

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
		error_output=$(printf '%s' "$content" | wl-copy 2>&1) && success=true
	elif [[ -n "$DISPLAY" ]]; then
		if command -v xsel >/dev/null 2>&1; then
			clipboard_tool="xsel"
			error_output=$(printf '%s' "$content" | xsel -b 2>&1) && success=true
		elif command -v xclip >/dev/null 2>&1; then
			clipboard_tool="xclip"
			error_output=$(printf '%s' "$content" | xclip -selection clipboard -r 2>&1) && success=true
		fi
	elif [[ "$OSTYPE" == "darwin"* ]] && command -v pbcopy >/dev/null 2>&1; then
		clipboard_tool="pbcopy"
		error_output=$(printf '%s' "$content" | pbcopy 2>&1) && success=true
	elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]] && command -v clip >/dev/null 2>&1; then
		clipboard_tool="clip"
		error_output=$(printf '%s' "$content" | clip 2>&1) && success=true
	fi

	# Tmux içindeyse tmux tamponuna kopyala (ek güvenlik olarak)
	if [[ "$TERM_PROGRAM" == "tmux" || -n "$TMUX" ]]; then
		printf '%s' "$content" | tmux load-buffer - 2>/dev/null
		if [[ $? -eq 0 ]]; then
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
                   title=$(echo {} | cut -d " " -f2-)
                   ext=${file##*.}
                   awk -v title="$title" "BEGIN{RS=\"\"} \$0 ~ title" "$file" | 
                       bat --color=always -pp -l "$ext"
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
		echo "$selected" | bat --color=always -pp -l "${file_name##*.}"
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
	selected="$(cat "$SNIPPET_CACHE" "$SNIPPET_FILE" | awk '!seen[$0]++' |
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
	touch "$MULTI_CACHE"

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
			--preview 'bat --color=always -pp {}' \
			--preview-window='right:60%:wrap' \
			--prompt="Metin bloğu > " \
			--header="ESC: Çıkış | ENTER: Kopyala | CTRL+E: Düzenle" \
			--info=hidden \
			--layout=reverse \
			--tiebreak=index \
			--bind "ctrl-e:execute($EDITOR {} < /dev/tty > /dev/tty)")"

	[[ -z "$selected" ]] && exit 0

	update_cache "$selected" "$MULTI_CACHE"

	# Dosyanın içeriğini panoya kopyala
	copy_to_clipboard "$(cat "$selected")"

	# Önizleme göster
	echo -e "\n--- Kopyalanan İçerik ---"
	bat --color=always -pp "$selected"
	echo -e "\n"
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
                   title=$(echo {} | cut -d " " -f2-)
                   ext=${file##*.}
                   awk -v title="$title" "BEGIN{RS=\"\"} \$0 ~ title" "$file" |
                       bat --color=always -pp -l "$ext"
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
		echo "$selected" | bat --color=always -pp -l "${file_name##*.}"
		echo -e "\n"

		read -n 1 -p "Başka bir snippet seçmek ister misiniz? (e/h) [h]: " yn
		echo
		[[ -z "$yn" ]] && yn="h" # Enter'a basılırsa varsayılan 'h' olsun
		[[ "$yn" != "e" && "$yn" != "E" ]] && break
	done
}

# Dosya Düzenleme Modu
edit_mode() {
	while true; do
		if [[ "$TERM_PROGRAM" = tmux ]]; then
			selected=$(find "$ANOTE_DIR"/ -type f 2>/dev/null | sort |
				fzf -m -d / --with-nth -2.. \
					--bind "shift-delete:execute:gio trash --force {} >/dev/tty" \
					--bind "ctrl-v:execute:qmv -f do {} >/dev/tty" \
					--bind "ctrl-r:reload:find '$ANOTE_DIR'/ -type f | sort" \
					--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
					--header 'ESC:Geri C-v:yeniden-adlandır C-r:yenile S-del:çöpe-at' \
					--preview 'bat --color=always -pp {}' \
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
			selected=$(find "$ANOTE_DIR"/ -type f 2>/dev/null | sort |
				fzf -d / --with-nth -2.. \
					--preview 'bat --color=always -pp {}' \
					--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
					--header 'ESC:Geri ENTER:Düzenle' \
					--prompt="anote > düzenle: ")

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

# Dosya İçeriği Kopyalama Modu
copy_mode() {
	while true; do
		selected=$(
			find "$ANOTE_DIR"/ -type f 2>/dev/null | sort |
				fzf -d / --with-nth -2.. \
					--preview 'bat --color=always -pp {}' \
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
		bat --color=always -pp "$selected"
		echo -e "\n"

		read -n 1 -p "Başka bir snippet seçmek ister misiniz? (e/h) [h]: " yn
		echo
		[[ -z "$yn" ]] && yn="h" # Enter'a basılırsa varsayılan 'h' olsun
		[[ "$yn" != "e" && "$yn" != "E" ]] && break
	done
}

# Dosya Arama Modu
search_mode() {
	while true; do
		selected=$(grep -rnv '^[[:space:]]*$' "$ANOTE_DIR"/* 2>/dev/null |
			fzf -d / --with-nth 6.. \
				--prompt="anote > ara: " \
				--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
				--header "ESC:Geri ENTER:Seç")

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

		if [[ "$TERM_PROGRAM" = tmux ]]; then
			tmux new-window -n "ara-sonucu" "$EDITOR +$file_num $file_name"
		else
			"$EDITOR" +"$file_num" "$file_name"
		fi
		break
	done
}

# Yeni Dosya Oluşturma Modu
create_mode() {
	while true; do
		selected=$(echo | fzf --print-query \
			--prompt="anote > yeni dosya adı: " \
			--header 'ESC:Geri ENTER:Oluştur | örn: notlar.md veya linux/komutlar.sh' \
			--preview-window 'down' \
			--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
			--preview "find $ANOTE_DIR/ -type d | sed -e '/^[[:blank:]]*$/d' | sort")

		if [[ -f /tmp/anote_nav ]]; then
			rm /tmp/anote_nav
			show_anote_tui
			break
		fi

		[[ -z "$selected" ]] && exit 0
		mkdir -p "$(dirname "$ANOTE_DIR/$selected")"

		if [[ "$TERM_PROGRAM" = tmux ]]; then
			tmux new-window -n "yeni-dosya" "$EDITOR $ANOTE_DIR/$selected"
		else
			"$EDITOR" "$ANOTE_DIR/$selected"
		fi
		break
	done
}

# Karalama Kağıdı Modu
scratch_mode() {
	mkdir -p "$(dirname "$SCRATCH_FILE")"
	[[ -z "$(tail -n 1 "$SCRATCH_FILE" 2>/dev/null)" ]] || printf "\n" >>"$SCRATCH_FILE"
	printf "%s\n\n" "#### $TIMESTAMP" >>"$SCRATCH_FILE"
	"$EDITOR" +999999 "$SCRATCH_FILE"
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
	-A | --audit)
		# Not defterini düzenle
		mkdir -p "$(dirname "$SCRATCH_FILE")"
		[[ -z "$(tail -n 1 "$SCRATCH_FILE" 2>/dev/null)" ]] || printf "\n" >>"$SCRATCH_FILE"
		printf "%s\n\n" "#### $TIMESTAMP" >>"$SCRATCH_FILE"
		"$EDITOR" +999999 "$SCRATCH_FILE"
		;;
	-a | --auto)
		# Not defterine otomatik giriş ekle
		if [[ -z "$2" ]]; then
			echo 'HATA: Not girişi eksik!' >&2
			exit 1
		fi
		mkdir -p "$(dirname "$SCRATCH_FILE")"
		shift
		input="$*"
		[[ -z "$(tail -n 1 "$SCRATCH_FILE" 2>/dev/null)" ]] || printf "\n" >>"$SCRATCH_FILE"
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
					--preview 'bat --color=always -pp {}' \
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
				fzf -d / --with-nth 6.. --prompt="anote > ara: ")
			[[ -z "$selected" ]] && exit 0
			file_name=$(echo "$selected" | cut -d ':' -f1)
			file_num=$(echo "$selected" | cut -d ':' -f2)
			dir=$(dirname "$file_name")
			update_history "$dir" "$file_name"
			if [[ "$TERM_PROGRAM" = tmux ]]; then
				tmux new-window -n "ara-sonucu" "$EDITOR +$file_num $file_name"
			else
				"$EDITOR" +"$file_num" "$file_name"
			fi
		else
			# Belirtilen kelimeyi ara
			cd "$ANOTE_DIR" || exit 1
			shift
			grep --color=auto -rnH "$*" .
		fi
		;;
	-p | --print)
		if [[ -z "$2" ]]; then
			# Dosya belirtilmemişse fzf ile seç
			selected=$(find "$ANOTE_DIR"/ -type f -not -path "*/\.*" | sort |
				fzf -d / --with-nth -2.. \
					--preview 'bat --color=always -pp {}' \
					--prompt="anote > görüntüle: ")
			[[ -z "$selected" ]] && exit 0
			bat --color=always -pp "$selected"
		else
			# Belirtilen dosyayı görüntüle
			if [[ -f "$ANOTE_DIR/$2" ]]; then
				bat --color=always -pp "$ANOTE_DIR/$2"
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
EDITOR="vim"

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
		if command -v bat >/dev/null; then
			if [[ -f "$ANOTE_DIR/$1" ]]; then
				bat --color=always -pp "$ANOTE_DIR/$1"
			else
				echo "HATA: Dosya bulunamadı: $ANOTE_DIR/$1" >&2
				exit 1
			fi
		else
			if [[ -f "$ANOTE_DIR/$1" ]]; then
				cat "$ANOTE_DIR/$1"
			else
				echo "HATA: Dosya bulunamadı: $ANOTE_DIR/$1" >&2
				exit 1
			fi
		fi
		;;
	esac
}

# Programı çalıştır
main "$@"
