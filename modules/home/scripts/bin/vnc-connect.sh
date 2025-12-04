#!/usr/bin/env bash

# Pass'dan VNC parolasını al
VNC_PASS=$(pass vncpass 2>/dev/null)

# VNC parola dosyası yoksa oluştur
if [ ! -f ~/.vnc/passwd ]; then
	mkdir -p ~/.vnc/
	vncpasswd -f <<<"$VNC_PASS" >~/.vnc/passwd
	chmod 600 ~/.vnc/passwd
fi

# VNC bağlantısını kur
vncviewer localhost:5901 -SecurityTypes VncAuth -passwd ~/.vnc/passwd
