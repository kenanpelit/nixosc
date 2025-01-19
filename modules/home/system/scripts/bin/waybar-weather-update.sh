#!/usr/bin/env bash

notify-send "Hava Durumu" "Güncelleniyor..." -i weather-clear
rm -f /tmp/weather.cache
pkill -RTMIN+8 waybar
sleep 2
notify-send "Hava Durumu" "Güncelleme tamamlandı" -i weather-clear
