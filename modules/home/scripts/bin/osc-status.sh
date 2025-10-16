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

set -euo pipefail

VERSION="12.4"

# ----------------------------- renkler (isteğe bağlı) -------------------------
if [[ -t 1 ]]; then
	BOLD=$'\e[1m'
	DIM=$'\e[2m'
	RED=$'\e[31m'
	GRN=$'\e[32m'
	YLW=$'\e[33m'
	BLU=$'\e[34m'
	MAG=$'\e[35m'
	CYN=$'\e[36m'
	RST=$'\e[0m'
else
	BOLD=""
	DIM=""
	RED=""
	GRN=""
	YLW=""
	BLU=""
	MAG=""
	CYN=""
	RST=""
fi

# ----------------------------- yardımcılar ------------------------------------
have() { command -v "$1" >/dev/null 2>&1; }
read_file() { [[ -r "$1" ]] && cat "$1" || return 1; }

json_out=false
brief_out=false
sample_power=false

while [[ $# -gt 0 ]]; do
	case "$1" in
	--json) json_out=true ;;
	--brief) brief_out=true ;;
	--sample-power) sample_power=true ;;
	-h | --help)
		cat <<EOF
Usage: ${0##*/} [--json] [--brief] [--sample-power]

  --json           Makine-okunabilir JSON çıktı (jq önerilir)
  --brief          İnsan-çıktısında kısa mod
  --sample-power   RAPL enerji sayacıyla ~2 sn örnek al, Watt hesapla
EOF
		exit 0
		;;
	*)
		echo "Unknown option: $1" >&2
		exit 2
		;;
	esac
	shift
done

# ----------------------------- CPU tipi ---------------------------------------
CPU_TYPE="unknown"
if grep -q "Intel" /proc/cpuinfo 2>/dev/null; then
	CPU_TYPE="intel"
elif grep -q "AMD" /proc/cpuinfo 2>/dev/null; then
	CPU_TYPE="amd"
fi

# ----------------------------- güç kaynağı ------------------------------------
ON_AC=0
for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
	[[ -f "$PS" ]] && {
		ON_AC="$(cat "$PS")"
		break
	}
done
POWER_SRC=$([[ "${ON_AC}" = "1" ]] && echo "AC" || echo "Battery")

# ----------------------------- pstate / governor ------------------------------
GOVERNOR="$(read_file /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")"
PSTATE="$(read_file /sys/devices/system/cpu/intel_pstate/status 2>/dev/null || echo "unknown")"

NO_TURBO="$(read_file /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || echo "1")"
TURBO_ENABLED=$([[ "${NO_TURBO}" = "0" ]] && echo true || echo false)

HWP_BOOST="$(read_file /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost 2>/dev/null || echo "0")"
HWP_BOOST_BOOL=$([[ "${HWP_BOOST}" = "1" ]] && echo true || echo false)

MIN_PERF="$(read_file /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || echo "0")"
MAX_PERF="$(read_file /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null || echo "0")"

# ----------------------------- EPP --------------------------------------------
EPP_ANY="unknown"
declare -A EPP_MAP || true
EPP_COUNT=0
for pol in /sys/devices/system/cpu/cpufreq/policy*; do
	[[ -r "$pol/energy_performance_preference" ]] || continue
	epp="$(cat "$pol/energy_performance_preference")"
	EPP_ANY="$epp"
	EPP_MAP["$epp"]=$((${EPP_MAP["$epp"]:-0} + 1))
	EPP_COUNT=$((EPP_COUNT + 1))
done

# ----------------------------- freq (ort + örnek çekirdekler) ----------------
FREQ_SUM=0
FREQ_CNT=0
for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq; do
	[[ -f "$f" ]] || continue
	val="$(cat "$f")"
	FREQ_SUM=$((FREQ_SUM + val))
	FREQ_CNT=$((FREQ_CNT + 1))
done
FREQ_AVG_MHZ=0
[[ $FREQ_CNT -gt 0 ]] && FREQ_AVG_MHZ=$((FREQ_SUM / FREQ_CNT / 1000))

