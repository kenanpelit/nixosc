#!/usr/bin/env bash
# Enhanced script to connect Linux to Android device over USB or WiFi and mirror display

# Global variables
CONFIG_DIR="$HOME/.config/scrcpy"
IP_FILE="$CONFIG_DIR/ip.txt"
LOG_FILE="$CONFIG_DIR/prog.log"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Check for dependencies
check_dependencies() {
	if ! command -v scrcpy >/dev/null; then
		zenity --error --text="scrcpy is not installed. Please install it first." --width=300
		exit 1
	fi

	if ! command -v adb >/dev/null; then
		zenity --error --text="adb is not installed. Please install Android Debug Bridge first." --width=300
		exit 1
	fi

	if ! command -v zenity >/dev/null; then
		echo "Zenity is not installed. Using terminal for messages instead."
		USE_TERMINAL=true
	else
		USE_TERMINAL=false
	fi
}

# Display messages using either zenity or terminal
show_message() {
	local type=$1
	local message=$2
	local title=$3
	local width=${4:-300}
	local height=${5:-150}

	if [ "$USE_TERMINAL" = true ]; then
		case $type in
		"info")
			echo -e "INFO: $message"
			read -p "Press Enter to continue..." </dev/tty
			;;
		"error")
			echo -e "ERROR: $message"
			read -p "Press Enter to continue..." </dev/tty
			;;
		*)
			echo -e "$message"
			read -p "Press Enter to continue..." </dev/tty
			;;
		esac
	else
		case $type in
		"info")
			zenity --info --text="$message" --title="$title" --width=$width --height=$height
			;;
		"error")
			zenity --error --text="$message" --title="$title" --width=$width --height=$height
			;;
		*)
			zenity --info --text="$message" --title="$title" --width=$width --height=$height
			;;
		esac
	fi
}

# Reset ADB server
reset_adb() {
	echo "Restarting ADB server..."
	adb kill-server
	adb start-server
	adb devices
}

# Connect to device over USB
usb_connect() {
	show_message "info" "Connect your phone via USB. Make sure the phone is unlocked and USB debugging is enabled.\n\nClick OK to continue." "USB Connection"

	# Wait for device to be connected
	adb wait-for-device

	# Check if device is connected
	if ! adb devices | grep -q "device$"; then
		show_message "error" "No device detected. Please check your USB connection and make sure USB debugging is enabled." "Connection Error"
		exit 1
	fi

	show_message "info" "USB connection successful!" "Connection Status"
}

# Setup WiFi connection
setup_wifi() {
	show_message "info" "Setting up WiFi connection. Make sure your phone and computer are on the same WiFi network.\n\nClick OK to continue." "WiFi Setup"

	# Switch to TCP/IP mode
	adb tcpip 5555
	sleep 3

	# Try to get device IP address from various interfaces
	local ipadd=""
	for interface in wlan0 wlp2s0 wlp3s0 wlp4s0 eth0; do
		ipadd=$(adb shell ip -f inet addr show $interface 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1)
		if [ ! -z "$ipadd" ]; then
			echo "Found IP address $ipadd on interface $interface"
			break
		fi
	done

	# If no IP found, try another method
	if [ -z "$ipadd" ]; then
		ipadd=$(adb shell ip route | grep -o 'src [0-9.]*' | cut -d ' ' -f 2 | head -n 1)
	fi

	# If still no IP found, exit with error
	if [ -z "$ipadd" ]; then
		show_message "error" "Could not find IP address. Check your WiFi connection and try again." "WiFi Error"
		return 1
	fi

	local ipfull="${ipadd}:5555"
	echo "$ipfull" >"$IP_FILE"

	# Connect to the device over WiFi
	if adb connect "$ipfull" | grep -q "connected"; then
		show_message "info" "WiFi connection successful!\n\nYou can now disconnect the USB cable." "WiFi Connection"
		return 0
	else
		show_message "error" "Failed to connect over WiFi. Please try again." "Connection Error"
		return 1
	fi
}

# Launch scrcpy with optimal settings
launch_scrcpy() {
	local options=""

	# Detect device characteristics and adjust settings accordingly
	local screen_size=$(adb shell wm size | cut -d':' -f2 | tr -d ' ')
	local width=$(echo $screen_size | cut -d'x' -f1)
	local height=$(echo $screen_size | cut -d'x' -f2)

	# For high-resolution screens, adjust settings for better performance
	if [ "$width" -gt 1080 ]; then
		options="--max-size 1080 --max-fps 60 --bit-rate 16M"
	else
		options="--max-fps 60 --bit-rate 8M"
	fi

	# Add window title
	options="$options --window-title \"Android Screen Mirror\""

	# Launch scrcpy with the determined options
	echo "Launching scrcpy with options: $options"
	eval "scrcpy $options > \"$LOG_FILE\" 2>&1 &"
	local pid=$!

	# Check if scrcpy started successfully
	sleep 3
	if grep -q "INFO" "$LOG_FILE" || ! grep -q "ERROR" "$LOG_FILE"; then
		echo "scrcpy started successfully with PID $pid"
		return 0
	else
		kill $pid 2>/dev/null
		echo "Failed to start scrcpy. Check the log at $LOG_FILE"
		cat "$LOG_FILE"
		return 1
	fi
}

# Try to connect using saved IP
try_saved_connection() {
	if [ -f "$IP_FILE" ]; then
		local storedip=$(head -n 1 "$IP_FILE")
		echo "Trying to connect to previously saved IP: $storedip"

		if adb connect "$storedip" 2>/dev/null | grep -q "connected"; then
			show_message "info" "Connected to saved device at $storedip" "Connection Status"
			return 0
		else
			show_message "info" "Could not connect to saved device. Will try a new connection." "Connection Status"
			return 1
		fi
	fi
	return 1
}

# Main function
main() {
	check_dependencies
	reset_adb

	# Check if already connected over WiFi
	if adb devices | grep -q "[0-9]\{1,3\}\.[0-9]\{1,3\}"; then
		show_message "info" "Already connected to a device over WiFi." "Connection Status"
		if ! launch_scrcpy; then
			show_message "error" "Failed to launch scrcpy. Check your connection and try again." "Launch Error"
			exit 1
		fi
	else
		# Try to connect using saved IP
		if try_saved_connection; then
			if ! launch_scrcpy; then
				show_message "error" "Failed to launch scrcpy with saved connection. Will try USB connection." "Launch Error"
				usb_connect
				if setup_wifi; then
					launch_scrcpy
				fi
			fi
		else
			# No saved connection or saved connection failed
			usb_connect
			if setup_wifi; then
				launch_scrcpy
			fi
		fi
	fi
}

# Run the main function
main
exit 0
