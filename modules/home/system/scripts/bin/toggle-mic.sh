#!/usr/bin/env bash

# Pamixer ile mikrofon durumunu kontrol et
if pamixer --get-mute --source 0 | grep -q "true"; then
	echo "Unmuting microphone"
	pamixer --unmute --source 0
	echo 0 | sudo tee /sys/class/leds/platform::micmute/brightness >/dev/null
	echo "LED OFF"
else
	echo "Muting microphone"
	pamixer --mute --source 0
	echo 1 | sudo tee /sys/class/leds/platform::micmute/brightness >/dev/null
	echo "LED ON"
fi

echo "Final status: $(pamixer --get-mute --source 0)"
