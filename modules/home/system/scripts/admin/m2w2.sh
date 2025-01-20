#!/usr/bin/env bash
hyprctl dispatch focusmonitor DP-5
sleep 0.1 # Kısa bir bekleme monitör geçişinin tamamlanması için
hyprctl dispatch workspace 2
