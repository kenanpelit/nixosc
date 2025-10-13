#!/usr/bin/env bash
# ==============================================================================
# System Status Monitor - NixOS Power Management Suite
# ==============================================================================
#
# AÇIKLAMA:
# ---------
# Bu script NixOS sisteminin güç yönetimi ve performans durumunu gösterir.
# Özellikle Intel CPU'lar için optimize edilmiştir ve gerçek zamanlı sistem
# metriklerini hem insan-okunabilir hem de JSON formatında sunar.
#
# KULLANIM:
# ---------
#   ./osc-status.sh           # Normal çıktı (renkli, detaylı)
#   ./osc-status.sh --json    # JSON çıktı (monitoring için)
#
# GÖSTERİLEN BİLGİLER:
# --------------------
# ✅ CPU Tipi (Intel/AMD detection)
# ✅ Güç Kaynağı (AC/Pil)
# ✅ P-State Modu (active/passive)
# ✅ EPP (Energy Performance Preference) - YENİ v12!
# ✅ HWP Dynamic Boost Durumu - YENİ v12!
# ✅ Min/Max Performans Yüzdeleri
# ✅ Turbo Boost Durumu
# ✅ Platform Profili (performance/balanced/low-power)
# ✅ Tüm CPU Core'larının Frekansları
# ✅ Sıcaklık Bilgisi (sensors)
# ✅ RAPL Güç Limitleri (PL1/PL2) - AC/Pil adaptif
# ✅ Pil Durumu ve Şarj Eşikleri
# ✅ Systemd Servis Durumları (cpu-epp dahil)
#
# JSON ÇIKTISI:
# -------------
# Monitoring araçları için makine-okunabilir JSON formatı:
#   {
#     "cpu_type": "intel",
#     "power_source": "AC",
#     "pstate_mode": "active",
#     "epp": "performance",
#     "hwp_dynamic_boost": true,
#     "turbo_enabled": true,
#     "freq_avg_mhz": 2500,
#     "temp_celsius": 65.0,
#     "power_limits": {
#       "pl1_watts": 45,
#       "pl2_watts": 90
#     },
#     "timestamp": "2025-10-13T23:15:00+0300"
#   }
#
# ÖRNEKLER:
# ---------
#   # Anlık durum kontrolü
#   ./osc-status.sh
#
#   # JSON çıktısını jq ile işle
#   ./osc-status.sh --json | jq '.epp'
#
#   # EPP değişimini izle (AC/Pil)
#   watch -n 2 ./osc-status.sh
#
#   # Log'a kaydet
#   ./osc-status.sh >> /var/log/system-status.log
#
# BAĞIMLILIKLAR:
# --------------
# - lm_sensors (sensors komutu)
# - jq (JSON çıktısı için)
# - systemctl (servis durumu için)
#
# NOTLAR:
# -------
# - Script root yetkisi gerektirmez (read-only sysfs kullanır)
# - Intel CPU'lar için optimize edilmiştir
# - AMD sistemlerde bazı metrikler mevcut olmayabilir
# - v12'de EPP ve AC/Pil adaptif limitler eklendi
#
# YAZARLAR:
# ---------
# Versiyon: 12.0 - EPP + AC/Battery Adaptive Edition
# Tarih: 2025-10-13
#
# LİSANS:
# -------
# MIT License - Özgürce kullanabilir, değiştirebilir ve dağıtabilirsiniz
#
# ==============================================================================

