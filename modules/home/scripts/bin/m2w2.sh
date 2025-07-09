#!/usr/bin/env bash
hyprctl dispatch focusmonitor DP-3
sleep 0.2 # Kısa bir bekleme monitör geçişinin tamamlanması için
hyprctl dispatch workspace 2
