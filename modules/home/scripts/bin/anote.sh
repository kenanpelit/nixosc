#!/usr/bin/env bash

# This implementation appears to be inspired by gotbletu's
# notekami project (https://github.com/gotbletu/fzf-nova),
# which is a terminal-based note-taking and cheatsheet manager
# utilizing fzf for efficient text searching and management.

# Temel ayarlar ve gerekli fonksiyonlar ilk olarak tanımlanır
show_anote_help() {
	cat <<'EOF'

açıklama:      terminal üzerinde basit cheatsheet,
               snippet,karalama ve not alma yöneticisi
bağımlılıklar: fzf coreutils less bat util-linux findutils glib2 renameutils
               awk sed grep xsel (veya xclip,wl-copy,pbcopy,clip,termux,clipboard,tmux)

kullanım: anote.sh <seçenekler>

seçenekler:
                        Argüman olmadan fzf TUI'yı başlatır
  -a, --auto            Not defterine otomatik giriş ekle
  -A, --audit           Not defterini metin editöründe aç
  -e, --edit            Dosya düzenle veya yeni oluştur (argümansız fzf başlatır)
  -l, --list            Tüm dosyaları listele
  -d, --dir             Tüm dizinleri listele
  -p, --print           Dosya içeriğini ekranda göster (argümansız fzf başlatır)
  -s, --search          Tek anahtar kelime için tüm dosyalarda ara (argümansız fzf başlatır)
  -t, --snippet         Snippet'i panoya kopyala ve ekranda göster
  -i, --info            Snippet yazma kılavuzu ve kısayol tuşları listesi
  -h, --help            Bu yardım sayfasını göster
  -S, --single-snippet  Tek satır snippet modunda çalıştır
  -M, --multi-snippet   Çok satırlı snippet modunda çalıştır

örnekler:
  anote.sh
  anote.sh betik.sh
  anote.sh komutlar/awk.sh
  anote.sh -p
  anote.sh -p notlar.md
  anote.sh -p notlar/linux/awk.sh
  anote.sh -e
  anote.sh -e notlar/linux/awk.sh
  anote.sh -e yenidosya.sh
  anote.sh -e yenidizin/yenidosya.sh
  anote.sh -a buraya yazdığım mesaj not defterine eklenecek
  anote.sh -s
  anote.sh -s aranacakkelime

kayıt dizini: oluşturulan dosyalar ~/.anote dizinine kaydedilir

[tuş kısayolları için -i veya --info kullanın]

EOF
}

export EDITOR="vim"

# XDG Base Directory cache dizini
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/anote"
[[ ! -d "$CACHE_DIR" ]] && mkdir -p "$CACHE_DIR"

# Geçmiş yönetimi fonksiyonları
update_history() {
	local dir=$1
	local file=$2
	local history_file="$CACHE_DIR/history.json"
	local temp_file="$CACHE_DIR/history.tmp"
	local timestamp=$(date +%s)

	[[ ! -f "$history_file" ]] && echo "{}" >"$history_file"

	if jq -e "has(\"$dir\")" "$history_file" >/dev/null; then
		jq --arg dir "$dir" \
			--arg file "$file" \
			--arg time "$timestamp" \
			'.[$dir] = (.[$dir] | map(select(.file != $file)) + [{
              "file": $file,
              "time": $time | tonumber
           }] | sort_by(-.time)[0:100])' "$history_file" >"$temp_file"
	else
		jq --arg dir "$dir" \
			--arg file "$file" \
			--arg time "$timestamp" \
			'.[$dir] = [{
              "file": $file,
              "time": $time | tonumber
          }]' "$history_file" >"$temp_file"
	fi

	mv "$temp_file" "$history_file"
}

get_sorted_files() {
	local dir=$1
	local history_file="$CACHE_DIR/history.json"
	local recent_files=""

	if [[ -f "$history_file" ]] && jq -e "has(\"$dir\")" "$history_file" >/dev/null; then
		recent_files=$(jq -r --arg dir "$dir" '.[$dir][].file' "$history_file")
	fi

	# Önce geçmiş dosyaları göster
	while read -r file; do
		[[ -f "$file" ]] && echo "$file"
	done < <(echo "$recent_files")

	# Sonra diğer dosyaları
	while read -r file; do
		if [[ -n "$recent_files" ]]; then
			echo "$recent_files" | grep -q "^$file$" || echo "$file"
		else
			echo "$file"
		fi
	done < <(find "$dir" -type f)
}