if [[ "${1:-}" == "--json" ]]; then
	# CPU tipi algıla
	CPU_TYPE="unknown"
	if grep -q "Intel" /proc/cpuinfo 2>/dev/null; then
		CPU_TYPE="intel"
	elif grep -q "AMD" /proc/cpuinfo 2>/dev/null; then
		CPU_TYPE="amd"
	fi

	# Güç kaynağı
	ON_AC=0
	for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
		[[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
	done

	# Governor ve pstate
	GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
	PSTATE=$(cat /sys/devices/system/cpu/intel_pstate/status 2>/dev/null || echo "unknown")

	# EPP (Energy Performance Preference)
	EPP=$(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null || echo "unknown")

	# HWP Dynamic Boost
	HWP_BOOST=$(cat /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost 2>/dev/null || echo "0")

	# Turbo durumu
	NO_TURBO=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || echo "1")
	TURBO_ENABLED=$([[ "$NO_TURBO" == "0" ]] && echo "true" || echo "false")

	# Min/Max performans
	MIN_PERF=$(cat /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || echo "0")
	MAX_PERF=$(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null || echo "0")

	# Ortalama frekans
	FREQ_SUM=0
	FREQ_COUNT=0
	for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq; do
		[[ -f "$f" ]] || continue
		FREQ_SUM=$((FREQ_SUM + $(cat "$f")))
		FREQ_COUNT=$((FREQ_COUNT + 1))
	done
	FREQ_AVG=0
	[[ $FREQ_COUNT -gt 0 ]] && FREQ_AVG=$((FREQ_SUM / FREQ_COUNT / 1000))

	# Sıcaklık
	TEMP=$(sensors 2>/dev/null |
		grep -E 'Package id 0|Tctl' |
		awk '{match($0, /[+]?([0-9]+\.[0-9]+)/, arr); if(arr[1]!="") print arr[1]; exit}')
	[[ -z "$TEMP" ]] && TEMP="0"

	# Güç limitleri
	PL1=0
	PL2=0
	if [[ -d /sys/class/powercap/intel-rapl:0 ]]; then
		PL1=$(($(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0) / 1000000))
		PL2=$(($(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0) / 1000000))
	fi

	# Platform profili
	PLATFORM_PROFILE=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null || echo "unknown")

	# JSON çıktısı
	jq -n \
		--arg cpu_type "$CPU_TYPE" \
		--argjson on_ac "$ON_AC" \
		--arg governor "$GOVERNOR" \
		--arg pstate "$PSTATE" \
		--arg epp "$EPP" \
		--argjson hwp_boost "$HWP_BOOST" \
		--argjson turbo_enabled "$TURBO_ENABLED" \
		--argjson min_perf "$MIN_PERF" \
		--argjson max_perf "$MAX_PERF" \
		--argjson freq_avg "$FREQ_AVG" \
		--argjson temp "$TEMP" \
		--argjson pl1 "$PL1" \
		--argjson pl2 "$PL2" \
		--arg platform_profile "$PLATFORM_PROFILE" \
		'{
      cpu_type: $cpu_type,
      power_source: (if $on_ac == 1 then "AC" else "Battery" end),
      governor: $governor,
      pstate_mode: $pstate,
      epp: $epp,
      hwp_dynamic_boost: ($hwp_boost == 1),
      turbo_enabled: $turbo_enabled,
      performance: {
        min_pct: $min_perf,
        max_pct: $max_perf
      },
      platform_profile: $platform_profile,
      freq_avg_mhz: $freq_avg,
      temp_celsius: $temp,
      power_limits: {
        pl1_watts: $pl1,
        pl2_watts: $pl2
      },
      timestamp: now | strftime("%Y-%m-%dT%H:%M:%S%z")
    }'
	exit 0
fi

# Human-readable output
echo "=== SİSTEM DURUMU (v12) ==="
echo ""

# CPU tipi algıla
CPU_TYPE="unknown"
if grep -q "Intel" /proc/cpuinfo 2>/dev/null; then
	CPU_TYPE="intel"
elif grep -q "AMD" /proc/cpuinfo 2>/dev/null; then
	CPU_TYPE="amd"
fi
echo "CPU Type: $CPU_TYPE"

