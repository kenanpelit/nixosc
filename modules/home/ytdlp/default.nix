{ config, ... }:

{
 home.file.".config/yt-dlp/config".text = ''
   --format "(bestvideo[vcodec^=av01][height>=1080][fps>30]/bestvideo[vcodec^=vp9.2][height>=1080][fps>30]/bestvideo[vcodec^=vp9][height>=1080][fps>30]/bestvideo[vcodec^=avc1][height>=1080][fps>30]/bestvideo[height>=1080][fps>30]/bestvideo[vcodec^=av01][height>=1080]/bestvideo[vcodec^=vp9.2][height>=1080]/bestvideo[vcodec^=vp9][height>=1080]/bestvideo[vcodec^=avc1][height>=1080]/bestvideo[height>=1080]/bestvideo)+(bestaudio[acodec^=opus]/bestaudio)/best"
   --paths "$HOME/Videos/yt-dlp"
   --output "%(title)s.%(upload_date)s.%(resolution)s.%(vcodec)s.%(acodec)s.%(autonumber)02d.%(ext)s"
   --restrict-filenames
   --no-mtime
   --write-sub
   --write-auto-sub
   --sub-langs "tur,tr,eng,en"
   --sub-format "ass/srt/best"
   --embed-subs
   --embed-metadata
   --embed-chapters
   --embed-thumbnail
   --convert-thumbnails webp
   --no-overwrites
   --no-playlist
   --continue
   --min-sleep-interval 1
   --max-sleep-interval 2
   --concurrent-fragments 4
   --socket-timeout 30
   --extractor-retries 3
   --fragment-retries 3
   --console-title
   --progress
   --cookies-from-browser firefox:/home/kenan/.zen/Kenp
 '';
}
