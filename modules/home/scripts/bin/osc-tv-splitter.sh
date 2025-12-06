#!/usr/bin/env bash
#===============================================================================
# IPTV Channel Splitter and Player
# This script:
# 1. Clones/updates the iptv-org/iptv repository to ~/.apps/iptv
# 2. Processes tr.m3u from the streams directory
# 3. Splits channels into individual .m3u files in ~/.iptv/channels
# 4. Creates executable scripts in ~/.iptv/bin
# Author: Kenan Pelit | https://github.com/kenanpelit/nixosc
# Version: 1.1
#===============================================================================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
APPS_DIR="$HOME/.apps"
IPTV_DIR="$APPS_DIR/iptv"
CHANNELS_DIR="$HOME/.iptv/channels"
SCRIPTS_DIR="$HOME/.iptv/bin"

# Helper functions
error() {
	echo -e "${RED}ERROR: $1${NC}" >&2
	exit 1
}

success() {
	echo -e "${GREEN}✓ $1${NC}"
}

info() {
	echo -e "${YELLOW}→ $1${NC}"
}

# Check dependencies
info "Checking dependencies..."
for cmd in git mpv; do
	command -v "$cmd" >/dev/null 2>&1 || error "Required command not found: $cmd"
done
success "Dependencies OK"

# Create necessary directories
info "Creating directories..."
mkdir -p "$APPS_DIR" "$CHANNELS_DIR" "$SCRIPTS_DIR" || error "Failed to create directories"
success "Directories created"

# Clone or update iptv repository
info "Managing IPTV repository..."
if [ -d "$IPTV_DIR" ]; then
	cd "$IPTV_DIR" || error "Cannot change to IPTV directory"
	git pull origin master >/dev/null 2>&1 || error "Git pull failed"
	success "Repository updated"
else
	cd "$APPS_DIR" || error "Cannot change to apps directory"
	git clone --depth 1 https://github.com/iptv-org/iptv >/dev/null 2>&1 || error "Git clone failed"
	success "Repository cloned"
fi

# Validate M3U file
M3U_FILE="$IPTV_DIR/streams/tr.m3u"
[ -f "$M3U_FILE" ] || error "M3U file not found: $M3U_FILE"
[ -r "$M3U_FILE" ] || error "M3U file not readable"
success "M3U file validated"

# Process tr.m3u file
info "Processing M3U file..."
cd "$IPTV_DIR/streams" || error "Cannot change to streams directory"

# Clean old files
rm -f "$CHANNELS_DIR"/*.m3u 2>/dev/null
rm -f "$SCRIPTS_DIR"/tv-* 2>/dev/null

# Initialize counters
processed_count=0
current_file=""

# Process file line by line
while IFS= read -r line || [ -n "$line" ]; do
	if [[ $line == \#EXTINF* ]]; then
		# Extract channel ID
		channel_id=$(echo "$line" | grep -o 'tvg-id="[^"]*"' | cut -d'"' -f2)

		# Extract channel name (everything after the last comma)
		channel_name=$(echo "$line" | sed 's/.*,//')

		if [ -n "$channel_id" ]; then
			# Sanitize channel ID for filename
			safe_id=$(echo "$channel_id" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/_/g')

			current_file="$CHANNELS_DIR/${safe_id}.m3u"
			script_name="tv-${safe_id}"

			# Create M3U file
			echo "$line" >"$current_file" || error "Failed to create channel file"

			# Create executable script for this channel
			cat >"$SCRIPTS_DIR/$script_name" <<EOF
#!/usr/bin/env bash
# TV Script for: $channel_name
# Channel ID: $channel_id
mpv --no-resume-playback --title="$channel_name" "$current_file"
EOF
			chmod +x "$SCRIPTS_DIR/$script_name" || error "Failed to make script executable"

			((processed_count++))
		else
			current_file=""
		fi

	elif [[ $line == http* ]] && [ -n "$current_file" ]; then
		# Add stream URL to current channel file
		echo "$line" >>"$current_file" || error "Failed to append URL to channel file"
	fi

done <"tr.m3u"

success "Processing completed"

# Show results
echo
echo "==============================================="
echo -e "${GREEN}Process completed successfully!${NC}"
echo "==============================================="
echo "📺 Channels processed: $processed_count"
echo "📁 M3U files: $CHANNELS_DIR"
echo "🎬 TV scripts: $SCRIPTS_DIR"
echo
echo "🚀 Usage:"
echo "   Add to PATH: export PATH=\"$SCRIPTS_DIR:\$PATH\""
echo "   Then run: tv-<channel-name>"
echo
echo "📋 Sample channels:"
find "$SCRIPTS_DIR" -name "tv-*" -type f | head -5 | while read -r script; do
	echo "   $(basename "$script")"
done

total_scripts=$(find "$SCRIPTS_DIR" -name "tv-*" -type f | wc -l)
if [ "$total_scripts" -gt 5 ]; then
	echo "   ... and $((total_scripts - 5)) more"
fi

echo
echo "✨ All done!"