# ----------------------------- sıcaklık --------------------------------------
get_temp() {
	if have sensors; then
		local t
		t="$(sensors 2>/dev/null | grep -E 'Package id 0|Tctl' | awk '{match($0, /[+]?([0-9]+\.[0-9]+)/, a); if(a[1]!=""){print a[1]; exit}}')"
		[[ -n "$t" ]] && {
			echo "$t"
			return
		}
	fi
	for p in /sys/class/thermal/thermal_zone*/temp; do
		[[ -r "$p" ]] || continue
		tmc="$(cat "$p")"
		[[ "$tmc" =~ ^[0-9]+$ ]] && { awk -v v="$tmc" 'BEGIN{printf "%.1f", v/1000}' && return; }
	done
	echo "0"
}
TEMP_C="$(get_temp)"

# ----------------------------- RAPL limitleri ---------------------------------
PL1_W=0
PL2_W=0
PL4_W=0
if [[ -d /sys/class/powercap/intel-rapl:0 ]]; then
	PL1_W=$(($(read_file /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0) / 1000000))
	PL2_W=$(($(read_file /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0) / 1000000))
	PL4_W=$(($(read_file /sys/class/powercap/intel-rapl:0/constraint_2_power_limit_uw 2>/dev/null || echo 0) / 1000000))
fi

# MSR vs MMIO tutarlılık (sadece package-0 için)
MSR_PL1_W=0
MSR_PL2_W=0
MMIO_PL1_W=0
MMIO_PL2_W=0
if [[ -d /sys/class/powercap/intel-rapl:0 && -d /sys/class/powercap/intel-rapl-mmio:0 ]]; then
	MSR_PL1_W=$(($(read_file /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0) / 1000000))
	MSR_PL2_W=$(($(read_file /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0) / 1000000))
	MMIO_PL1_W=$(($(read_file /sys/class/powercap/intel-rapl-mmio:0/constraint_0_power_limit_uw 2>/dev/null || echo 0) / 1000000))
	MMIO_PL2_W=$(($(read_file /sys/class/powercap/intel-rapl-mmio:0/constraint_1_power_limit_uw 2>/dev/null || echo 0) / 1000000))
fi

# ----------------------------- platform profile -------------------------------
PLATFORM_PROFILE="$(read_file /sys/firmware/acpi/platform_profile 2>/dev/null || echo "unknown")"

# ----------------------------- pil durumu -------------------------------------
BAT_JSON="[]"
BAT_LINES=()
for bat in /sys/class/power_supply/BAT*; do
	[[ -d "$bat" ]] || continue
	name="${bat##*/}"
	cap="$(read_file "$bat/capacity" 2>/dev/null || echo "N/A")"
	stat="$(read_file "$bat/status" 2>/dev/null || echo "N/A")"
	start="$(read_file "$bat/charge_control_start_threshold" 2>/dev/null || echo "N/A")"
	stop="$(read_file "$bat/charge_control_end_threshold" 2>/dev/null || echo "N/A")"
	BAT_LINES+=("  ${name}: ${cap}% (${stat}) [eşikler: ${start}-${stop}%]")
	if have jq; then
		BAT_JSON="$(jq -cn --arg name "$name" --arg cap "$cap" --arg stat "$stat" --arg start "$start" --arg stop "$stop" \
			--argjson cur "$BAT_JSON" '$cur + [{name:$name, capacity:$cap, status:$stat, start:$start, stop:$stop}]')"
	fi
done

# ----------------------------- anlık paket gücü -------------------------------
PKG_W_NOW=""
if $sample_power && [[ -r /sys/class/powercap/intel-rapl:0/energy_uj ]]; then
	E0="$(cat /sys/class/powercap/intel-rapl:0/energy_uj)"
	sleep 2
	E1="$(cat /sys/class/powercap/intel-rapl:0/energy_uj)"
	diff=$((E1 - E0))
	[[ $diff -lt 0 ]] && diff="$E1" # wraparound koruması
	PKG_W_NOW="$(printf "%.2f" "$(awk -v d="$diff" 'BEGIN{print d/2000000.0}')")"
fi

