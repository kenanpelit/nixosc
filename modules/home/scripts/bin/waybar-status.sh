#!/usr/bin/env bash
# ==============================================================================
# Waybar System Status Module - CPU Usage, Temperature & Power
# ==============================================================================
#
# Bu script Waybar için CPU kullanımı, sıcaklık ve sistem durumu bilgilerini
# JSON formatında döndürür. Hem cpu hem de temperature modüllerinin işlevini
# tek bir modülde birleştirir.
#
# KULLANIM:
# ---------
#   ./waybar-status.sh
#
# Waybar config.nix'e eklenecek modül:
# "custom/system-status": {
#   "exec": "~/.config/waybar/scripts/waybar-status.sh",
#   "return-type": "json",
#   "interval": 5,
#   "format": "{icon} {}"
# }
#
# ==============================================================================

set -euo pipefail

# ----------------------------- yardımcılar ------------------------------------
have() { command -v "$1" >/dev/null 2>&1; }
read_file() { [[ -r "$1" ]] && cat "$1" || return 1; }

# ----------------------------- CPU kullanımını hesapla ------------------------
get_cpu_usage() {
	# /proc/stat'tan CPU kullanımını hesapla (tüm çekirdekler ortalaması)
	if [[ -r /proc/stat ]]; then
		# İki okuma arası veriler
		read cpu user1 nice1 system1 idle1 iowait1 irq1 softirq1 steal1 _ < <(grep '^cpu ' /proc/stat)
		sleep 1
		read cpu user2 nice2 system2 idle2 iowait2 irq2 softirq2 steal2 _ < <(grep '^cpu ' /proc/stat)

		# Farkları hesapla
		idle=$((idle2 - idle1 + iowait2 - iowait1))
		total=$((user2 - user1 + nice2 - nice1 + system2 - system1 + idle2 - idle1 + iowait2 - iowait1 + irq2 - irq1 + softirq2 - softirq1 + steal2 - steal1))

		# CPU kullanımı yüzdesi
		if [[ $total -gt 0 ]]; then
			awk -v idle="$idle" -v total="$total" 'BEGIN {printf "%.0f", (1 - idle/total) * 100}'
		else
			echo "0"
		fi
	else
		echo "0"
	fi
}

# ----------------------------- sıcaklık --------------------------------------
get_temp() {
	if have sensors; then
		local t
		# Önce Package id dene, yoksa coretemp'ten en yüksek sıcaklığı al
		t="$(sensors 2>/dev/null | grep -E 'Package id 0' | head -1 | awk '{match($0, /[+]?([0-9]+)/, a); if(a[1]!=""){print a[1]; exit}}')"
		[[ -z "$t" ]] && t="$(sensors 2>/dev/null | awk '/^temp[0-9]+:/ && /°C/ {match($0, /[+]([0-9]+)/, a); if(a[1]!="" && a[1]>max){max=a[1]}} END{if(max>0) print max; else print 0}')"
		[[ -n "$t" && "$t" != "0" ]] && {
			echo "$t"
			return
		}
	fi

	# sensors yoksa thermal_zone'dan oku
	for p in /sys/class/thermal/thermal_zone*/temp; do
		[[ -r "$p" ]] || continue
		tmc="$(cat "$p")"
		[[ "$tmc" =~ ^[0-9]+$ ]] && {
			awk -v v="$tmc" 'BEGIN{printf "%.0f", v/1000}'
			return
		}
	done
	echo "0"
}

# ----------------------------- CPU frekansı ortalama -------------------------
get_avg_freq() {
	local freq_sum=0
	local freq_cnt=0

	for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq; do
		[[ -f "$f" ]] || continue
		val="$(cat "$f" 2>/dev/null || echo 0)"
		freq_sum=$((freq_sum + val))
		freq_cnt=$((freq_cnt + 1))
	done

	if [[ $freq_cnt -gt 0 ]]; then
		echo $((freq_sum / freq_cnt / 1000))
	else
		echo "0"
	fi
}

# ----------------------------- güç kaynağı ------------------------------------
get_power_source() {
	local on_ac=0
	for ps in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
		[[ -f "$ps" ]] && {
			on_ac="$(cat "$ps")"
			break
		}
	done
	[[ "${on_ac}" = "1" ]] && echo "AC" || echo "Battery"
}

# ----------------------------- durum sınıfı belirle --------------------------
get_status_class() {
	local cpu_usage=$1
	local temp=$2

	# Sıcaklık kontrolü öncelikli
	if [[ $(awk -v t="$temp" 'BEGIN{print (t>=80)?1:0}') -eq 1 ]]; then
		echo "critical"
		return
	elif [[ $(awk -v t="$temp" 'BEGIN{print (t>=70)?1:0}') -eq 1 ]]; then
		echo "high"
		return
	fi

	# CPU kullanımına göre
	if [[ $cpu_usage -ge 80 ]]; then
		echo "high"
	elif [[ $cpu_usage -ge 50 ]]; then
		echo "normal"
	else
		echo "low"
	fi
}

# ----------------------------- icon belirle ----------------------------------
get_icon() {
	local status_class=$1
	local power_source=$2

	case "$status_class" in
	critical)
		echo "󰈸" # fire
		;;
	high)
		if [[ "$power_source" = "AC" ]]; then
			echo "󱐋" # chip-lightning
		else
			echo "󰻠" # chip
		fi
		;;
	normal)
		echo "󰾆" # cpu
		;;
	low)
		echo "󰾆" # cpu-low
		;;
	*)
		echo "󰾆"
		;;
	esac
}

# ----------------------------- ana işlem --------------------------------------
main() {
	# Verileri topla
	cpu_usage=$(get_cpu_usage)
	temp=$(get_temp)
	freq=$(get_avg_freq)
	power_source=$(get_power_source)
	status_class=$(get_status_class "$cpu_usage" "$temp")
	icon=$(get_icon "$status_class" "$power_source")

	# Formatlanmış çıktı - Frekansı GHz'e çevir
	if [[ $freq -ge 1000 ]]; then
		freq_display=$(awk -v f="$freq" 'BEGIN{printf "%.1fG", f/1000}')
	else
		freq_display="${freq}M"
	fi
	text="${cpu_usage}% ${temp}°C ${freq_display}"

	# Tooltip için detaylı bilgi (JSON-safe)
	tooltip="CPU: ${cpu_usage}% | Temp: ${temp}°C | Freq: ${freq} MHz | Power: ${power_source}"

	# JSON çıktı (Waybar için)
	printf '{"text":"%s","icon":"%s","tooltip":"%s","class":"%s","percentage":%d}\n' \
		"${text}" "${icon}" "${tooltip}" "${status_class}" "${cpu_usage}"
}

main