# Güç kaynağı
ON_AC=0
for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
	[[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
done
if [[ "$ON_AC" = "1" ]]; then
	echo "Güç Kaynağı: ⚡ AC"
else
	echo "Güç Kaynağı: 🔋 Pil"
fi

# P-State modu
echo ""
if [[ -f "/sys/devices/system/cpu/intel_pstate/status" ]]; then
	PSTATE=$(cat /sys/devices/system/cpu/intel_pstate/status)
	echo "P-State Modu: $PSTATE"

	if [[ -r "/sys/devices/system/cpu/intel_pstate/min_perf_pct" ]]; then
		MIN_PERF=$(cat /sys/devices/system/cpu/intel_pstate/min_perf_pct)
		MAX_PERF=$(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null || echo "?")
		echo "  Min/Max Performans: $MIN_PERF% / $MAX_PERF%"
	fi

	# Turbo durumu
	if [[ -r "/sys/devices/system/cpu/intel_pstate/no_turbo" ]]; then
		NO_TURBO=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
		if [[ "$NO_TURBO" = "0" ]]; then
			echo "  Turbo Boost: ✓ Aktif"
		else
			echo "  Turbo Boost: ✗ Kapalı"
		fi
	fi

	# HWP Dynamic Boost
	if [[ -r "/sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost" ]]; then
		BOOST=$(cat /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost)
		if [[ "$BOOST" = "1" ]]; then
			echo "  HWP Dynamic Boost: ✓ Aktif"
		else
			echo "  HWP Dynamic Boost: ✗ Kapalı"
		fi
	fi
fi

# Platform profili
if [[ -r "/sys/firmware/acpi/platform_profile" ]]; then
	PROFILE=$(cat /sys/firmware/acpi/platform_profile)
	echo "Platform Profili: $PROFILE"
fi

# EPP (Energy Performance Preference)
echo ""
echo "EPP (Energy Performance Preference):"
for pol in /sys/devices/system/cpu/cpufreq/policy*; do
	if [[ -r "$pol/energy_performance_preference" ]]; then
		EPP=$(cat "$pol/energy_performance_preference")
		POL_NUM=$(basename "$pol" | sed 's/policy//')
		echo "  Policy $POL_NUM: $EPP"
		break
	fi
done

# CPU Frekansları
echo ""
echo "CPU FREKANSLARI (örnek çekirdekler):"
for i in 0 4 8 12 16 20; do
	if [[ -r "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq" ]]; then
		FREQ=$(cat "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq" 2>/dev/null || echo 0)
		printf "  CPU %2d: %4d MHz\n" "$i" "$((FREQ / 1000))"
	fi
done

# Sıcaklık
echo ""
echo "SICAKLIK:"
sensors 2>/dev/null | grep -E 'Package|Core|Tctl' | head -3 ||
	echo "  Sıcaklık bilgisi mevcut değil"

# RAPL Güç Limitleri
echo ""
echo "RAPL GÜÇ LİMİTLERİ:"
if [[ -d /sys/class/powercap/intel-rapl:0 ]]; then
	PL1=$(($(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0) / 1000000))
	PL2=$(($(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0) / 1000000))
	echo "  PL1 (sürekli): ${PL1}W"
	echo "  PL2 (burst):   ${PL2}W"

	# AC/Pil durumuna göre beklenen değerler
	if [[ "$ON_AC" = "1" ]]; then
		echo "  💡 AC modunda - Performans limitleri aktif"
	else
		echo "  💡 Pil modunda - Verimlilik limitleri aktif"
	fi
else
	echo "  RAPL interface bulunamadı"
fi

# Pil Durumu
echo ""
echo "PİL DURUMU:"
FOUND_BAT=0
for bat in /sys/class/power_supply/BAT*; do
	[[ -d "$bat" ]] || continue
	FOUND_BAT=1
	NAME=$(basename "$bat")
	CAPACITY=$(cat "$bat/capacity" 2>/dev/null || echo "N/A")
	STATUS=$(cat "$bat/status" 2>/dev/null || echo "N/A")
	START=$(cat "$bat/charge_control_start_threshold" 2>/dev/null || echo "N/A")
	STOP=$(cat "$bat/charge_control_end_threshold" 2>/dev/null || echo "N/A")
	echo "  $NAME: $CAPACITY% ($STATUS) [Eşikler: $START-$STOP%]"
done
[[ $FOUND_BAT -eq 0 ]] && echo "  Pil bulunamadı"

# Servis Durumu
echo ""
echo "SERVİS DURUMU:"
SERVICES="battery-thresholds platform-profile cpu-epp cpu-min-freq-guard rapl-power-limits"
for service in $SERVICES; do
	STATE=$(systemctl show -p ActiveState --value "$service.service" 2>/dev/null)
	RESULT=$(systemctl show -p Result --value "$service.service" 2>/dev/null)

	if [[ "$STATE" == "inactive" ]] && [[ "$RESULT" == "success" ]]; then
		echo "  ✅ $service"
	elif [[ "$STATE" == "active" ]]; then
		echo "  ✅ $service"
	else
		echo "  ⚠️  $service ($STATE)"
	fi
done

echo ""
echo "💡 İpucu: Gerçek frekanslar için 'turbostat-quick' kullanın"
echo "💡 Güç tüketimi için 'power-check' veya 'power-monitor' kullanın"
echo "💡 JSON çıktı için: ./osc-status.sh --json"
