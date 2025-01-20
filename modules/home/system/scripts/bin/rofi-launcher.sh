# modules/home/scripts/bin/rofi-launcher.sh
#!/usr/bin/env bash

if [[ "$1" == "--keys" ]]; then
	./hypr-keybinds | rofi -dmenu -theme-str 'window {width: 50%;} listview {columns: 1;}'
else
	rofi \
		-show combi \
		-combi-modi 'drun,run,window,ssh,filebrowser' \
		-modi "combi,drun,run,window,ssh,filebrowser,keys:./hypr-keybinds" \
		-show-icons \
		-matching fuzzy
fi
