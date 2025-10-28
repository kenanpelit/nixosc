# modules/home/ytdlp/default.nix
# ==============================================================================
# Youtube-DL Configuration
# ==============================================================================
{ config, username, ... }:
{
  # =============================================================================
  # Configuration File
  # =============================================================================
  home.file.".config/yt-dlp/config".text = ''
    # ---------------------------------------------------------------------------
    # Video Quality and Format Settings
    # ---------------------------------------------------------------------------
    --format "(bestvideo[vcodec^=av01][height>=1080][fps>30]/bestvideo[vcodec^=vp9.2][height>=1080][fps>30]/bestvideo[vcodec^=vp9][height>=1080][fps>30]/bestvideo[vcodec^=avc1][height>=1080][fps>30]/bestvideo[height>=1080][fps>30]/bestvideo[vcodec^=av01][height>=1080]/bestvideo[vcodec^=vp9.2][height>=1080]/bestvideo[vcodec^=vp9][height>=1080]/bestvideo[vcodec^=avc1][height>=1080]/bestvideo[height>=1080]/bestvideo)+(bestaudio[acodec^=opus]/bestaudio)/best"
    # ---------------------------------------------------------------------------
    # YouTube Client Settings
    # ---------------------------------------------------------------------------
    --extractor-args "youtube:player_client=web_creator"
    # ---------------------------------------------------------------------------
    # Output Settings
    # ---------------------------------------------------------------------------
    --paths "$HOME/Videos/yt-dlp"
    --output "%(title)s.%(upload_date)s.%(resolution)s.%(vcodec)s.%(acodec)s.%(autonumber)02d.%(ext)s"
    --restrict-filenames
    --no-mtime
    --no-overwrites
    #--no-playlist
    # ---------------------------------------------------------------------------
    # Subtitle Settings
    # ---------------------------------------------------------------------------
    --write-sub
    --write-auto-sub
    --sub-langs "tur,tr,eng,en"
    --sub-format "ass/srt/best"
    --embed-subs
    # ---------------------------------------------------------------------------
    # Metadata Settings
    # ---------------------------------------------------------------------------
    --embed-metadata
    --embed-chapters
    --embed-thumbnail
    --convert-thumbnails webp
    # ---------------------------------------------------------------------------
    # Download Settings
    # ---------------------------------------------------------------------------
    --continue
    --min-sleep-interval 1
    --max-sleep-interval 2
    --concurrent-fragments 4
    --socket-timeout 30
    --extractor-retries 3
    --fragment-retries 3
    # ---------------------------------------------------------------------------
    # Interface Settings
    # ---------------------------------------------------------------------------
    --console-title
    --progress
    # ---------------------------------------------------------------------------
    # Browser Integration
    # ---------------------------------------------------------------------------
    #--cookies-from-browser firefox:/home/${username}/.zen/Kenp
    --cookies-from-browser brave:/home/${username}/.config/BraveSoftware/Brave-Browser/Default
  '';
}