# ----------------------------- JSON çıktı -------------------------------------
if $json_out; then
	if ! have jq; then
		echo "Error: --json için 'jq' gerekli." >&2
		exit 1
	fi

	# EPP map’i JSON’a çevir
	EPP_JSON="{}"
	if ((EPP_COUNT > 0)); then
		for k in "${!EPP_MAP[@]}"; do
			EPP_JSON="$(jq -cn --argjson cur "$EPP_JSON" --arg k "$k" --argjson v "${EPP_MAP[$k]}" '$cur + {($k):$v}')"
		done
	fi

	TS="$(date +%Y-%m-%dT%H:%M:%S%z)"

	jq -n \
		--arg version "$VERSION" \
		--arg cpu_type "$CPU_TYPE" \
		--arg power_source "$POWER_SRC" \
		--arg governor "$GOVERNOR" \
		--arg pstate "$PSTATE" \
		--arg epp_any "$EPP_ANY" \
		--arg platform_profile "$PLATFORM_PROFILE" \
		--arg ts "$TS" \
		--argjson turbo "$TURBO_ENABLED" \
		--argjson hwp_boost "$HWP_BOOST_BOOL" \
		--argjson min_perf "${MIN_PERF//[^0-9]/}" \
		--argjson max_perf "${MAX_PERF//[^0-9]/}" \
		--argjson freq_avg "$FREQ_AVG_MHZ" \
		--argjson temp "$TEMP_C" \
		--argjson pl1 "$PL1_W" \
		--argjson pl2 "$PL2_W" \
		--argjson pl4 "$PL4_W" \
		--argjson msr_pl1 "$MSR_PL1_W" \
		--argjson msr_pl2 "$MSR_PL2_W" \
		--argjson mmio_pl1 "$MMIO_PL1_W" \
		--argjson mmio_pl2 "$MMIO_PL2_W" \
		--argjson pkg_w_now "${PKG_W_NOW:-0}" \
		--argjson bat "$([[ "${BAT_JSON}" == "[]" ]] && echo "[]" || echo "${BAT_JSON}")" \
		--argjson epp_map "$([[ $EPP_COUNT -gt 0 ]] && echo "${EPP_JSON}" || echo "{}")" \
		'{
      version: $version,
      cpu_type: $cpu_type,
      power_source: $power_source,
      governor: $governor,
      pstate_mode: $pstate,
      epp_any: $epp_any,
      epp_map: $epp_map,
      hwp_dynamic_boost: $hwp_boost,
      turbo_enabled: $turbo,
      performance: { min_pct: $min_perf, max_pct: $max_perf },
      platform_profile: $platform_profile,
      freq_avg_mhz: $freq_avg,
      temp_celsius: $temp,
      power_limits: {
        pl1_watts: $pl1, pl2_watts: $pl2, pl4_watts: $pl4,
        msr_vs_mmio: { msr: {pl1:$msr_pl1, pl2:$msr_pl2}, mmio: {pl1:$mmio_pl1, pl2:$mmio_pl2} }
      },
      pkg_watts_now: $pkg_w_now,
      batteries: $bat,
      timestamp: $ts
    }'
	exit 0
fi

# ----------------------------- İnsan-okunur çıktı -----------------------------
echo "=== SİSTEM DURUMU (v${VERSION}) ==="
echo ""

echo "CPU Type: ${CYN}${CPU_TYPE}${RST}"
echo -n "Güç Kaynağı: "
if [[ "$POWER_SRC" = "AC" ]]; then
	echo "⚡ AC"
else
	echo "🔋 Pil"
fi

echo ""
if [[ "$PSTATE" != "unknown" ]]; then
	echo "P-State Modu: ${BOLD}${PSTATE}${RST}"
	echo "  Min/Max Performans: ${MIN_PERF}% / ${MAX_PERF}%"
	echo "  Turbo Boost: $([[ "$TURBO_ENABLED" = true ]] && echo "✓ Aktif" || echo "✗ Kapalı")"
	echo "  HWP Dynamic Boost: $([[ "$HWP_BOOST_BOOL" = true ]] && echo "✓ Aktif" || echo "✗ Kapalı")"
fi

