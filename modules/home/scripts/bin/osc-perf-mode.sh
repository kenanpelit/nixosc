#!/usr/bin/env bash
# Performance Control Script for ThinkPad - Hardware Config Compatible

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# CPU detection from hardware config
detect_cpu() {
	CPU_INFO=$(cat /proc/cpuinfo 2>/dev/null || echo "")

	if echo "$CPU_INFO" | grep -qE "155H|Ultra|Meteor Lake"; then
		echo "meteolake"
	elif echo "$CPU_INFO" | grep -qE "8650U|8550U|8250U|8350U|Kaby Lake"; then
		echo "kabylaker"
	else
		echo "kabylaker" # Default to conservative
	fi
}

# Get power source
get_power_source() {
	for PS in /sys/class/power_supply/A{C,C0,DP1}/online; do
		[ -f "$PS" ] && echo $(cat "$PS") && return
	done
	echo "0"
}

# Check if running as root
check_root() {
	if [[ $EUID -ne 0 ]]; then
		echo -e "${RED}This script must be run with sudo${NC}"
		exit 1
	fi
}

# Get current status
get_status() {
	echo -e "${BLUE}=== Current System Status ===${NC}"

	# Detect CPU type
	CPU_TYPE=$(detect_cpu)
	ON_AC=$(get_power_source)
	echo -e "CPU Type: ${YELLOW}$CPU_TYPE${NC}"
	echo -e "Power Source: ${YELLOW}$([ "$ON_AC" = "1" ] && echo "AC" || echo "Battery")${NC}"

	# Governor
	if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
		GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
		echo -e "Governor: ${YELLOW}$GOVERNOR${NC}"
	else
		echo -e "Governor: ${RED}Not available${NC}"
	fi

	# Turbo Boost
	if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
		TURBO=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
		if [ "$TURBO" = "0" ]; then
			echo -e "Turbo: ${GREEN}Enabled${NC}"
		else
			echo -e "Turbo: ${RED}Disabled${NC}"
		fi
	fi

	# Current frequencies
	echo -e "\nCPU Frequencies:"
	if grep -q "cpu MHz" /proc/cpuinfo 2>/dev/null; then
		grep "cpu MHz" /proc/cpuinfo | head -4 | awk '{print "  Core " NR-1 ": " $4 " MHz"}'
	else
		echo "  Frequency info not available"
	fi

	# Power limits
	if [ -d /sys/class/powercap/intel-rapl:0 ]; then
		PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo "0")
		PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo "0")
		echo -e "\nPower Limits:"
		echo -e "  PL1: $((PL1 / 1000000))W"
		echo -e "  PL2: $((PL2 / 1000000))W"
	else
		echo -e "\nPower Limits: ${RED}RAPL not available${NC}"
	fi

	# Temperature
	TEMP_FILES=$(ls /sys/class/thermal/thermal_zone*/temp 2>/dev/null || true)
	if [ -n "$TEMP_FILES" ]; then
		TEMP=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1 || echo "0")
		echo -e "\nCPU Temp: ${YELLOW}$((TEMP / 1000))°C${NC}"
	else
		echo -e "\nCPU Temp: ${RED}Not available${NC}"
	fi

	# auto-cpufreq status
	if systemctl is-active --quiet auto-cpufreq; then
		echo -e "auto-cpufreq: ${GREEN}Active${NC}"
	else
		echo -e "auto-cpufreq: ${RED}Inactive${NC}"
	fi

	# Battery charge thresholds if available
	if [ -f /sys/class/power_supply/BAT0/charge_control_start_threshold ]; then
		START_THRESH=$(cat /sys/class/power_supply/BAT0/charge_control_start_threshold 2>/dev/null || echo "N/A")
		STOP_THRESH=$(cat /sys/class/power_supply/BAT0/charge_control_end_threshold 2>/dev/null || echo "N/A")
		echo -e "Battery Thresholds: ${YELLOW}Start: ${START_THRESH}% | Stop: ${STOP_THRESH}%${NC}"
	fi
}

