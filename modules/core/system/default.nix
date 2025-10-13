# modules/core/system/default.nix
# ==============================================================================
# NixOS Sistem Konfigürasyonu - ThinkPad E14 Gen 6 (Core Ultra 7 155H)
# ==============================================================================
#
# Modül:     modules/core/system
# Versiyon:  12.0 - EPP + AC/Battery Adaptive Edition
# Tarih:     2025-10-13
# Platform:  ThinkPad E14 Gen 6 (Intel Core Ultra 7 155H, Meteor Lake)
#
# FELSEFİ YAKLAŞIM:
# -----------------
# "Donanıma güven, sadece kritik yerleri düzelt"
# 
# YENİ ÖZELLİKLER (v12):
# ----------------------
# ✅ EPP (Energy Performance Preference) desteği
#    - AC'de: performance (maksimum tepkisellik)
#    - Pil'de: balance_power (verimlilik)
# ✅ AC/Pil ayrımı ile adaptif RAPL limitleri
#    - AC: 45W/90W (sürdürülebilir + burst)
#    - Pil: 28W/45W (verimli + ömür koruması)
# ✅ Suspend/resume sonrası otomatik yeniden uygulama
# ✅ HWP Dynamic Boost desteği
# ✅ turbostat monitoring aracı
#
# SORUN ÇÖZÜMÜ:
# -------------
# Bu konfigürasyon şu sorunu çözdü:
# - CPU'lar yük altında 400-900 MHz'e düşüyordu
# - ACPI Platform Profile "balanced" modda agresif throttling yapıyordu
# - Min Performance %8 gibi çok düşüktü
#
# ÇÖZÜM:
# ------
# ✅ Platform Profile → "performance" (ACPI throttling engellendi)
# ✅ EPP → AC'de "performance", Pil'de "balance_power"
# ✅ Min Performance → %30 (yaklaşık 1500 MHz minimum)
# ✅ Active HWP mode + Dynamic Boost (donanım kendi frekansları yönetiyor)
# ✅ RAPL Limits → AC/Pil'e göre adaptif (sürdürülebilir limitler)
# ✅ Battery Thresholds → 75-80% (pil ömrü koruması)
#
# ==============================================================================

{ pkgs, config, lib, inputs, system, ... }:

