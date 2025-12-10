#!/usr/bin/env bash
# ssh-launcher.sh - SSH bağlantı menüsü
# tanımlı hostları fzf/rofi ile seçip ssh başlatır; agent durumunu kontrol eder.
cd $HOME
exec ssh "$@"
