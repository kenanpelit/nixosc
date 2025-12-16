#!/usr/bin/env bash
# niri-arrange-windows.sh
# Moves running applications to their designated named workspaces in Niri.
# Useful for restoring window layout after a messy session or restart.

#set -euo pipefail
set -x
# Define Rules: "AppID"="WorkspaceName"
declare -A RULES=(
  # Communication
  ["discord"]="5"
  ["WebCord"]="5"
  ["ferdium"]="9"

  # Media
  ["Spotify"]="8"
  ["spotify"]="8"

  # Tools/System
  ["org.keepassxc.KeePassXC"]="7"

      # Browsers (Profiles)
      ["Kenp"]="1"
      ["Ai"]="3"
      ["CompecTA"]="4"
      ["brave-youtube.com__-Default"]="7"
  )
  
  # Niri command
  NIRI="niri msg"
  
  echo "Scanning windows..."
  
  # Get all windows
  WINDOWS=$($NIRI -j windows)
  
  # Process each window
  echo "$WINDOWS" | jq -c '.[]' | while read -r win; do
      ID=$(echo "$win" | jq -r '.id')
      APP_ID=$(echo "$win" | jq -r '.app_id // empty')
      TITLE=$(echo "$win" | jq -r '.title // empty')
      
      # Skip share picker
      if [[ "$APP_ID" == "hyprland-share-picker" ]]; then continue; fi
      
      TARGET_WS=""
  
      # 1. Exact App ID Match
      if [[ -n "$APP_ID" && -v RULES["$APP_ID"] ]]; then
          TARGET_WS="${RULES[$APP_ID]}"
      fi
  
      # 2. Regex/Partial Match (if exact failed)
      if [[ -z "$TARGET_WS" && -n "$APP_ID" ]]; then
          if [[ "$APP_ID" == *"brave-youtube"* ]]; then TARGET_WS="7"; fi
      fi
  
      # Move if target found
      if [[ -n "$TARGET_WS" ]]; then
          echo " -> Moving '$APP_ID' (ID: $ID) to Workspace '$TARGET_WS'"
          
          # Try move by Name (quoted)
          if ! $NIRI action move-window-to-workspace --id "$ID" "$TARGET_WS" 2>/dev/null; then
              echo "    Move by name failed. Trying index..."
              # Try move by Index (unquoted, if numeric)
              if [[ "$TARGET_WS" =~ ^[0-9]+$ ]]; then
                   $NIRI action move-window-to-workspace --id "$ID" $TARGET_WS || echo "    Failed."
              else
                   echo "    Failed."
              fi
          else
              echo "    Success."
          fi
      fi
  done
  
  echo "Done."
