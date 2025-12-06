#!/usr/bin/env bash
#===============================================================================
#   Original Author: Wenxuan
#    Original Email: wenxuangm@gmail.com
#  Created: 2018-04-06 12:12
#
#   Updated By: Kenan Pelit
#    Email: kenanpelit@gmail.com
#   Update: 2025-04-07 - NixOS ve Zen Browser desteği eklendi
#===============================================================================
get_fzf_options() {
	local fzf_options
	local fzf_default_options='-w 100% -h 50% --multi -0 --no-preview'
	fzf_options="$(tmux show -gqv '@fzf-url-fzf-options')"
	[ -n "$fzf_options" ] && echo "$fzf_options" || echo "$fzf_default_options"
}

fzf_filter() {
	eval "fzf-tmux $(get_fzf_options)"
}

# Hata ayıklama log dosyası
LOG_FILE="/tmp/tmux-fzf-url-debug.log"
echo "$(date): Script başlatıldı" >"$LOG_FILE"

custom_open=$3
echo "custom_open değeri: $custom_open" >>"$LOG_FILE"

open_url() {
	local url="$1"
	echo "URL açılıyor: $url" >>"$LOG_FILE"

	# Doğrudan xdg-open kullan
	xdg-open "$url" &>/dev/null &
	echo "xdg-open ile URL açıldı." >>"$LOG_FILE"
	return 0
}

limit='screen'
[[ $# -ge 2 ]] && limit=$2
if [[ $limit == 'screen' ]]; then
	content="$(tmux capture-pane -J -p -e)"
else
	content="$(tmux capture-pane -J -p -e -S -"$limit")"
fi

# URL'leri topla
urls=$(echo "$content" | grep -oE '(https?|ftp|file):/?//[-A-Za-z0-9+&@#/%?=~_|!:,.;]*[-A-Za-z0-9+&@#/%=~_|]')
wwws=$(echo "$content" | grep -oE '(http?s://)?www\.[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}(/\S+)*' | grep -vE '^https?://' | sed 's/^\(.*\)$/http:\/\/\1/')
ips=$(echo "$content" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(:[0-9]{1,5})?(/\S+)*' | sed 's/^\(.*\)$/http:\/\/\1/')
gits=$(echo "$content" | grep -oE '(ssh://)?git@\S*' | sed 's/:/\//g' | sed 's/^\(ssh\/\/\/\)\{0,1\}git@\(.*\)$/https:\/\/\2/')
gh=$(echo "$content" | grep -oE "['\"]([_A-Za-z0-9-]*/[_.A-Za-z0-9-]*)['\"]" | sed "s/['\"]//g" | sed 's#.#https://github.com/&#')

if [[ $# -ge 1 && "$1" != '' ]]; then
	extras=$(echo "$content" | eval "$1")
fi

items=$(
	printf '%s\n' "${urls[@]}" "${wwws[@]}" "${gh[@]}" "${ips[@]}" "${gits[@]}" "${extras[@]}" |
		grep -v '^$' |
		sort -u |
		nl -w3 -s '  '
)

[ -z "$items" ] && tmux display 'tmux-fzf-url: no URLs found' && exit

echo "URL'ler bulundu: $(echo "$items" | wc -l) adet" >>"$LOG_FILE"

fzf_filter <<<"$items" | awk '{print $2}' |
	while read -r chosen; do
		echo "Seçilen URL: $chosen" >>"$LOG_FILE"
		open_url "$chosen"
	done