[[ "$PLATFORM_PROFILE" != "unknown" ]] && echo "Platform Profili: ${PLATFORM_PROFILE}"

echo ""
if ((EPP_COUNT > 0)); then
	echo "EPP (Energy Performance Preference):"
	for k in "${!EPP_MAP[@]}"; do
		echo "  - ${k} (on ${EPP_MAP[$k]} policies)"
	done
else
	echo "EPP: (arayüz bulunamadı veya yetkisiz)"
fi

if ! $brief_out; then
	echo ""
	echo "CPU FREKANSLARI:"
	for i in 0 4 8 12 16 20; do
		p="/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_cur_freq"
		[[ -r "$p" ]] || continue
		f="$(cat "$p" 2>/dev/null || echo 0)"
		printf "  CPU %2d: %4d MHz\n" "$i" "$((f / 1000))"
	done
	echo "  Ortalama: ${BOLD}${FREQ_AVG_MHZ} MHz${RST}"
fi

echo ""
echo "SICAKLIK: ${BOLD}${TEMP_C}°C${RST}"

echo ""
echo "RAPL GÜÇ LİMİTLERİ:"
if [[ -d /sys/class/powercap/intel-rapl:0 ]]; then
	printf "  PL1 (sürekli): %2d W\n" "$PL1_W"
	printf "  PL2 (burst):   %2d W\n" "$PL2_W"
	[[ $PL4_W -gt 0 ]] && printf "  PL4 (peak):    %2d W\n" "$PL4_W"

	if [[ $MSR_PL1_W -gt 0 || $MMIO_PL1_W -gt 0 ]]; then
		match_pl1=$([[ $MSR_PL1_W -eq $MMIO_PL1_W ]] && echo "✓ match" || echo "≠ mismatch")
		match_pl2=$([[ $MSR_PL2_W -eq $MMIO_PL2_W ]] && echo "✓ match" || echo "≠ mismatch")
		echo "  Tutarlılık (MSR vs MMIO):"
		printf "    PL1: MSR=%d W | MMIO=%d W  [%s]\n" "$MSR_PL1_W" "$MMIO_PL1_W" "$match_pl1"
		printf "    PL2: MSR=%d W | MMIO=%d W  [%s]\n" "$MSR_PL2_W" "$MMIO_PL2_W" "$match_pl2"
	fi

	if $sample_power && [[ -n "${PKG_W_NOW}" ]]; then
		echo "  Anlık Paket Gücü (≈2 sn örnek): ${BOLD}${PKG_W_NOW} W${RST}"
	fi

	if [[ "$POWER_SRC" = "AC" ]]; then
		echo "  💡 AC modunda - Performans limitleri"
	else
		echo "  💡 Pil modunda - Verimlilik limitleri"
	fi
else
	echo "  RAPL interface bulunamadı"
fi

echo ""
echo "PİL DURUMU:"
if ((${#BAT_LINES[@]} == 0)); then
	echo "  Pil bulunamadı"
else
	printf "%s\n" "${BAT_LINES[@]}"
fi

echo ""
echo "SERVİS DURUMU:"
SERVICES=(battery-thresholds platform-profile cpu-epp cpu-epb cpu-min-freq-guard rapl-power-limits rapl-thermo-guard disable-rapl-mmio rapl-mmio-sync rapl-mmio-keeper)
for svc in "${SERVICES[@]}"; do
	STATE="$(systemctl show -p ActiveState --value "$svc.service" 2>/dev/null || echo "")"
	RESULT="$(systemctl show -p Result --value "$svc.service" 2>/dev/null || echo "")"
	if [[ ("$STATE" == "inactive" && "$RESULT" == "success") || "$STATE" == "active" ]]; then
		printf "  %-25s %s\n" "$svc" "✅ OK"
	else
		printf "  %-25s %s\n" "$svc" "⚠️  $STATE ($RESULT)"
	fi
done

echo ""
echo "💡 İpucu: Gerçek frekanslar için 'turbostat-quick'"
echo "💡 İpucu: Güç için 'power-check' / 'power-monitor' (veya bu scriptte --sample-power)"
echo "💡 JSON çıktı: ${BOLD}${0##*/} --json${RST}"
