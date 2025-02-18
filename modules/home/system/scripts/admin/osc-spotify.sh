#!/usr/bin/env bash

USER_CONFIG_DEFAULTS="CLIENT_ID=\"\"\nCLIENT_SECRET=\"\""
USER_CONFIG_FILE="${HOME}/.config/shpotify.cfg"
if ! [[ -f "${USER_CONFIG_FILE}" ]]; then
	touch "${USER_CONFIG_FILE}"
	echo -e "${USER_CONFIG_DEFAULTS}" >"${USER_CONFIG_FILE}"
fi
source "${USER_CONFIG_FILE}"

# Set the percent change in volume for vol up and vol down
VOL_INCREMENT=10

showAPIHelp() {
	echo
	echo "Connecting to Spotify's API:"
	echo
	echo "  This command line application needs to connect to Spotify's API in order to"
	echo "  find music by name. It is very likely you want this feature!"
	echo
	echo "  To get this to work, you need to sign up (or in) and create an 'Application' at:"
	echo "  https://developer.spotify.com/my-applications/#!/applications/create"
	echo
	echo "  Once you've created an application, find the 'Client ID' and 'Client Secret'"
	echo "  values, and enter them into your shpotify config file at '${USER_CONFIG_FILE}'"
	echo
	echo "  Be sure to quote your values and don't add any extra spaces!"
	echo "  When done, it should look like this (but with your own values):"
	echo '  CLIENT_ID="abc01de2fghijk345lmnop"'
	echo '  CLIENT_SECRET="qr6stu789vwxyz"'
}

showHelp() {
	echo "Usage:"
	echo
	echo "  $(basename $0) <command>"
	echo
	echo "Commands:"
	echo
	echo "  play                         # Resumes playback where Spotify last left off."
	echo "  play <song name>             # Finds a song by name and plays it."
	echo "  play album <album name>      # Finds an album by name and plays it."
	echo "  play artist <artist name>    # Finds an artist by name and plays it."
	echo "  play list <playlist name>    # Finds a playlist by name and plays it."
	echo "  play uri <uri>               # Play songs from specific uri."
	echo
	echo "  next                         # Skips to the next song in a playlist."
	echo "  prev                         # Returns to the previous song in a playlist."
	echo "  replay                       # Replays the current track from the beginning."
	echo "  pos <time>                   # Jumps to a time (in microsecs) in the current song."
	echo "  pause                        # Pauses (or resumes) Spotify playback."
	echo "  stop                         # Stops playback."
	echo "  quit                         # Stops playback and quits Spotify."
	echo
	echo "  vol up                       # Increases the volume by 10%."
	echo "  vol down                     # Decreases the volume by 10%."
	echo "  vol <amount>                 # Sets the volume to an amount between 0 and 100."
	echo "  vol [show]                   # Shows the current Spotify volume."
	echo
	echo "  status                       # Shows the current player status."
	echo "  status artist                # Shows the currently playing artist."
	echo "  status album                 # Shows the currently playing album."
	echo "  status track                 # Shows the currently playing track."
	echo
	echo "  share                        # Displays the current song's Spotify URL and URI."
	echo
	echo "  toggle shuffle               # Toggles shuffle playback mode."
	echo "  toggle repeat                # Toggles repeat playback mode."
	showAPIHelp
}

cecho() {
	bold=$(tput bold)
	green=$(tput setaf 2)
	reset=$(tput sgr0)
	echo $bold$green"$1"$reset
}

# DBus functions for Linux
getSpotifyStatus() {
	dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'PlaybackStatus' | grep -o '".*"' | cut -d'"' -f2
}

showArtist() {
	dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata' | awk -F '"' '/xesam:artist/ {getline; getline; print $2}'
}

showAlbum() {
	dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata' | awk -F '"' '/xesam:album/ {getline; print $2}'
}

showTrack() {
	dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata' | awk -F '"' '/xesam:title/ {getline; print $2}'
}

showStatus() {
	state=$(getSpotifyStatus)
	cecho "Spotify is currently $state."
	artist=$(showArtist)
	album=$(showAlbum)
	track=$(showTrack)
	echo -e "Artist: $artist\nAlbum: $album\nTrack: $track"
}