# Set performance mode
set_performance() {
	echo -e "${GREEN}Setting PERFORMANCE mode...${NC}"

	CPU_TYPE=$(detect_cpu)

	# Set governor
	cpupower frequency-set -g performance 2>/dev/null || true

	# Enable turbo
	echo 0 >/sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true

	# Set appropriate power limits based on CPU type
	if [ -d /sys/class/powercap/intel-rapl:0 ]; then
		if [ "$CPU_TYPE" = "meteolake" ]; then
			echo 45000000 >/sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || true
			echo 55000000 >/sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || true
			echo "Power limits set: 45W/55W (Meteor Lake)"
		else
			echo 30000000 >/sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || true
			echo 40000000 >/sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || true
			echo "Power limits set: 30W/40W (Kaby Lake R)"
		fi
	fi

	# Remove frequency limits
	cpupower frequency-set -u 4.8GHz 2>/dev/null || true
	cpupower frequency-set -d 800MHz 2>/dev/null || true

	# Ensure auto-cpufreq is stopped to prevent conflicts
	systemctl stop auto-cpufreq 2>/dev/null || true

	echo -e "${GREEN}Performance mode activated!${NC}"
}

# Set powersave mode
set_powersave() {
	echo -e "${BLUE}Setting POWERSAVE mode...${NC}"

	CPU_TYPE=$(detect_cpu)

	# Set governor
	cpupower frequency-set -g powersave 2>/dev/null || true

	# Disable turbo for maximum savings
	echo 1 >/sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true

	# Set conservative power limits
	if [ -d /sys/class/powercap/intel-rapl:0 ]; then
		if [ "$CPU_TYPE" = "meteolake" ]; then
			echo 20000000 >/sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || true
			echo 30000000 >/sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || true
			echo "Power limits set: 20W/30W (Meteor Lake)"
		else
			echo 10000000 >/sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || true
			echo 20000000 >/sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || true
			echo "Power limits set: 10W/20W (Kaby Lake R)"
		fi
	fi

	# Set frequency limits
	cpupower frequency-set -u 2.0GHz 2>/dev/null || true
	cpupower frequency-set -d 400MHz 2>/dev/null || true

	# Ensure auto-cpufreq is stopped
	systemctl stop auto-cpufreq 2>/dev/null || true

	echo -e "${BLUE}Powersave mode activated!${NC}"
}

# Set balanced mode (let auto-cpufreq handle it)
set_balanced() {
	echo -e "${YELLOW}Setting BALANCED mode...${NC}"

	CPU_TYPE=$(detect_cpu)

	# Restart auto-cpufreq for automatic management
	systemctl restart auto-cpufreq 2>/dev/null || true

	# Enable turbo for balanced performance
	echo 0 >/sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true

	# Set moderate power limits that auto-cpufreq can work with
	if [ -d /sys/class/powercap/intel-rapl:0 ]; then
		if [ "$CPU_TYPE" = "meteolake" ]; then
			echo 35000000 >/sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || true
			echo 45000000 >/sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || true
			echo "Power limits set: 35W/45W (Meteor Lake)"
		else
			echo 20000000 >/sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || true
			echo 30000000 >/sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || true
			echo "Power limits set: 20W/30W (Kaby Lake R)"
		fi
	fi

	echo -e "${YELLOW}Balanced mode activated (auto-cpufreq managing)!${NC}"
}

# Set custom mode
set_custom() {
	echo -e "${YELLOW}Custom Settings${NC}"

	CPU_TYPE=$(detect_cpu)
	echo -e "Detected CPU: ${BLUE}$CPU_TYPE${NC}"

	# Governor selection
	echo "Select governor:"
	echo "1) performance"
	echo "2) powersave"
	echo "3) schedutil"
	read -p "Choice [1-3]: " gov_choice

	case $gov_choice in
	1)
		cpupower frequency-set -g performance 2>/dev/null || true
		echo "Governor set to: performance"
		;;
	2)
		cpupower frequency-set -g powersave 2>/dev/null || true
		echo "Governor set to: powersave"
		;;
	3)
		cpupower frequency-set -g schedutil 2>/dev/null || true
		echo "Governor set to: schedutil"
		;;
	*)
		echo "Invalid choice, keeping current governor"
		;;
	esac

	# Turbo boost
	read -p "Enable turbo boost? (y/n): " turbo_choice
	if [[ $turbo_choice == "y" || $turbo_choice == "Y" ]]; then
		echo 0 >/sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
		echo "Turbo boost: Enabled"
	else
		echo 1 >/sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
		echo "Turbo boost: Disabled"
	fi

	# Power limits
	if [ -d /sys/class/powercap/intel-rapl:0 ]; then
		read -p "Set PL1 (watts, recommended $([ "$CPU_TYPE" = "meteolake" ] && echo "20-45" || echo "10-30")): " pl1
		read -p "Set PL2 (watts, recommended $([ "$CPU_TYPE" = "meteolake" ] && echo "30-55" || echo "20-40")): " pl2

		if [[ $pl1 =~ ^[0-9]+$ ]] && [[ $pl2 =~ ^[0-9]+$ ]]; then
			echo $((pl1 * 1000000)) >/sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || true
			echo $((pl2 * 1000000)) >/sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || true
			echo "Power limits set: ${pl1}W/${pl2}W"
		else
			echo "Invalid power values, keeping current limits"
		fi
	else
		echo "RAPL power limits not available"
	fi

	# Frequency limits
	read -p "Set maximum frequency (e.g., 4.8GHz, 2.5GHz) [leave empty for no limit]: " max_freq
	read -p "Set minimum frequency (e.g., 800MHz, 400MHz) [leave empty for no limit]: " min_freq

	if [ -n "$max_freq" ]; then
		cpupower frequency-set -u "$max_freq" 2>/dev/null || true
		echo "Max frequency set to: $max_freq"
	fi

	if [ -n "$min_freq" ]; then
		cpupower frequency-set -d "$min_freq" 2>/dev/null || true
		echo "Min frequency set to: $min_freq"
	fi

	# auto-cpufreq management
	read -p "Enable auto-cpufreq? (y/n): " auto_choice
	if [[ $auto_choice == "y" || $auto_choice == "Y" ]]; then
		systemctl restart auto-cpufreq 2>/dev/null || true
		echo "auto-cpufreq: Enabled"
	else
		systemctl stop auto-cpufreq 2>/dev/null || true
		echo "auto-cpufreq: Disabled"
	fi

	echo -e "${GREEN}Custom settings applied!${NC}"
}

