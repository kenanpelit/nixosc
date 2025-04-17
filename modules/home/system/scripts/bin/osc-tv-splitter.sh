#!/usr/bin/env bash

# IPTV Channel Splitter and Player
# This script:
# 1. Clones/updates the iptv-org/iptv repository to ~/.apps/iptv
# 2. Processes tr.m3u from the streams directory
# 3. Splits channels into individual .m3u files in ~/.iptv/channels
# 4. Creates executable scripts in ~/.iptv/bin
# Author: Kenan Pelit | https://github.com/kenanpelit/nixosc
# Version: 1.0

APPS_DIR="$HOME/.apps"
IPTV_DIR="$APPS_DIR/iptv"
CHANNELS_DIR="$HOME/.iptv/channels"
SCRIPTS_DIR="$HOME/.iptv/bin"

# Create necessary directories
mkdir -p "$APPS_DIR" "$CHANNELS_DIR" "$SCRIPTS_DIR"

# Clone or update iptv repository
if [ -d "$IPTV_DIR" ]; then
	cd "$IPTV_DIR"
	git pull origin master
else
	cd "$APPS_DIR"
	git clone --depth 1 https://github.com/iptv-org/iptv
fi

# Process tr.m3u file
cd "$IPTV_DIR/streams"

# Clean old files
rm -f "$CHANNELS_DIR"/*.m3u
rm -f "$SCRIPTS_DIR"/tv-*

while IFS= read -r line; do
	if [[ $line == \#EXTINF* ]]; then
		channel_id=$(echo "$line" | grep -o 'tvg-id="[^"]*"' | cut -d'"' -f2)
		channel_name=$(echo "$line" | grep -o ',[^,]*$' | cut -d',' -f2)
		if [ ! -z "$channel_id" ]; then
			current_file="$CHANNELS_DIR/${channel_id}.m3u"
			script_name="tv-${channel_id,,}" # lowercase version
			echo "$line" >"$current_file"

			# Create executable script for this channel
			cat >"$SCRIPTS_DIR/$script_name" <<EOF
#!/usr/bin/env bash
mpv --no-resume-playback "$CHANNELS_DIR/${channel_id}.m3u"
EOF
			chmod +x "$SCRIPTS_DIR/$script_name"
		fi
	elif [[ $line == http* ]] && [ ! -z "$current_file" ]; then
		echo "$line" >>"$current_file"
	fi
done <"tr.m3u"

echo "Process completed:"
echo "- M3U files are in $CHANNELS_DIR"
echo "- Channel scripts are in $SCRIPTS_DIR"
echo "- Add $SCRIPTS_DIR to your PATH to run tv-* commands"
