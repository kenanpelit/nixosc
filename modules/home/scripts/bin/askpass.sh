#!/usr/bin/env bash
# askpass.sh - rofi tabanlı sudo parola istemi
# GUI gerektirmeden dmenu modunda parola alır; sudo için askpass olarak
# kullanılabilir.
rofi -dmenu -password -p "Sudo Password:" -theme-str 'entry { placeholder: "Enter sudo password..."; }' -theme-str 'window { width: 30%; }'