# Reset to hardware config defaults
reset_to_default() {
	echo -e "${YELLOW}Resetting to hardware config defaults...${NC}"

	# Restart auto-cpufreq to let it manage everything
	systemctl restart auto-cpufreq 2>/dev/null || true

	# Restart the cpu-power-limit service to apply hardware config defaults
	systemctl restart cpu-power-limit 2>/dev/null || true

	echo -e "${GREEN}Reset to hardware configuration defaults!${NC}"
	echo -e "${YELLOW}Waiting for services to apply changes...${NC}"
	sleep 3
}

# Main menu
show_menu() {
	echo -e "\n${BLUE}=== ThinkPad Performance Control ===${NC}"
	echo "1) Show current status"
	echo "2) PERFORMANCE mode (Maximum power)"
	echo "3) BALANCED mode (Auto-managed)"
	echo "4) POWERSAVE mode (Battery saver)"
	echo "5) CUSTOM settings"
	echo "6) RESET to hardware config defaults"
	echo "7) Exit"
	echo -n "Select option: "
}

# Main logic
main() {
	# Clear screen
	clear

	if [[ $# -eq 0 ]]; then
		# Interactive mode
		while true; do
			show_menu
			read -r choice

			case $choice in
			1)
				get_status
				;;
			2)
				check_root
				set_performance
				get_status
				;;
			3)
				check_root
				set_balanced
				get_status
				;;
			4)
				check_root
				set_powersave
				get_status
				;;
			5)
				check_root
				set_custom
				get_status
				;;
			6)
				check_root
				reset_to_default
				get_status
				;;
			7)
				echo "Exiting..."
				exit 0
				;;
			*)
				echo -e "${RED}Invalid option${NC}"
				;;
			esac

			echo -e "\nPress Enter to continue..."
			read -r
			clear
		done
	else
		# Command line mode
		case $1 in
		status)
			get_status
			;;
		performance)
			check_root
			set_performance
			get_status
			;;
		balanced)
			check_root
			set_balanced
			get_status
			;;
		powersave)
			check_root
			set_powersave
			get_status
			;;
		custom)
			check_root
			set_custom
			get_status
			;;
		reset)
			check_root
			reset_to_default
			get_status
			;;
		--help | -h)
			echo "Usage: $0 [command]"
			echo "Commands:"
			echo "  status      - Show current system status"
			echo "  performance - Set maximum performance mode"
			echo "  balanced    - Set balanced mode (auto-cpufreq)"
			echo "  powersave   - Set power saving mode"
			echo "  custom      - Interactive custom settings"
			echo "  reset       - Reset to hardware config defaults"
			echo ""
			echo "Run without arguments for interactive menu"
			;;
		*)
			echo "Invalid command. Use --help for usage."
			exit 1
			;;
		esac
	fi
}

# Handle script interrupts
trap 'echo -e "\n${RED}Script interrupted.${NC}"; exit 1' INT TERM

main "$@"
