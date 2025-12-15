#!/usr/bin/env bash
# lofi.sh - mpv ile YouTube lo-fi radyo akışı başlatıcı
# mpv + ytdlp kullanarak favori radyo URL’lerini çalıştırır, ses/ayar parametreleriyle.

if (ps aux | grep mpv | grep -v grep > /dev/null); then
    pkill mpv
else
    runbg mpv --no-video https://www.youtube.com/live/jfKfPfyJRdk?si=OF0HKrYFFj33BzMo
fi