clean_history() {
	local history_file="$CACHE_DIR/history.json"
	local temp_file="$CACHE_DIR/history.tmp"

	if [[ -f "$history_file" ]]; then
		jq 'to_entries | map(
           .value = (.value | map(select(.file as $f | test("^/") and ($f | test("^" + env.HOME)))))
           | from_entries' "$history_file" >"$temp_file"
		mv "$temp_file" "$history_file"

		jq 'to_entries | map(select(.value != [])) | from_entries' "$history_file" >"$temp_file"
		mv "$temp_file" "$history_file"
	fi
}

maintain_cache() {
	local last_clean_file="$CACHE_DIR/last_clean"
	local current_time=$(date +%s)
	local clean_interval=$((24 * 60 * 60))

	if [[ ! -f "$last_clean_file" ]] ||
		[[ $((current_time - $(cat "$last_clean_file"))) -gt $clean_interval ]]; then
		clean_history
		echo "$current_time" >"$last_clean_file"
	fi
}

maintain_cache

export FZF_DEFAULT_OPTS="-e -i --info=hidden --layout=reverse --scroll-off=5 --tiebreak=index"
FZF_DEFAULT_OPTS+=" --bind 'home:first,end:last,ctrl-k:preview-page-up,ctrl-j:preview-page-down'"
FZF_DEFAULT_OPTS+=" --bind 'ctrl-y:preview-up,ctrl-e:preview-down,ctrl-/:change-preview-window(hidden|)'"

export mydir="$HOME/.anote"
export mycheatdir="$mydir/cheats"
export myfile="$mydir/scratch/$(date +%Y-%m).txt"
export timestamp="$(date +%Y-%m-%d\ %r)"
[[ ! -d "$mydir" ]] && mkdir -p "$mydir"

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