let
  # ============================================================================
  # SİSTEM TANIMLAMA
  # ============================================================================
  hostname          = config.networking.hostName or "";
  isPhysicalMachine = hostname == "hay";      # ThinkPad E14 Gen 6
  isVirtualMachine  = hostname == "vhay";     # QEMU/KVM VM

  # ============================================================================
  # CPU DETECTION - Multi-Platform Support
  # ============================================================================
  cpuDetectionScript = pkgs.writeShellScript "detect-cpu" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    
    CACHE_FILE="/run/cpu-detection.cache"
    
    # Cache varsa kullan
    if [[ -f "$CACHE_FILE" ]]; then
      cat "$CACHE_FILE"
      exit 0
    fi
    
    # CPU bilgilerini al
    CPU_MODEL="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'Model name' | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.gnused}/bin/sed 's/^ *//')"
    CPU_FAMILY="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'CPU family' | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.gnused}/bin/sed 's/^ *//')"
    
    echo "Detected CPU: $CPU_MODEL" >&2
    echo "CPU Family: $CPU_FAMILY" >&2
    
    # CPU tipini belirle
    RESULT=""
    if echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE "Core.*Ultra.*155H|Meteor Lake"; then
      RESULT="METEORLAKE"
    elif echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE "i7-8650U|Kaby Lake"; then
      RESULT="KABYLAKE"
    else
      RESULT="GENERIC"
    fi
    
    # Cache'e yaz ve döndür
    echo "$RESULT" | ${pkgs.coreutils}/bin/tee "$CACHE_FILE"
  '';

  # ============================================================================
  # AC/BATTERY DETECTION HELPER
  # ============================================================================
  detectPowerSource = ''
    ON_AC=0
    for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
      [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
    done
    echo "$ON_AC"
  '';

  # ============================================================================
  # ROBUST SCRIPT HELPER
  # ============================================================================
  mkRobustScript = name: content: pkgs.writeShellScript name ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    exec 1> >(${pkgs.util-linux}/bin/logger -t "power-mgmt-${name}" -p user.info)
    exec 2> >(${pkgs.util-linux}/bin/logger -t "power-mgmt-${name}" -p user.err)
    ${content}
  '';

in
{
  # ============================================================================
  # LOKALIZASYON & ZAMAN DİLİMİ
  # ============================================================================
  time.timeZone = "Europe/Istanbul";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS        = "tr_TR.UTF-8";
      LC_IDENTIFICATION = "tr_TR.UTF-8";
      LC_MEASUREMENT    = "tr_TR.UTF-8";
      LC_MONETARY       = "tr_TR.UTF-8";
      LC_NAME           = "tr_TR.UTF-8";
      LC_NUMERIC        = "tr_TR.UTF-8";
      LC_PAPER          = "tr_TR.UTF-8";
      LC_TELEPHONE      = "tr_TR.UTF-8";
      LC_TIME           = "tr_TR.UTF-8";
      LC_MESSAGES       = "en_US.UTF-8";
    };
  };

  services.xserver.xkb = {
    layout  = "tr";
    variant = "f";
    options = "ctrl:nocaps";
  };

  console = {
    keyMap = "trf";
    font = "ter-v20b";
    packages = [ pkgs.terminus_font ];
  };

  system.stateVersion = "25.11";

  # ============================================================================
  # BOOT KONFIGÜRASYONU
  # ============================================================================
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    kernelModules = [
      "coretemp"
      "i915"
    ] ++ lib.optionals isPhysicalMachine [
      "thinkpad_acpi"
    ];

    extraModprobeConfig = lib.optionalString isPhysicalMachine ''
      options thinkpad_acpi experimental=1
    '';

    kernelParams = [
      "i915.enable_guc=3"
      "i915.enable_fbc=1"
      "mem_sleep_default=s2idle"
    ];

    kernel.sysctl = {
      "vm.swappiness" = 60;
      "kernel.nmi_watchdog" = 0;
    };

    loader = {
      grub = {
        enable = true;
        device = lib.mkForce (if isVirtualMachine then "/dev/vda" else "nodev");
        efiSupport = isPhysicalMachine;
        useOSProber = true;
        configurationLimit = 10;
        gfxmodeEfi  = "1920x1200";
        gfxmodeBios = if isVirtualMachine then "1920x1080" else "1920x1200";
        theme = inputs.distro-grub-themes.packages.${system}.nixos-grub-theme;
      };

      efi = lib.mkIf isPhysicalMachine {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
  };

  # ============================================================================
  # DONANIM KONFIGÜRASYONU
  # ============================================================================
  hardware = {
    trackpoint = lib.mkIf isPhysicalMachine {
      enable = true;
      speed = 200;
      sensitivity = 200;
      emulateWheel = true;
    };

    graphics = {
      enable = true;
      enable32Bit = true;

      extraPackages = with pkgs; [
        intel-media-driver
        mesa
        vaapiVdpau
        libvdpau-va-gl
        intel-compute-runtime
      ];

      extraPackages32 = with pkgs.pkgsi686Linux; [
        intel-media-driver
      ];
    };

    enableRedistributableFirmware = true;
    enableAllFirmware             = true;
    cpu.intel.updateMicrocode     = true;
    bluetooth.enable              = true;
  };

  # ============================================================================
  # GÜÇ YÖNETİMİ SERVİSLERİ - HEPSİ DEVRE DIŞI
  # ============================================================================
  services.auto-cpufreq.enable          = false;
  services.power-profiles-daemon.enable = false;
  services.tlp.enable                   = false;
  services.thermald.enable              = false;
  services.thinkfan.enable              = false;

  # ============================================================================
  # PLATFORM PROFILE - PERFORMANCE MODU
  # ============================================================================
  systemd.services.platform-profile = lib.mkIf isPhysicalMachine {
    description = "Set ACPI platform profile to performance";
    wantedBy = [ "multi-user.target" "suspend.target" "hibernate.target" ];
    after = [ "multi-user.target" "suspend.target" "hibernate.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "platform-profile" ''
        echo "=== Platform Profile Configuration ==="
        
        if [[ -w "/sys/firmware/acpi/platform_profile" ]]; then
          CURRENT=$(cat /sys/firmware/acpi/platform_profile)
          echo "Current profile: $CURRENT"
          
          echo "performance" > /sys/firmware/acpi/platform_profile 2>/dev/null
          
          NEW=$(cat /sys/firmware/acpi/platform_profile)
          if [[ "$NEW" == "performance" ]]; then
            echo "✓ Platform profile: performance"
          else
            echo "⚠ Performance profile ayarlanamadı (current: $NEW)" >&2
          fi
        else
          echo "⚠ Platform profile interface bulunamadı"
        fi
      '';
    };
  };

  # ============================================================================
  # EPP (Energy Performance Preference)
  # ============================================================================
  systemd.services.cpu-epp = lib.mkIf isPhysicalMachine {
    description = "Set Intel EPP (AC=performance, Battery=balance_power)";
    wantedBy = [ "multi-user.target" "suspend.target" "hibernate.target" ];
    after = [ "multi-user.target" "suspend.target" "hibernate.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "cpu-epp" ''
        echo "=== EPP (Energy Performance Preference) ==="
        
        ON_AC=$(${detectPowerSource})
        
        if [[ "$ON_AC" = "1" ]]; then
          EPP="performance"
          SOURCE="AC"
        else
          EPP="balance_power"
          SOURCE="Battery"
        fi
        
        echo "Güç kaynağı: $SOURCE → EPP: $EPP"
        
        SUCCESS=0
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          if [[ -w "$pol/energy_performance_preference" ]]; then
            echo "$EPP" > "$pol/energy_performance_preference" 2>/dev/null && SUCCESS=1
          fi
        done
        
        if [[ "$SUCCESS" == "1" ]]; then
          echo "✓ EPP ayarlandı: $EPP"
        else
          echo "⚠ EPP interface'i bulunamadı" >&2
        fi
        
        if [[ -w /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost ]]; then
          echo 1 > /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost 2>/dev/null
          BOOST=$(cat /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost)
          if [[ "$BOOST" == "1" ]]; then
            echo "✓ HWP Dynamic Boost: aktif"
          fi
        fi
      '';
    };
  };

  # ============================================================================
  # CPU PERFORMANS KONFIGÜRASYONU
  # ============================================================================
  systemd.services.cpu-min-freq-guard = lib.mkIf isPhysicalMachine {
    description = "Configure CPU for responsive performance (30% minimum)";
    wantedBy = [ "multi-user.target" "suspend.target" "hibernate.target" ];
    after = [ "multi-user.target" "suspend.target" "hibernate.target" "platform-profile.service" ];
    wants = [ "platform-profile.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "cpu-min-freq-guard" ''
        echo "=== CPU PERFORMANS KONFIGÜRASYONU ==="
        
        sleep 2
        
        if [[ -w "/sys/devices/system/cpu/intel_pstate/min_perf_pct" ]]; then
          echo 30 > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null
          
          WRITTEN=$(cat /sys/devices/system/cpu/intel_pstate/min_perf_pct)
          echo "✓ Minimum performans: $WRITTEN%"
          
          CPUINFO_MAX=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null || echo 5000000)
          MAX_FREQ_MHZ=$((CPUINFO_MAX / 1000))
          MIN_FREQ_APPROX=$((MAX_FREQ_MHZ * WRITTEN / 100))
          echo "  Yaklaşık minimum frekans: ~$MIN_FREQ_APPROX MHz"
        else
          echo "⚠ min_perf_pct ayarlanamadı" >&2
          exit 1
        fi
        
        if [[ -w "/sys/devices/system/cpu/intel_pstate/max_perf_pct" ]]; then
          CURRENT_MAX=$(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct)
          if [[ "$CURRENT_MAX" -lt 100 ]]; then
            echo 100 > /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null
            echo "✓ Maksimum performans: 100%"
          fi
        fi
        
        if [[ -w "/sys/devices/system/cpu/intel_pstate/no_turbo" ]]; then
          echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null
          NO_TURBO=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
          if [[ "$NO_TURBO" == "0" ]]; then
            echo "✓ Turbo boost: aktif"
          fi
        fi
        
        echo ""
        echo "✓ CPU responsive performans için konfigüre edildi"
      '';
    };
  };

  # ============================================================================
  # RAPL GÜÇ LİMİTLERİ - AC/PİL ADAPTİF
  # ============================================================================
  systemd.services.rapl-power-limits = lib.mkIf isPhysicalMachine {
    description = "Set RAPL power limits (adaptive: CPU type + AC/Battery)";
    wantedBy = [ "multi-user.target" "suspend.target" "hibernate.target" ];
    after = [ "multi-user.target" "suspend.target" "hibernate.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "rapl-power-limits" ''
        echo "=== RAPL GÜÇ LİMİTLERİ (AC/PİL ADAPTİF) ==="
        
        CPU_TYPE="$(${cpuDetectionScript})"
        echo "CPU Tipi: $CPU_TYPE"
        
        ON_AC=$(${detectPowerSource})
        
        case "$CPU_TYPE" in
          METEORLAKE)
            PL1_AC=45;  PL2_AC=90
            PL1_BAT=28; PL2_BAT=45
            echo "  → Meteor Lake: Yüksek performans profili (28W TDP)"
            ;;
          KABYLAKE)
            PL1_AC=35;  PL2_AC=55
            PL1_BAT=20; PL2_BAT=35
            echo "  → Kaby Lake: Orta performans profili (15W TDP)"
            ;;
          *)
            PL1_AC=40;  PL2_AC=65
            PL1_BAT=22; PL2_BAT=40
            echo "  → Generic Intel: Dengeli profil"
            ;;
        esac
        
        if [[ "$ON_AC" = "1" ]]; then
          PL1="$PL1_AC"
          PL2="$PL2_AC"
          SOURCE="AC (Performans)"
        else
          PL1="$PL1_BAT"
          PL2="$PL2_BAT"
          SOURCE="Pil (Verimlilik)"
        fi
        
        echo "Güç Kaynağı: $SOURCE"
        echo "Hedef limitler: PL1=$PL1 W (sürekli), PL2=$PL2 W (burst)"
        
        SUCCESS=0
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ ! -d "$R" ]] && continue
          RAPL_NAME=$(cat "$R/name" 2>/dev/null || echo "unknown")
          
          if [[ -w "$R/constraint_0_power_limit_uw" ]]; then
            echo $((PL1 * 1000000)) > "$R/constraint_0_power_limit_uw" 2>/dev/null && \
            echo "✓ $RAPL_NAME PL1: $PL1 W (sürekli)" && SUCCESS=1
          fi
          
          if [[ -w "$R/constraint_1_power_limit_uw" ]]; then
            echo $((PL2 * 1000000)) > "$R/constraint_1_power_limit_uw" 2>/dev/null && \
            echo "✓ $RAPL_NAME PL2: $PL2 W (burst)" && SUCCESS=1
          fi
        done
        
        if [[ "$SUCCESS" == "1" ]]; then
          echo ""
          echo "✓ RAPL limitleri başarıyla uygulandı"
          echo "  Konfigürasyon: $CPU_TYPE + $SOURCE"
        else
          echo "⚠ RAPL interface'i bulunamadı" >&2
          exit 0
        fi
      '';
    };
  };

  # ============================================================================
  # PİL SAĞLIĞI YÖNETİMİ
  # ============================================================================
  systemd.services.battery-thresholds = lib.mkIf isPhysicalMachine {
    description = "Set battery charge thresholds (75-80%)";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "30s";
      StartLimitBurst = 3;
      ExecStart = mkRobustScript "battery-thresholds" ''
        echo "=== PİL ŞARJ EŞİKLERİ ==="
        
        SUCCESS=0
        for bat in /sys/class/power_supply/BAT*; do
          [[ ! -d "$bat" ]] && continue
          
          BAT_NAME=$(basename "$bat")
          
          if [[ -w "$bat/charge_control_start_threshold" ]]; then
            echo 75 > "$bat/charge_control_start_threshold" 2>/dev/null && \
            echo "✓ $BAT_NAME: başlangıç eşiği = 75%" && SUCCESS=1
          fi
          
          if [[ -w "$bat/charge_control_end_threshold" ]]; then
            echo 80 > "$bat/charge_control_end_threshold" 2>/dev/null && \
            echo "✓ $BAT_NAME: bitiş eşiği = 80%" && SUCCESS=1
          fi
        done
        
        if [[ "$SUCCESS" == "1" ]]; then
          echo "✓ Pil eşikleri: 75-80%"
        else
          echo "⚠ Pil eşik interface'i bulunamadı" >&2
          exit 0
        fi
      '';
    };
  };

  # ============================================================================
  # SİSTEM SERVİSLERİ
  # ============================================================================
  services = {
    upower.enable = true;

    logind.settings.Login = {
      HandleLidSwitch              = "suspend";
      HandleLidSwitchDocked        = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandlePowerKey               = "ignore";
      HandlePowerKeyLongPress      = "poweroff";
      HandleSuspendKey             = "suspend";
      HandleHibernateKey           = "hibernate";
    };

    spice-vdagentd.enable = lib.mkIf isVirtualMachine true;
  };

  # ============================================================================
  # MONİTÖRİNG ARAÇLARI
  # ============================================================================
  environment.systemPackages = with pkgs;
    lib.optionals isPhysicalMachine [
      lm_sensors
      stress-ng
      powertop
      bc
      linuxPackages_latest.turbostat

      # ========================================================================
      # SYSTEM-STATUS
      # ========================================================================
      (writeScriptBin "system-status" ''
        #!${bash}/bin/bash
        echo "=== SİSTEM DURUMU (v12) ==="
        echo ""
        
        ON_AC=0
        for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
        done
        echo "Güç Kaynağı: $([ "$ON_AC" = "1" ] && echo "⚡ AC" || echo "🔋 Pil")"
        
        if [[ -f "/sys/devices/system/cpu/intel_pstate/status" ]]; then
          PSTATE=$(cat /sys/devices/system/cpu/intel_pstate/status)
          echo "P-State Modu: $PSTATE"
          
          if [[ -r "/sys/devices/system/cpu/intel_pstate/min_perf_pct" ]]; then
            MIN_PERF=$(cat /sys/devices/system/cpu/intel_pstate/min_perf_pct)
            MAX_PERF=$(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null || echo "?")
            echo "  Min/Max Performans: $MIN_PERF% / $MAX_PERF%"
          fi
          
          if [[ -r "/sys/devices/system/cpu/intel_pstate/no_turbo" ]]; then
            NO_TURBO=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
            echo "  Turbo Boost: $([ "$NO_TURBO" = "0" ] && echo "✓ Aktif" || echo "✗ Kapalı")"
          fi
          
          if [[ -r "/sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost" ]]; then
            BOOST=$(cat /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost)
            echo "  HWP Dynamic Boost: $([ "$BOOST" = "1" ] && echo "✓ Aktif" || echo "✗ Kapalı")"
          fi
        fi
        
        if [[ -r "/sys/firmware/acpi/platform_profile" ]]; then
          PROFILE=$(cat /sys/firmware/acpi/platform_profile)
          echo "Platform Profili: $PROFILE"
        fi
        
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
        
        echo ""
        echo "CPU FREKANSLARI (örnek çekirdekler):"
        for i in 0 4 8 12 16 20; do
          if [[ -r "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq" ]]; then
            FREQ=$(cat "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq" 2>/dev/null || echo 0)
            printf "  CPU %2d: %4d MHz\n" "$i" "$((FREQ/1000))"
          fi
        done
        
        echo ""
        echo "RAPL GÜÇ LİMİTLERİ:"
        for R in /sys/class/powercap/intel-rapl:0; do
          if [[ -d "$R" ]]; then
            PL1=$(cat "$R/constraint_0_power_limit_uw" 2>/dev/null || echo 0)
            PL2=$(cat "$R/constraint_1_power_limit_uw" 2>/dev/null || echo 0)
            echo "  PL1 (sürekli): $((PL1/1000000)) W"
            echo "  PL2 (burst):   $((PL2/1000000)) W"
          fi
        done
        
        echo ""
        echo "PİL DURUMU:"
        for bat in /sys/class/power_supply/BAT*; do
          [[ -d "$bat" ]] || continue
          NAME=$(basename "$bat")
          CAPACITY=$(cat "$bat/capacity" 2>/dev/null || echo "N/A")
          STATUS=$(cat "$bat/status" 2>/dev/null || echo "N/A")
          START=$(cat "$bat/charge_control_start_threshold" 2>/dev/null || echo "N/A")
          STOP=$(cat "$bat/charge_control_end_threshold" 2>/dev/null || echo "N/A")
          echo "  $NAME: $CAPACITY% ($STATUS) [Eşikler: $START-$STOP%]"
        done
        
        echo ""
        echo "SERVİS DURUMU:"
        for svc in battery-thresholds platform-profile cpu-epp cpu-min-freq-guard rapl-power-limits; do
          STATE=$(${systemd}/bin/systemctl show -p ActiveState --value "$svc.service" 2>/dev/null)
          RESULT=$(${systemd}/bin/systemctl show -p Result --value "$svc.service" 2>/dev/null)
          
          if [[ "$STATE" == "inactive" ]] && [[ "$RESULT" == "success" ]]; then
            echo "  ✅ $svc"
          elif [[ "$STATE" == "active" ]]; then
            echo "  ✅ $svc"
          else
            echo "  ⚠️  $svc ($STATE)"
          fi
        done
        
        echo ""
        echo "💡 İpucu: Gerçek frekanslar için 'turbostat-quick' kullanın"
        echo "💡 Güç tüketimi için 'power-check' veya 'power-monitor' kullanın"
      '')

      # ========================================================================
      # TURBOSTAT-QUICK
      # ========================================================================
      (writeScriptBin "turbostat-quick" ''
        #!${bash}/bin/bash
        echo "=== TURBOSTAT HIZLI ANALİZ ==="
        echo "5 saniye boyunca CPU davranışı izleniyor..."
        echo ""
        echo "NOT: 'Avg_MHz' sütunu GERÇEK ortalama frekansı gösterir"
        echo "     'Bzy_MHz' meşgul çekirdeklerin frekansını gösterir"
        echo "     scaling_cur_freq'deki 400 MHz değerleri yanıltıcıdır!"
        echo ""
        
        if ! command -v turbostat &> /dev/null; then
          echo "⚠ turbostat bulunamadı"
          exit 1
        fi
        
        sudo ${linuxPackages_latest.turbostat}/bin/turbostat --interval 5 --num_iterations 1
      '')

      # ========================================================================
      # TURBOSTAT-STRESS
      # ========================================================================
      (writeScriptBin "turbostat-stress" ''
        #!${bash}/bin/bash
        echo "=== CPU PERFORMANS TESTİ ==="
        echo "10 saniye stress + turbostat analizi"
        echo ""
        
        if ! command -v turbostat &> /dev/null || ! command -v stress-ng &> /dev/null; then
          echo "⚠ Gerekli araçlar bulunamadı"
          exit 1
        fi
        
        echo "Başlangıç durumu (idle):"
        sudo ${linuxPackages_latest.turbostat}/bin/turbostat --interval 2 --num_iterations 1
        
        echo ""
        echo "Stress test başlatılıyor..."
        ${stress-ng}/bin/stress-ng --cpu 0 --timeout 10s &
        STRESS_PID=$!
        
        sleep 1
        echo "Yük altında analiz:"
        sudo ${linuxPackages_latest.turbostat}/bin/turbostat --interval 8 --num_iterations 1
        
        wait $STRESS_PID 2>/dev/null
        
        echo ""
        echo "Stress test tamamlandı"
        echo ""
        echo "📊 Değerlendirme:"
        echo "   - Avg_MHz değerine bakın (2000+ MHz iyi)"
        echo "   - Package sıcaklığını kontrol edin (85°C altı ideal)"
        echo "   - Watt değerlerini RAPL limitleri ile karşılaştırın"
      '')

      # ========================================================================
      # POWER-CHECK
      # ========================================================================
      (writeScriptBin "power-check" ''
        #!${bash}/bin/bash
        echo "=== GÜÇ TÜKETİMİ ANALİZİ (v12) ==="
        echo ""
        
        ON_AC=0
        for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
        done
        echo "Güç Kaynağı: $([ "$ON_AC" = "1" ] && echo "⚡ AC" || echo "🔋 Pil")"
        echo ""
        
        if [[ -d /sys/class/powercap/intel-rapl:0 ]]; then
          echo "2 saniye boyunca güç tüketimi ölçülüyor..."
          
          ENERGY_BEFORE=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)
          sleep 2
          ENERGY_AFTER=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)
          
          ENERGY_DIFF=$((ENERGY_AFTER - ENERGY_BEFORE))
          if [[ $ENERGY_DIFF -lt 0 ]]; then
            ENERGY_DIFF=$ENERGY_AFTER
          fi
          
          WATTS=$(echo "scale=2; $ENERGY_DIFF / 2000000" | ${bc}/bin/bc)
          
          echo ""
          echo "ANLIK PACKAGE GÜÇ: ''${WATTS}W"
          echo ""
          
          PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw)
          PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw)
          
          echo "Aktif RAPL Limitleri:"
          printf "  PL1 (sürekli): %3d W\n" $((PL1/1000000))
          printf "  PL2 (burst):   %3d W\n" $((PL2/1000000))
          echo ""
          
          WATTS_INT=$(echo "$WATTS" | ${coreutils}/bin/cut -d. -f1)
          if [[ "$WATTS_INT" -lt 10 ]]; then
            echo "📊 Durum: İdeal (düşük güç tüketimi)"
          elif [[ "$WATTS_INT" -lt 30 ]]; then
            echo "📊 Durum: Normal (günlük kullanım)"
          elif [[ "$WATTS_INT" -lt 50 ]]; then
            echo "📊 Durum: Yüksek (yoğun işlem)"
          else
            echo "📊 Durum: Çok Yüksek (stres testi?)"
          fi
          
          FREQ_SUM=0
          COUNT=0
          for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
            [[ -f "$f" ]] && FREQ_SUM=$((FREQ_SUM + $(cat "$f"))) && COUNT=$((COUNT + 1))
          done
          [[ $COUNT -gt 0 ]] && echo "Ortalama scaling freq: $((FREQ_SUM / COUNT / 1000)) MHz"
          
          TEMP=$(${lm_sensors}/bin/sensors 2>/dev/null | ${gnugrep}/bin/grep "Package id 0" | ${gawk}/bin/awk '{match($0, /[+]?([0-9]+\.[0-9]+)/, arr); print arr[1]}')
          [[ -n "$TEMP" ]] && printf "Package sıcaklığı: %.1f°C\n" "$TEMP"
          
          echo ""
          echo "💡 İpucu: 'turbostat-quick' gerçek frekansları gösterir"
        else
          echo "⚠ RAPL interface bulunamadı"
        fi
      '')

      # ========================================================================
      # POWER-MONITOR
      # ========================================================================
      (writeScriptBin "power-monitor" ''
        #!${bash}/bin/bash
        echo "=== GERÇEK ZAMANLI GÜÇ MONİTÖRÜ (v12) ==="
        echo "Durdurmak için Ctrl+C"
        echo ""
        
        while true; do
          clear
          echo "=== GÜÇ MONİTÖRÜ ($(date '+%H:%M:%S')) ==="
          echo ""
          
          ON_AC=0
          for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
            [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
          done
          echo "Güç Kaynağı: $([ "$ON_AC" = "1" ] && echo "⚡ AC" || echo "🔋 Pil")"
          echo ""
          
          if [[ -d /sys/class/powercap/intel-rapl:0 ]]; then
            ENERGY_BEFORE=$(cat /sys/class/powercap/intel-rapl:0/energy_uj 2>/dev/null || echo 0)
            sleep 0.5
            ENERGY_AFTER=$(cat /sys/class/powercap/intel-rapl:0/energy_uj 2>/dev/null || echo 0)
            
            ENERGY_DIFF=$((ENERGY_AFTER - ENERGY_BEFORE))
            if [[ $ENERGY_DIFF -lt 0 ]]; then
              ENERGY_DIFF=$ENERGY_AFTER
            fi
            WATTS=$(echo "scale=2; $ENERGY_DIFF / 500000" | ${bc}/bin/bc)
            
            PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0)
            PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0)
            
            echo "PACKAGE GÜÇ:"
            printf "  Anlık:   %6.2f W\n" "$WATTS"
            printf "  Limit 1: %6d W (sürekli)\n" $((PL1/1000000))
            printf "  Limit 2: %6d W (burst)\n" $((PL2/1000000))
            echo ""
          fi
          
          for pol in /sys/devices/system/cpu/cpufreq/policy0; do
            if [[ -r "$pol/energy_performance_preference" ]]; then
              EPP=$(cat "$pol/energy_performance_preference")
              echo "EPP: $EPP"
              echo ""
              break
            fi
          done
          
          echo "CPU FREKANSLARI (scaling):"
          FREQ_SUM=0
          FREQ_COUNT=0
          FREQ_MIN=9999999
          FREQ_MAX=0
          
          for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
            [[ -f "$f" ]] || continue
            FREQ=$(cat "$f")
            FREQ_SUM=$((FREQ_SUM + FREQ))
            FREQ_COUNT=$((FREQ_COUNT + 1))
            
            [[ $FREQ -lt $FREQ_MIN ]] && FREQ_MIN=$FREQ
            [[ $FREQ -gt $FREQ_MAX ]] && FREQ_MAX=$FREQ
          done
          
          if [[ $FREQ_COUNT -gt 0 ]]; then
            FREQ_AVG=$((FREQ_SUM / FREQ_COUNT))
            printf "  Ortalama: %4d MHz\n" $((FREQ_AVG/1000))
            printf "  Minimum:  %4d MHz\n" $((FREQ_MIN/1000))
            printf "  Maximum:  %4d MHz\n" $((FREQ_MAX/1000))
          fi
          echo ""
          
          echo "SICAKLIK:"
          TEMP=$(${lm_sensors}/bin/sensors 2>/dev/null | \
            ${gnugrep}/bin/grep "Package id 0" | \
            ${gawk}/bin/awk '{match($0, /[+]?([0-9]+\.[0-9]+)/, arr); print arr[1]}')
          [[ -n "$TEMP" ]] && printf "  Package: %5.1f°C\n" "$TEMP" || echo "  N/A"
          
          echo ""
          echo "⚠ NOT: scaling_cur_freq değerleri yanıltıcı olabilir!"
          echo "   Gerçek frekanslar için 'turbostat-quick' kullanın"
          
          sleep 1
        done
      '')

      # ========================================================================
      # POWER-PROFILE-REFRESH
      # ========================================================================
      (writeScriptBin "power-profile-refresh" ''
        #!${bash}/bin/bash
        echo "=== GÜÇ PROFİLİ YENİLEME ==="
        echo ""
        echo "EPP ve RAPL servislerini yeniden tetikliyor..."
        echo ""
        
        sudo ${systemd}/bin/systemctl restart cpu-epp.service
        sudo ${systemd}/bin/systemctl restart rapl-power-limits.service
        
        echo "✓ Servisler yenilendi"
        echo ""
        echo "Yeni durum:"
        system-status
      '')
    ];
}
