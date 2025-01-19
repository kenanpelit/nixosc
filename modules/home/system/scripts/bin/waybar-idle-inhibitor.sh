#!/usr/bin/env bash

# Hyprland idle durumunu kontrol eden script
IDLE_INHIBITOR_STATUS=$(hyprctl clients | grep -oP '(?<=idle_inhibitor: )\w+')

if [[ "$IDLE_INHIBITOR_STATUS" == "active" ]]; then
  # Eğer aktifse, deactivated simgesi
  echo "{\"text\":\"  \", \"tooltip\":\"Idle Inhibitor Deactivated\"}"
else
  # Eğer devre dışıysa, activated simgesi
  echo "{\"text\":\"  \", \"tooltip\":\"Idle Inhibitor Activated\"}"
fi
