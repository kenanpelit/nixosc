#!/usr/bin/env bash

# Mikrofonu toggle et
pamixer --toggle-mute --source 0

# Durumu kontrol et ve LED'i buna göre ayarla
if pamixer --get-mute --source 0 | grep -q "true"; then
	echo 1 | sudo tee /sys/class/leds/platform::micmute/brightness >/dev/null
	echo "Microphone MUTED - LED ON"
else
	echo 0 | sudo tee /sys/class/leds/platform::micmute/brightness >/dev/null
	echo "Microphone UNMUTED - LED OFF"
fi
