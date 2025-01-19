#!/bin/sh
# Toggle wf-recorder and update waybar

if pid=$(pgrep wf-recorder); then
	kill -s INT "$pid"
	: > /tmp/RECORDING
else
	wf-recorder &
	echo '' > /tmp/RECORDING
fi
pkill -RTMIN+8 waybar
