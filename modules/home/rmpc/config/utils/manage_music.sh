#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Music Management Utility
# Combines lyrics fetching, genre tagging, and metadata tagging.
# ==============================================================================

# --- Helpers ---

check_dependency() {
    if ! command -v "$1" &> /dev/null;
then
        echo "❌ Error: '$1' is not installed. Please install it."
        exit 1
    fi
}

usage() {
    echo "Usage: $0 <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  lyrics <album_dir>   Fetch synced lyrics from LRCLIB for all mp3s in a directory."
    echo "  genre <album_dir>    Interactively tag genres for mp3s in a directory."
    echo "  tag <album_dir>      Tag artist, album, and track titles (requires editing script or passing args)."
    echo ""
    exit 1
}

# --- Commands ---

cmd_lyrics() {
    check_dependency curl
    check_dependency jq

    if [ -z "${1:-}" ]; then
        echo "Usage: $0 lyrics <album_directory>"
        exit 1
    fi

    ALBUM_DIR="$1"
    if [ ! -d "$ALBUM_DIR" ]; then
        echo "Error: '$ALBUM_DIR' is not a directory."
        exit 1
    fi

    LRCLIB_API="https://lrclib.net/api/get"
    ARTIST="$(basename "$(dirname "$ALBUM_DIR")")"
    ALBUM="$(basename "$ALBUM_DIR")"

    echo "▶ Fetching lyrics for: $ARTIST - $ALBUM"

    shopt -s nullglob
    for mp3 in "$ALBUM_DIR"/*.mp3; do
        TITLE_RAW="$(basename "$mp3" .mp3)"
        LRC_FILE="${mp3%.mp3}.lrc"

        if [ -f "$LRC_FILE" ]; then
            echo "– Skipping \"$TITLE_RAW\" (already have .lrc)"
            continue
        fi

        # Fetch logic
        # 1. Try exact match
        LYRICS=$(curl -sG --data-urlencode "artist_name=${ARTIST}" --data-urlencode "track_name=${TITLE_RAW}" --data-urlencode "album_name=${ALBUM}" "$LRCLIB_API" | jq -r '.syncedLyrics')

        # 2. Try stripping (feat. ...)
        if [ -z "$LYRICS" ] || [ "$LYRICS" == "null" ]; then
            STRIPPED="$(echo "$TITLE_RAW" | sed -E 's/ *\([^)]*\)//g')"
            if [ "$STRIPPed" != "$TITLE_RAW" ]; then
                LYRICS=$(curl -sG --data-urlencode "artist_name=${ARTIST}" --data-urlencode "track_name=${STRIPPED}" --data-urlencode "album_name=${ALBUM}" "$LRCLIB_API" | jq -r '.syncedLyrics')
            fi
        fi

        if [ -z "$LYRICS" ] || [ "$LYRICS" == "null" ]; then
            echo "✗ No lyrics for: \"$TITLE_RAW\""
        else
            echo "$LYRICS" | sed -E '/^[[ar|al|ti]:/d' > "$LRC_FILE"
            echo "✔ Saved: $(basename "$LRC_FILE")"
        fi
    done
    echo "Done."
}

cmd_genre() {
    check_dependency eyeD3

    if [ -z "${1:-}" ]; then
        echo "Usage: $0 genre <album_directory>"
        exit 1
    fi

    DIR="$1"
    if [ ! -d "$DIR" ]; then
        echo "Error: '$DIR' is not a directory."
        exit 1
    fi

    cd "$DIR"

    # Get mp3s sorted by track number
    FILES=()
    while IFS= read -r line; do
        FILES+=("$line")
    done < <(
        for f in *.mp3; do
            [ -e "$f" ] || continue
            track_num=$(eyeD3 "$f" 2>/dev/null | grep -i "^track:" | awk '{print $2}' | cut -d/ -f1)
            printf "%03d|%s\n" "${track_num:-999}" "$f"
        done | sort | cut -d'|' -f2
    )

    for file in "${FILES[@]}"; do
        [[ -f "$file" ]] || continue
        echo ""
        echo "🎵 Now tagging: $file"
        eyeD3 --no-color "$file" | grep -Ei "title:|track:|genre:"
        
        read -rp "Enter genre(s) (comma-separated): " genre
        if [[ -n "$genre" ]]; then
            eyeD3 --genre="$genre" "$file"
            echo "✅ Set genre to: $genre"
        else
            echo "⏭️  Skipped."
        fi
    done
}

cmd_tag() {
    check_dependency eyeD3
    
    # This was originally a script you edited manually. 
    # To make it generic, we'd need to supply arguments or a file list.
    # For now, I'll provide a warning that this requires manual input or a track list file.
    
    echo "ℹ️  The 'tag' command requires a list of track titles to function correctly."
    echo "ℹ️  Please provide a file named 'tracks.txt' in the album directory with one song title per line."
    
    if [ -z "${1:-}" ]; then
        echo "Usage: $0 tag <album_directory>"
        exit 1
    fi

    DIR="$1"
    TRACKS_FILE="$DIR/tracks.txt"

    if [ ! -f "$TRACKS_FILE" ]; then
        echo "❌ Error: '$TRACKS_FILE' not found."
        echo "Create it with one track title per line, in the correct order."
        exit 1
    fi

    ARTIST="$(basename "$(dirname "$DIR")")"
    ALBUM="$(basename "$DIR")"
    
    echo "Artist: $ARTIST"
    echo "Album:  $ALBUM"
    echo "Reading tracks from: $TRACKS_FILE"
    
    cd "$DIR"
    
    # Read tracks into array
    mapfile -t TRACKS < "tracks.txt"
    
    for i in "${!TRACKS[@]}"; do
        track_num=$((i + 1))
        title="${TRACKS[$i]}"
        # Assuming filenames match titles or are generic like '01.mp3' - this part is tricky generically.
        # We will try to find a file that matches the title OR simply rename files like '01.mp3', 'Track 1.mp3' etc if they exist?
        # To be safe, let's assume the user has files named exactly "$title.mp3".
        
        filename="$title.mp3"
        
        if [[ ! -f "$filename" ]]; then
             # Try fallback: look for file starting with track num?
             # For safety, let's just warn.
             echo "⚠️ File '$filename' not found. Skipping."
             continue
        fi

        echo "✅ Tagging: $filename"
        eyeD3 -a "$ARTIST" -A "$ALBUM" -t "$title" -n "$track_num" "$filename"
    done
}

# --- Main Dispatcher ---

if [ $# -lt 1 ]; then
    usage
fi

COMMAND="$1"
shift

case "$COMMAND" in
    lyrics)
        cmd_lyrics "$@"
        ;;    genre)
        cmd_genre "$@"
        ;;    tag)
        cmd_tag "$@"
        ;;    *)
        usage
        ;;esac
