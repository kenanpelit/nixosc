# modules/home/scripts/bin/rofi-launcher.sh
#!/usr/bin/env bash

if [[ "$1" == "--Keys" ]]; then
	hypr-keybinds | rofi -dmenu -theme-str 'window {width: 50%;} listview {columns: 1;}'
else
	SELECTED=$(rofi \
		-show combi \
		-combi-modi 'drun,run,window,filebrowser,ssh' \
		-modi "combi,drun,run,window,filebrowser,Keys:hypr-keybinds,ssh" \
		-show-icons \
		-matching fuzzy \
		-sort \
		-sorting-method "fzf" \
		-drun-match-fields "name,generic,exec,categories,keywords" \
		-window-match-fields "title,class,name,desktop" \
		-drun-display-format "{name} [<span weight='light' size='small'><i>({generic})</i></span>]")

	if [ -n "$SELECTED" ]; then
		rofi-frecency --add "$SELECTED"
		eval "$SELECTED"
	fi
fi