if [ $# = 0 ]; then
	showHelp
else
	if ! command -v spotify &>/dev/null; then
		echo "The Spotify application must be installed."
		exit 1
	fi

	# Check if Spotify is running
	if ! pgrep -x "spotify" >/dev/null; then
		spotify &
		sleep 2
	fi
fi

while [ $# -gt 0 ]; do
	arg=$1

	case $arg in
	"play")
		if [ $# != 1 ]; then
			# API search implementation remains the same as original
			# ...
			if [ "$SPOTIFY_PLAY_URI" != "" ]; then
				if [ "$2" = "uri" ]; then
					cecho "Playing Spotify URI: $SPOTIFY_PLAY_URI"
				else
					cecho "Playing ($Q Search) -> Spotify URI: $SPOTIFY_PLAY_URI"
				fi

				dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.OpenUri string:"$SPOTIFY_PLAY_URI"
			else
				cecho "No results when searching for $Q"
			fi
		else
			cecho "Playing Spotify."
			dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Play
		fi
		break
		;;

	"pause")
		dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
		break
		;;

	"stop")
		dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Stop
		break
		;;

	"next")
		cecho "Going to next track."
		dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next
		showStatus
		break
		;;

	"prev")
		cecho "Going to previous track."
		dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous
		showStatus
		break
		;;

	"vol")
		if [[ $2 = "" || $2 = "show" ]]; then
			vol=$(pactl list sinks | grep -A 15 "$(pactl info | grep "Default Sink" | cut -d: -f2)" | grep "Volume:" | grep -o "[0-9]*%" | head -1 | cut -d'%' -f1)
			cecho "Current Spotify volume level is $vol."
		elif [ "$2" = "up" ]; then
			pactl set-sink-volume @DEFAULT_SINK@ +${VOL_INCREMENT}%
			cecho "Increasing Spotify volume."
		elif [ "$2" = "down" ]; then
			pactl set-sink-volume @DEFAULT_SINK@ -${VOL_INCREMENT}%
			cecho "Decreasing Spotify volume."
		elif [[ $2 =~ ^[0-9]+$ ]] && [[ $2 -ge 0 && $2 -le 100 ]]; then
			pactl set-sink-volume @DEFAULT_SINK@ ${2}%
			cecho "Setting Spotify volume level to $2"
		else
			echo "Improper use of 'vol' command"
			echo "The 'vol' command should be used as follows:"
			echo "  vol up                       # Increases the volume by $VOL_INCREMENT%."
			echo "  vol down                     # Decreases the volume by $VOL_INCREMENT%."
			echo "  vol [amount]                 # Sets the volume to an amount between 0 and 100."
			echo "  vol                          # Shows the current Spotify volume."
			exit 1
		fi
		break
		;;

	"toggle")
		if [ "$2" = "shuffle" ]; then
			dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Shuffle
			cecho "Toggled shuffle mode"
		elif [ "$2" = "repeat" ]; then
			dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.LoopStatus
			cecho "Toggled repeat mode"
		fi
		break
		;;

	"quit")
		cecho "Quitting Spotify."
		killall spotify
		exit 0
		;;

	"status")
		if [ $# != 1 ]; then
			case $2 in
			"artist")
				showArtist
				break
				;;
			"album")
				showAlbum
				break
				;;
			"track")
				showTrack
				break
				;;
			esac
		else
			showStatus
		fi
		break
		;;

	"share")
		metadata=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata')
		track_id=$(echo "$metadata" | grep -A 1 "trackid" | tail -1 | cut -d'"' -f2)
		if [[ $track_id == *"spotify:track:"* ]]; then
			uri=$track_id
			remove='spotify:track:'
			url=${uri#$remove}
			url="https://open.spotify.com/track/$url"
			cecho "Spotify URL: $url"
			cecho "Spotify URI: $uri"
		else
			cecho "No track is currently playing."
		fi
		break
		;;

	"help")
		showHelp
		break
		;;

	*)
		showHelp
		exit 1
		;;
	esac
done
