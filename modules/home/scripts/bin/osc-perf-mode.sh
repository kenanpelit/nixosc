#!/usr/bin/env bash
# Performance Control Script for ThinkPad

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

	# Governor
	GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
	echo -e "Governor: ${YELLOW}$GOVERNOR${NC}"

	# Turbo Boost
	TURBO=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
	if [ "$TURBO" = "0" ]; then
		echo -e "Turbo: ${GREEN}Enabled${NC}"
	else
		echo -e "Turbo: ${RED}Disabled${NC}"
	fi

	# Current frequencies
	echo -e "\nCPU Frequencies:"
	grep "cpu MHz" /proc/cpuinfo | head -4 | awk '{print "  Core " NR-1 ": " $4 " MHz"}'

	# Power limits
	PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw)
	PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw)
	echo -e "\nPower Limits:"
	echo -e "  PL1: $((PL1 / 1000000))W"
	echo -e "  PL2: $((PL2 / 1000000))W"

	# Temperature
	TEMP=$(cat /sys/class/thermal/thermal_zone*/temp | sort -rn | head -1)
	echo -e "\nCPU Temp: ${YELLOW}$((TEMP / 1000))°C${NC}"
}

# Set performance mode
set_performance() {
	echo -e "${GREEN}Setting PERFORMANCE mode...${NC}"

	# Stop auto-cpufreq temporarily
	systemctl stop auto-cpufreq 2>/dev/null || true

	# Set governor
	cpupower frequency-set -g performance

	# Enable turbo
	echo 0 >/sys/devices/system/cpu/intel_pstate/no_turbo

	# Set higher power limits (E14 Gen 6)
	echo 45000000 >/sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
	echo 55000000 >/sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw

	# Remove frequency limits
	cpupower frequency-set -u 4.8GHz
	cpupower frequency-set -d 800MHz

	echo -e "${GREEN}Performance mode activated!${NC}"
}

# Set powersave mode
set_powersave() {
	echo -e "${BLUE}Setting POWERSAVE mode...${NC}"

	# Stop auto-cpufreq temporarily
	systemctl stop auto-cpufreq 2>/dev/null || true

	# Set governor
	cpupower frequency-set -g powersave

	# Disable turbo
	echo 1 >/sys/devices/system/cpu/intel_pstate/no_turbo

	# Set lower power limits
	echo 25000000 >/sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
	echo 35000000 >/sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw

	# Set frequency limits
	cpupower frequency-set -u 2.5GHz
	cpupower frequency-set -d 400MHz

	echo -e "${BLUE}Powersave mode activated!${NC}"
}

# Set balanced mode
set_balanced() {
	echo -e "${YELLOW}Setting BALANCED mode...${NC}"

	# Restart auto-cpufreq for automatic management
	systemctl restart auto-cpufreq

	# Wait for service to start
	sleep 2

	# Enable turbo for balanced performance
	echo 0 >/sys/devices/system/cpu/intel_pstate/no_turbo

	# Set moderate power limits
	echo 35000000 >/sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
	echo 45000000 >/sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw

	# Let auto-cpufreq manage governor and frequencies
	# It will switch between powersave/performance based on load

	echo -e "${YELLOW}Balanced mode activated (auto-cpufreq managing)!${NC}"
}

# Set custom mode
set_custom() {
	echo -e "${YELLOW}Custom Settings${NC}"

	# Governor selection
	echo "Select governor:"
	echo "1) performance"
	echo "2) powersave"
	echo "3) schedutil"
	read -p "Choice: " gov_choice

	case $gov_choice in
	1) cpupower frequency-set -g performance ;;
	2) cpupower frequency-set -g powersave ;;
	3) cpupower frequency-set -g schedutil ;;
	*) echo "Invalid choice" ;;
	esac

	# Turbo boost
	read -p "Enable turbo boost? (y/n): " turbo_choice
	if [[ $turbo_choice == "y" ]]; then
		echo 0 >/sys/devices/system/cpu/intel_pstate/no_turbo
	else
		echo 1 >/sys/devices/system/cpu/intel_pstate/no_turbo
	fi

	# Power limits
	read -p "Set PL1 (watts, e.g., 35): " pl1
	read -p "Set PL2 (watts, e.g., 45): " pl2

	echo $((pl1 * 1000000)) >/sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
	echo $((pl2 * 1000000)) >/sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw

	echo -e "${GREEN}Custom settings applied!${NC}"
}

# Main menu
show_menu() {
	echo -e "\n${BLUE}=== ThinkPad Performance Control ===${NC}"
	echo "1) Show current status"
	echo "2) PERFORMANCE mode (Maximum power)"
	echo "3) BALANCED mode (Auto-managed)"
	echo "4) POWERSAVE mode (Battery saver)"
	echo "5) CUSTOM settings"
	echo "6) Exit"
	echo -n "Select option: "
}

# Main logic
main() {
	if [[ $# -eq 0 ]]; then
		# Interactive mode
		while true; do
			show_menu
			read -r choice

			case $choice in
			1) get_status ;;
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
				echo "Exiting..."
				exit 0
				;;
			*) echo -e "${RED}Invalid option${NC}" ;;
			esac

			echo -e "\nPress Enter to continue..."
			read -r
			clear
		done
	else
		# Command line mode
		case $1 in
		status) get_status ;;
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
		--help | -h)
			echo "Usage: $0 [command]"
			echo "Commands:"
			echo "  status      - Show current system status"
			echo "  performance - Set maximum performance mode"
			echo "  balanced    - Set balanced mode (auto-cpufreq)"
			echo "  powersave   - Set power saving mode"
			echo "  custom      - Interactive custom settings"
			echo ""
			echo "Run without arguments for interactive menu"
			;;
		*) echo "Invalid command. Use --help for usage." ;;
		esac
	fi
}

main "$@"
