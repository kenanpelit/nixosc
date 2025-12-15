#!/usr/bin/env bash
# osc-vradio.sh - VRadio istasyon başlatıcı
# vrun/vradio listeleriyle hızlı seçim yapıp mpv üzerinden çalar.

# Kill existing instances first
pkill -f "osc-radio" && pkill -f "cvlc" 2>/dev/null

# Wait for processes to clean up
sleep 1

# Start tradio with the requested station
osc-radio -t 1