show_anote_tui() {
	selected=$(list_anote_options | column -s '|' -t |
		fzf --header 'Esc:quit C-n/p:down/up Enter:select' \
			--prompt="snippets: " | cut -d ' ' -f1)

	[[ -z "$selected" ]] && exit

	case $selected in
	snippet)
		while true; do
			selected=$(grep -nrH '^####; ' "$mydir/snippets"/* | sort -t: -k1,1 |
				fzf -d ' ' --with-nth 2.. \
					--prompt="anote >>> copy to clipboard: " \
					--bind "ctrl-f:execute:$EDITOR \$(echo {} | cut -d: -f1)" \
					--bind "ctrl-e:execute:$EDITOR +\$(echo {} | cut -d: -f2) \$(echo {} | cut -d: -f1)" \
					--bind "ctrl-r:reload(grep -nrH '^####; ' $mydir/snippets/*)" \
					--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
					--bind 'home:first,end:last,tab:down,shift-tab:up' \
					--header 'ESC:Back C-e:edit-line C-f:edit-file' \
					--preview-window 'down' \
					--preview '
                       file=$(echo {} | cut -d: -f1)
                       title=$(echo {} | cut -d " " -f2-)
                       ext=$(echo "$file" | rev | cut -d. -f1 | rev)
                       awk -v title="$title" "BEGIN{RS=\"\"} \$0 ~ title" "$file" | 
                           bat --color=always -pp -l "$ext"
                   ')

			if [[ -f /tmp/anote_nav ]]; then
				rm /tmp/anote_nav
				show_anote_tui
				break
			fi

			[[ -z "$selected" ]] && exit

			file_name="$(echo "$selected" | cut -d: -f1)"
			dir=$(dirname "$file_name")
			update_history "$dir" "$file_name"
			snippet_title="$(echo "$selected" | cut -d " " -f2-)"

			selected=$(awk -v title="$snippet_title" 'BEGIN{RS=""} $0 ~ title' "$file_name" |
				sed -e '/^####;/d' -e '/^###;/d' -e '/^##;/d')

			if [[ "$TERM_PROGRAM" = tmux ]]; then
				printf '%s' "$selected" | tmux load-buffer - 2>/dev/null
			fi

			printf '%s' "$selected" | wl-copy 2>/dev/null ||
				printf '%s' "$selected" | xsel -b 2>/dev/null ||
				printf '%s' "$selected" | xclip -selection clipboard -r 2>/dev/null

			break
		done
		;;

	single)
		single_mode
		;;

	multi)
		multi_mode
		;;

	cheats)
		while true; do
			selected=$(grep -nrH '^####; ' "$mycheatdir"/* | sort -t: -k1,1 |
				fzf -d ' ' --with-nth 2.. \
					--prompt="anote >>> copy to clipboard: " \
					--bind "ctrl-f:execute:$EDITOR \$(echo {} | cut -d: -f1)" \
					--bind "ctrl-e:execute:$EDITOR +\$(echo {} | cut -d: -f2) \$(echo {} | cut -d: -f1)" \
					--bind "ctrl-r:reload(grep -nrH '^####; ' $mycheatdir/*)" \
					--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
					--bind 'home:first,end:last,tab:down,shift-tab:up' \
					--header 'ESC:Back C-e:edit-line C-f:edit-file' \
					--preview-window 'down' \
					--preview '
                       file=$(echo {} | cut -d: -f1)
                       title=$(echo {} | cut -d " " -f2-)
                       ext=$(echo "$file" | rev | cut -d. -f1 | rev)
                       awk -v title="$title" "BEGIN{RS=\"\"} \$0 ~ title" "$file" |
                           bat --color=always -pp -l "$ext"
                   ')

			if [[ -f /tmp/anote_nav ]]; then
				rm /tmp/anote_nav
				show_anote_tui
				break
			fi

			[[ -z "$selected" ]] && exit

			file_name="$(echo "$selected" | cut -d: -f1)"
			dir=$(dirname "$file_name")
			update_history "$dir" "$file_name"
			snippet_title="$(echo "$selected" | cut -d " " -f2-)"

			selected=$(awk -v title="$snippet_title" 'BEGIN{RS=""} $0 ~ title' "$file_name" |
				sed -e '/^####;/d' -e '/^###;/d' -e '/^##;/d')

			if [[ "$TERM_PROGRAM" = tmux ]]; then
				printf '%s' "$selected" | tmux load-buffer - 2>/dev/null
			fi

			printf '%s' "$selected" | wl-copy 2>/dev/null ||
				printf '%s' "$selected" | xsel -b 2>/dev/null ||
				printf '%s' "$selected" | xclip -selection clipboard -r 2>/dev/null

			break
		done
		;;

	edit)
		while true; do
			if [[ "$TERM_PROGRAM" = tmux ]]; then
				selected=$(find "$mydir"/ -type f | sort |
					fzf -m -d / --with-nth -2.. \
						--bind "shift-delete:execute:gio trash --force {} >/dev/tty" \
						--bind "ctrl-v:execute:imv {} >/dev/tty" \
						--bind "ctrl-r:reload:find '$mydir'/ -type f | sort" \
						--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
						--header 'ESC:Back C-v:rename C-r:reload S-del:trash' \
						--preview 'bat --color=always -pp {}' \
						--prompt="anote >>> edit(s): ")

				if [[ -f /tmp/anote_nav ]]; then
					rm /tmp/anote_nav
					show_anote_tui
					break
				fi

				[[ -z "$selected" ]] && exit

				while read -r line; do
					filename="$(basename "$line")"
					tmux new-window -n "${filename}-pill" "$EDITOR $line"
				done <<<"$selected"
			else
				selected=$(find "$mydir"/ -type f | sort |
					fzf -d / --with-nth -2.. \
						--preview 'bat --color=always -pp {}' \
						--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
						--header 'ESC:Back ENTER:Edit' \
						--prompt="anote >>> edit: ")

				if [[ -f /tmp/anote_nav ]]; then
					rm /tmp/anote_nav
					show_anote_tui
					break
				fi

				[[ -z "$selected" ]] && exit
				dir=$(dirname "$selected")
				update_history "$dir" "$selected"
				"$EDITOR" "$selected"
			fi
			break
		done
		;;

	search)
		while true; do
			selected=$(grep -rnv '^[[:space:]]*$' "$mydir"/* 2>/dev/null |
				fzf -d / --with-nth 6.. \
					--prompt="anote >>> search: " \
					--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
					--header "ESC:Back ENTER:Select")

			if [[ -f /tmp/anote_nav ]]; then
				rm /tmp/
				/tmp/anote_nav
				show_anote_tui
				break
			fi

			[[ -z "$selected" ]] && exit
			file_name=$(echo "$selected" | cut -d ':' -f1)
			file_num=$(echo "$selected" | cut -d ':' -f2)
			dir=$(dirname "$file_name")
			update_history "$dir" "$file_name"

			if [[ "$TERM_PROGRAM" = tmux ]]; then
				tmux new-window -n "search-notes" "$EDITOR +$file_num $file_name"
			else
				"$EDITOR" +"$file_num" "$file_name"
			fi
			break
		done
		;;

	create)
		while true; do
			selected=$(echo | fzf --print-query \
				--prompt="anote >>> enter new name (no spaces): " \
				--header 'ESC:Back ENTER:Create | type in foo.md or newdir/subdir/bar.md' \
				--preview-window 'down' \
				--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
				--preview "find $mydir/ -type d | sed -e '/^[[:blank:]]*$/d' | sort")

			if [[ -f /tmp/anote_nav ]]; then
				rm /tmp/anote_nav
				show_anote_tui
				break
			fi

			[[ -z "$selected" ]] && exit
			mkdir -p "$(dirname "$mydir/$selected")"

			if [[ "$TERM_PROGRAM" = tmux ]]; then
				tmux new-window -n "create-notes" "$EDITOR $mydir/$selected"
			else
				"$EDITOR" "$mydir/$selected"
			fi
			break
		done
		;;

	copy)
		while true; do
			selected=$(find "$mydir"/ -type f | sort |
				fzf -d / --with-nth -2.. \
					--preview 'bat --color=always -pp {}' \
					--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
					--header 'ESC:Back ENTER:Copy' \
					--prompt="anote >>> copy to clipboard: ")

			if [[ -f /tmp/anote_nav ]]; then
				rm /tmp/anote_nav
				show_anote_tui
				break
			fi

			[[ -z "$selected" ]] && exit
			dir=$(dirname "$selected")
			update_history "$dir" "$selected"

			if [[ "$TERM_PROGRAM" = tmux ]]; then
				cat "$selected" | tmux load-buffer - 2>/dev/null
			fi

			cat "$selected" | wl-copy 2>/dev/null ||
				cat "$selected" | xsel -b 2>/dev/null ||
				cat "$selected" | xclip -selection clipboard -r 2>/dev/null
			break
		done
		;;

	scratch)
		mkdir -p "$(dirname "$myfile")"
		[[ -z "$(tail -n 1 "$myfile")" ]] || printf "\n" >>"$myfile"
		printf "%s\n\n" "#### $timestamp" >>"$myfile"
		"$EDITOR" +999999 "$myfile"
		;;

	info)
		show_anote_help | less -C
		;;
	esac
}

single_mode() {
	local SNIPPET_CACHE="$CACHE_DIR/snippetrc"
	local SNIPPET_FILE="$mydir/cheats/snippetrc"
	touch "$SNIPPET_FILE" "$SNIPPET_CACHE"

	local selected
	selected="$(cat "$SNIPPET_CACHE" "$SNIPPET_FILE" | awk '!seen[$0]++' |
		sed '/^$/d' |
		fzf -e -i \
			--prompt="Panoya kopyalanacak snippet: " \
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

	if [[ "$TERM_PROGRAM" = tmux ]]; then
		printf '%s' "$selected" | tmux load-buffer - 2>/dev/null
	fi

	printf '%s' "$selected" | wl-copy 2>/dev/null ||
		printf '%s' "$selected" | xsel -b 2>/dev/null ||
		printf '%s' "$selected" | xclip -selection clipboard -r 2>/dev/null
}

multi_mode() {
	local MULTI_CACHE="$CACHE_DIR/multi"
	touch "$MULTI_CACHE"

	local selected
	selected="$({
		cat "$MULTI_CACHE"
		find "$mycheatdir" -type f -not -name ".*"
	} |
		awk '!seen[$0]++' |
		sort |
		fzf -e -i \
			--delimiter / \
			--with-nth -1 \
			--preview 'cat {}' \
			--preview-window='right:60%:wrap' \
			--prompt="Metin bloğu seç: " \
			--header="ESC: Çıkış | ENTER: Kopyala | CTRL+E: Düzenle" \
			--info=hidden \
			--layout=reverse \
			--tiebreak=index \
			--bind "ctrl-e:execute($EDITOR {} < /dev/tty > /dev/tty)")"

	[[ -z "$selected" ]] && exit 0

	update_cache "$selected" "$MULTI_CACHE"

	if [[ "$TERM_PROGRAM" = tmux ]]; then
		printf '%s' "$(cat "$selected")" | tmux load-buffer - 2>/dev/null
	fi

	printf '%s' "$(cat "$selected")" | wl-copy 2>/dev/null ||
		printf '%s' "$(cat "$selected")" | xsel -b 2>/dev/null ||
		printf '%s' "$(cat "$selected")" | xclip -selection clipboard -r 2>/dev/null
}

# Ana program mantığı
if [[ "$1" = -h ]] || [[ "$1" = --help ]]; then
	show_anote_help
	exit 0
elif [[ -z "$1" ]]; then
	show_anote_tui
elif [[ "$1" = -A ]] || [[ "$1" = --audit ]]; then
	mkdir -p "$(dirname "$myfile")"
	[[ -z "$(tail -n 1 "$myfile")" ]] || printf "\n" >>"$myfile"
	printf "%s\n\n" "#### $timestamp" >>"$myfile"
	"$EDITOR" +999999 "$myfile"
elif [[ "$1" = -a ]] || [[ "$1" = --auto ]]; then
	if [[ -z "$2" ]]; then
		echo 'not girişi yazın'
		exit 1
	fi
	mkdir -p "$(dirname "$myfile")"
	shift
	input="$*"
	[[ -z "$(tail -n 1 "$myfile" 2>/dev/null)" ]] || printf "\n" >>"$myfile"
	printf "%s\n" "#### $timestamp" >>"$myfile"
	printf "%s\n" "$input" >>"$myfile"
elif [[ "$1" = -d ]] || [[ "$1" = --dir ]]; then
	cd "$mydir" || exit 1
	find . -type d -printf "%P\n" | sort
elif [[ "$1" = -l ]] || [[ "$1" = --list ]]; then
	cd "$mydir" || exit 1
	find . -type f -printf "%P\n" | sort
elif [[ "$1" = -e ]] || [[ "$1" = --edit ]]; then
	if [[ -z "$2" ]]; then
		cd "$mydir" || exit 1
		selected=$(fzf -e -i --prompt="anote >>> edit: " \
			--preview 'bat --color=always -pp {}' \
			--info=hidden --layout=reverse --scroll-off=5 \
			--bind 'home:first,end:last,ctrl-k:preview-page-up,ctrl-j:preview-page-down')
		[[ -z "$selected" ]] && exit
		"$EDITOR" "$selected"
	elif [[ -f "$mydir/$2" ]]; then
		"$EDITOR" "$mydir/$2"
	elif [[ -d "$(dirname "$mydir/$2")" ]]; then
		"$EDITOR" "$mydir/$2"
	elif [[ ! -d "$(dirname "$mydir/$2")" ]]; then
		read -rp "dizin oluşturulsun mu [e/h]? " answer
		printf '\n'
		if [[ $answer =~ ^[Ee]$ ]]; then
			mkdir -p "$(dirname "$mydir/$2")"
			"$EDITOR" "$mydir/$2"
		fi
	fi
elif [[ "$1" = -s ]] || [[ "$1" = --search ]]; then
	if [[ -z "$2" ]]; then
		selected=$(grep -rnv '^[[:space:]]*$' "$mydir"/* 2>/dev/null |
			fzf -d / --with-nth 6.. --prompt="anote >>> search: ")
		[[ -z "$selected" ]] && exit
		file_name=$(echo "$selected" | cut -d ':' -f1)
		file_num=$(echo "$selected" | cut -d ':' -f2)
		dir=$(dirname "$file_name")
		update_history "$dir" "$file_name"
		if [[ "$TERM_PROGRAM" = tmux ]]; then
			tmux new-window -n "search-notes" "$EDITOR +$file_num $file_name"
		else
			"$EDITOR" +"$file_num" "$file_name"
		fi
	else
		cd "$mydir" || exit 1
		shift
		grep --color=auto -rnH "$*" .
	fi
elif [[ "$1" = -i ]] || [[ "$1" = --info ]]; then
	show_anote_help | less -C
elif [[ "$1" = -t ]] || [[ "$1" = --snippet ]]; then
	selected=$(grep -nrH '^####; ' "$mycheatdir"/* | sort -t: -k1,1 |
		fzf -d ' ' --with-nth 2.. \
			--prompt="anote >>> copy to clipboard: " \
			--bind "ctrl-f:execute:$EDITOR \$(echo {} | cut -d: -f1)" \
			--bind "ctrl-e:execute:$EDITOR +\$(echo {} | cut -d: -f2) \$(echo {} | cut -d: -f1)" \
			--bind "ctrl-r:reload(grep -nrH '^####; ' $mycheatdir/*)" \
			--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
			--bind 'home:first,end:last,tab:down,shift-tab:up' \
			--header 'ESC:Back C-e:edit-line C-f:edit-file' \
			--preview-window 'down' \
			--preview '
           file=$(echo {} | cut -d: -f1)
           title=$(echo {} | cut -d " " -f2-)
           ext=$(echo "$file" | rev | cut -d. -f1 | rev)
           awk -v title="$title" "BEGIN{RS=\"\"} \$0 ~ title" "$file" |
               bat --color=always -pp -l "$ext"
       ')

	[[ -z "$selected" ]] && exit
	file_name="$(echo "$selected" | cut -d: -f1)"
	file_ext="$(echo "$selected" | cut -d: -f1 | rev | cut -d. -f1 | rev)"
	dir=$(dirname "$file_name")
	update_history "$dir" "$file_name"
	snippet_title="$(echo "$selected" | cut -d " " -f2-)"

	selected_unfilter=$(awk -v title="$snippet_title" 'BEGIN{RS=""} $0 ~ title' "$file_name")
	selected=$(awk -v title="$snippet_title" 'BEGIN{RS=""} $0 ~ title' "$file_name" |
		sed -e '/^####;/d' -e '/^###;/d' -e '/^##;/d')

	echo "$selected_unfilter" | bat --color=always -pp -l "$file_ext"

	if [[ "$TERM_PROGRAM" = tmux ]]; then
		printf '%s' "$selected" | tmux load-buffer - 2>/dev/null
	fi

	printf '%s' "$selected" | wl-copy 2>/dev/null ||
		printf '%s' "$selected" | xsel -b 2>/dev/null ||
		printf '%s' "$selected" | xclip -selection clipboard -r 2>/dev/null

elif [[ "$1" = -S ]] || [[ "$1" = --single-snippet ]]; then
	single_mode
elif [[ "$1" = -M ]] || [[ "$1" = --multi-snippet ]]; then
	multi_mode

elif [[ "$1" = -p ]] || [[ "$1" = --print ]]; then
	if [[ -z "$2" ]]; then
		selected=$(find "$mydir"/ -type f | sort |
			fzf -d / --with-nth -2.. \
				--preview 'bat --color=always -pp {}' \
				--prompt="anote >>> print: ")
		[[ -z "$selected" ]] && exit
		bat --color=always -pp "$selected"
	else
		if [[ -f "$mydir/$2" ]]; then
			bat --color=always -pp "$mydir/$2"
		else
			echo 'dosya mevcut değil'
		fi
	fi
else
	if command -v bat >/dev/null; then
		if [[ -f "$mydir/$1" ]]; then
			bat --color=always -pp "$mydir/$1"
		else
			echo 'dosya mevcut değil'
		fi
	else
		if [[ -f "$mydir/$1" ]]; then
			cat "$mydir/$1"
		else
			echo 'dosya mevcut değil'
		fi
	fi
fi
