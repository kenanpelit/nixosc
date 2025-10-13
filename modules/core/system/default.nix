# modules/core/system/default.nix
# ==============================================================================
# NixOS Sistem Konfigürasyonu - ThinkPad E14 Gen 6 (Core Ultra 7 155H)
# ==============================================================================
#
# Modül:     modules/core/system
# Versiyon:  11.0 - Final Stable Edition
# Tarih:     2025-10-12
# Platform:  ThinkPad E14 Gen 6 (Intel Core Ultra 7 155H, Meteor Lake)
#
# FELSEFİ YAKLAŞIM:
# -----------------
# "Minimal müdahale, maksimum responsive performans"
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
# ✅ Min Performance → %40 (yaklaşık 1700 MHz minimum)
# ✅ Active HWP mode (donanım kendi frekansları yönetiyor)
# ✅ RAPL Limits → 65W/115W (thermal throttling yok)
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
  # ROBUST SCRIPT HELPER
  # ============================================================================
  # Systemd servisleri için log'lu script oluşturur
  # Tüm output systemd journal'a gider
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
      "coretemp"    # CPU sıcaklık sensörü
      "i915"        # Intel GPU driver
    ] ++ lib.optionals isPhysicalMachine [
      "thinkpad_acpi"   # ThinkPad ACPI kontrolleri
    ];

    extraModprobeConfig = lib.optionalString isPhysicalMachine ''
      options thinkpad_acpi fan_control=1 experimental=1
    '';

    # Minimal kernel parametreleri
    # NOT: intel_pstate parametresi YOK - active HWP mode kullanılıyor
    kernelParams = [
      "i915.enable_guc=3"       # GPU GuC firmware
      "i915.enable_fbc=1"       # Frame buffer compression
      "mem_sleep_default=s2idle" # Modern standby
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
        intel-media-driver      # VA-API driver
        mesa                    # OpenGL
        vaapiVdpau             # Video decode
        libvdpau-va-gl         # VDPAU backend
        intel-compute-runtime  # OpenCL
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
  # Kendi özel servislerimizi kullanıyoruz
  services.auto-cpufreq.enable          = false;
  services.power-profiles-daemon.enable = false;
  services.tlp.enable                   = false;
  services.thermald.enable              = false;
  services.thinkfan.enable              = false;

  # ============================================================================
  # PLATFORM PROFILE - PERFORMANCE MODU
  # ============================================================================
  # ÇOK ÖNEMLİ: Bu servis olmadan ACPI CPU'yu agresif throttle ediyor!
  # Platform profile "balanced" modda CPU yük altında bile 400-900 MHz'e düşüyordu
  # "performance" modu ile bu sorun çözüldü
  systemd.services.platform-profile = lib.mkIf isPhysicalMachine {
    description = "Set ACPI platform profile to performance";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "platform-profile" ''
        echo "=== Platform Profile Configuration ==="
        
        if [[ -w "/sys/firmware/acpi/platform_profile" ]]; then
          CURRENT=$(cat /sys/firmware/acpi/platform_profile)
          echo "Current profile: $CURRENT"
          
          # Performance moduna geç
          echo "performance" > /sys/firmware/acpi/platform_profile 2>/dev/null
          
          NEW=$(cat /sys/firmware/acpi/platform_profile)
          if [[ "$NEW" == "performance" ]]; then
            echo "✓ Platform profile: performance"
            echo "  ACPI artık CPU'yu throttle etmeyecek"
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
  # CPU PERFORMANS KONFIGÜRASYONU
  # ============================================================================
  # ASIL ÇÖZÜM BURASI!
  # Min Performance %40 yapıyor (yaklaşık 1500 MHz minimum)
  # Bu sayede CPU idle'da bile responsive kalıyor
  systemd.services.cpu-min-freq-guard = lib.mkIf isPhysicalMachine {
    description = "Configure CPU for responsive performance (40% minimum)";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" "platform-profile.service" ];
    wants = [ "platform-profile.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "cpu-min-freq-guard" ''
        echo "=== CPU PERFORMANS KONFIGÜRASYONU ==="
        
        # Pstate interface'in hazır olmasını bekle
        sleep 2
        
        # Minimum performansı %40 yap
        if [[ -w "/sys/devices/system/cpu/intel_pstate/min_perf_pct" ]]; then
          echo 40 > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null
          
          WRITTEN=$(cat /sys/devices/system/cpu/intel_pstate/min_perf_pct)
          echo "✓ Minimum performans: $WRITTEN%"
          
          # Yaklaşık minimum frekansı hesapla
          CPUINFO_MAX=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null || echo 5000000)
          MAX_FREQ_MHZ=$((CPUINFO_MAX / 1000))
          MIN_FREQ_APPROX=$((MAX_FREQ_MHZ * WRITTEN / 100))
          echo "  Yaklaşık minimum frekans: ~$MIN_FREQ_APPROX MHz"
        else
          echo "⚠ min_perf_pct ayarlanamadı" >&2
          exit 1
        fi
        
        # Maksimum performansın sınırlanmadığından emin ol
        if [[ -w "/sys/devices/system/cpu/intel_pstate/max_perf_pct" ]]; then
          CURRENT_MAX=$(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct)
          if [[ "$CURRENT_MAX" -lt 100 ]]; then
            echo 100 > /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null
            echo "✓ Maksimum performans: 100% (tavan kaldırıldı)"
          fi
        fi
        
        # Turbo boost'un açık olduğundan emin ol
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
  # RAPL GÜÇ LİMİTLERİ
  # ============================================================================
  # Core Ultra 7 155H için optimal güç limitleri
  # PL1: 65W (sürekli yük) - Base TDP 28W'ın üstünde
  # PL2: 115W (kısa burst'ler için)
  # Bu limitler thermal throttling'i engelliyor
  systemd.services.rapl-power-limits = lib.mkIf isPhysicalMachine {
    description = "Set RAPL power limits (65W/115W)";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "rapl-power-limits" ''
        echo "=== RAPL GÜÇ LİMİTLERİ ==="
        
        PL1_WATTS=65   # Sürekli güç limiti
        PL2_WATTS=115  # Burst güç limiti
        
        echo "Hedef limitler: PL1=$PL1_WATTS W, PL2=$PL2_WATTS W"
        
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ ! -d "$R" ]] && continue
          RAPL_NAME=$(cat "$R/name" 2>/dev/null || echo "unknown")
          
          # PL1 ayarla
          if [[ -w "$R/constraint_0_power_limit_uw" ]]; then
            echo $((PL1_WATTS * 1000000)) > "$R/constraint_0_power_limit_uw" 2>/dev/null && \
            echo "✓ $RAPL_NAME PL1: $PL1_WATTS W"
          fi
          
          # PL2 ayarla
          if [[ -w "$R/constraint_1_power_limit_uw" ]]; then
            echo $((PL2_WATTS * 1000000)) > "$R/constraint_1_power_limit_uw" 2>/dev/null && \
            echo "✓ $RAPL_NAME PL2: $PL2_WATTS W"
          fi
        done
        
        echo "✓ Güç limitleri konfigüre edildi"
      '';
    };
  };

  # ============================================================================
  # PİL SAĞLIĞI YÖNETİMİ
  # ============================================================================
  # Pili %75'te şarj etmeye başla, %80'de durdur
  # Bu pil ömrünü uzatır
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
          
          # Başlangıç eşiği (75%)
          if [[ -w "$bat/charge_control_start_threshold" ]]; then
            echo 75 > "$bat/charge_control_start_threshold" 2>/dev/null && \
            echo "✓ $BAT_NAME: başlangıç eşiği = 75%" && SUCCESS=1
          fi
          
          # Bitiş eşiği (80%)
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
      lm_sensors    # Sıcaklık sensörleri
      stress-ng     # CPU stress test
      powertop      # Güç tüketimi analizi
      bc            # Hesap makinesi (power-check için)

      # ========================================================================
      # SYSTEM-STATUS: Sistem durumu gösterici
      # ========================================================================
      (writeScriptBin "system-status" ''
        #!${bash}/bin/bash
        echo "=== SİSTEM DURUMU ==="
        echo ""
        
        # Güç kaynağı
        ON_AC=0
        for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
        done
        echo "Güç Kaynağı: $([ "$ON_AC" = "1" ] && echo "AC" || echo "Pil")"
        
        # P-State modu ve performans
        if [[ -f "/sys/devices/system/cpu/intel_pstate/status" ]]; then
          PSTATE=$(cat /sys/devices/system/cpu/intel_pstate/status)
          echo "P-State Modu: $PSTATE"
          
          if [[ -r "/sys/devices/system/cpu/intel_pstate/min_perf_pct" ]]; then
            MIN_PERF=$(cat /sys/devices/system/cpu/intel_pstate/min_perf_pct)
            MAX_PERF=$(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null || echo "?")
            echo "  Min/Max Performans: $MIN_PERF% / $MAX_PERF%"
          fi
        fi
        
        # Platform profili
        if [[ -r "/sys/firmware/acpi/platform_profile" ]]; then
          PROFILE=$(cat /sys/firmware/acpi/platform_profile)
          echo "Platform Profili: $PROFILE"
        fi
        
        echo ""
        echo "CPU FREKANSLARI (örnek):"
        for i in 0 4 8 12 16 20; do
          if [[ -r "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq" ]]; then
            FREQ=$(cat "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq" 2>/dev/null || echo 0)
            printf "  CPU %2d: %4d MHz\n" "$i" "$((FREQ/1000))"
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
        for svc in battery-thresholds platform-profile cpu-min-freq-guard rapl-power-limits; do
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
      '')

      # ========================================================================
      # POWER-CHECK: Güç tüketimi ölçücü
      # ========================================================================
      (writeScriptBin "power-check" ''
        #!${bash}/bin/bash
        echo "=== GÜÇ TÜKETİMİ KONTROLÜ ==="
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
          echo "ANLIK GÜÇ TÜKETİMİ: ''${WATTS}W"
          echo ""
          
          PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw)
          PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw)
          
          echo "Güç Limitleri:"
          echo "  PL1 (sürekli): $((PL1/1000000))W"
          echo "  PL2 (burst):   $((PL2/1000000))W"
          echo ""
          
          # Ortalama frekans
          FREQ_SUM=0
          COUNT=0
          for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
            [[ -f "$f" ]] && FREQ_SUM=$((FREQ_SUM + $(cat "$f"))) && COUNT=$((COUNT + 1))
          done
          [[ $COUNT -gt 0 ]] && echo "Ortalama CPU frekansı: $((FREQ_SUM / COUNT / 1000)) MHz"
          
          # Sıcaklık
          TEMP=$(${lm_sensors}/bin/sensors 2>/dev/null | ${gnugrep}/bin/grep "Package id 0" | ${gawk}/bin/awk '{match($0, /[+]?([0-9]+\.[0-9]+)/, arr); print arr[1]}')
          [[ -n "$TEMP" ]] && echo "Package sıcaklığı: ''${TEMP}°C"
        else
          echo "RAPL interface bulunamadı"
        fi
      '')

      # ========================================================================
      # POWER-MONITOR: Gerçek zamanlı izleme
      # ========================================================================
      (writeScriptBin "power-monitor" ''
        #!${bash}/bin/bash
        echo "=== GERÇEK ZAMANLI GÜÇ MONİTÖRÜ ==="
        echo "Durdurmak için Ctrl+C"
        echo ""
        
        while true; do
          clear
          echo "=== GÜÇ MONİTÖRÜ ($(date '+%H:%M:%S')) ==="
          echo ""
          
          # RAPL güç tüketimi
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
            printf "  Anlık:  %6.2f W\n" "$WATTS"
            printf "  Limit 1: %6d W (sürekli)\n" $((PL1/1000000))
            printf "  Limit 2: %6d W (burst)\n" $((PL2/1000000))
            echo ""
          fi
          
          # CPU Frekansları
          echo "CPU FREKANSLARI:"
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
          
          # Sıcaklık
          echo "SICAKLIK:"
          TEMP=$(${lm_sensors}/bin/sensors 2>/dev/null | \
            ${gnugrep}/bin/grep "Package id 0" | \
            ${gawk}/bin/awk '{match($0, /[+]?([0-9]+\.[0-9]+)/, arr); print arr[1]}')
          [[ -n "$TEMP" ]] && printf "  Package: %5.1f°C\n" "$TEMP" || echo "  N/A"
          
          sleep 1
        done
      '')
    ];
}

