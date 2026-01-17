#!/usr/bin/env sh

# ==============================================================================
# Unified On Song Change Script for rmpc
# Combines: increment_play_count + notify
# ==============================================================================

# --- PART 1: Increment Play Count ---

# Check for jq dependency
if command -v jq >/dev/null 2>&1; then
    if [ -n "$FILE" ]; then
        # Get current play count, defaulting to 0 if null/empty
        current_count=$(rmpc sticker get "$FILE" "playCount" 2>/dev/null | jq -r '.value // 0')
        
        # Increment count
        new_count=$((current_count + 1))
        
        # Set the new count
        rmpc sticker set "$FILE" "playCount" "$new_count"
    fi
    # If FILE is empty or jq missing, we silently skip counting but continue to notify
fi

# --- PART 2: Send Notification ---

# Check for notify-send dependency
if command -v notify-send >/dev/null 2>&1; then
    
    # Directory where to store temporary data
    TMP_DIR="/tmp/rmpc"
    mkdir -p "$TMP_DIR"

    # Generate a unique filename to bypass caching
    TIMESTAMP=$(date +%s)
    ALBUM_ART_PATH="$TMP_DIR/notification_cover_$TIMESTAMP"

    # Clean up old covers
    rm -f "$TMP_DIR"/notification_cover_*

    # Fallback Image
    DEFAULT_ALBUM_ART_PATH="$HOME/.config/rmpc/assets/rmpc_screenshot.png"

    # Try to fetch album art
    if ! rmpc albumart --output "$ALBUM_ART_PATH" >/dev/null 2>&1; then
        if [ -f "$DEFAULT_ALBUM_ART_PATH" ]; then
            ALBUM_ART_PATH="$DEFAULT_ALBUM_ART_PATH"
        else
            ALBUM_ART_PATH="audio-x-generic"
        fi
    fi

    # Send notification
    # -h string:x-canonical-private-synchronous:rmpc replaces previous notification
    notify-send \
        -i "$ALBUM_ART_PATH" \
        -h string:x-canonical-private-synchronous:rmpc \
        "Now Playing" \
        "${TITLE:-Unknown Title}
${ARTIST:-Unknown Artist}"
fi