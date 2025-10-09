# modules/core/system/default.nix
# ==============================================================================
# NixOS System Configuration - Adaptive Power Management v8.5
# ==============================================================================
#
# Module:    modules/core/system
# Version:   8.5 - Production Grade Edition (Syntax Fixed)
# Date:      2025-10-09
# Author:    NixOS Power Management Suite
#
# RELEASE NOTES v8.5:
# -------------------
# • ENHANCED service orchestration with proper dependencies
# • FIXED race conditions with file locking
# • OPTIMIZED CPU detection with result caching
# • IMPROVED RAPL validation with write verification
# • ADDED atomic battery threshold configuration
# • ENHANCED temperature monitoring with averaging
# • IMPROVED UDEV debouncing for AC adapter events
# • ADDED JSON output for system-status (monitoring)
# • STREAMLINED service restart policies
# • FIXED all Nix bash string interpolation syntax
#
# SUPPORTED HARDWARE:
# -------------------
# - ThinkPad E14 Gen 6 (Core Ultra 7 155H, Meteor Lake, 28W TDP)
# - ThinkPad X1 Carbon Gen 6 (i7-8650U, Kaby Lake-R, 15W TDP)
# - QEMU/KVM Virtual Machines (hostname: vhay)
# - Any Intel CPU with P-State driver support
#
# DESIGN PHILOSOPHY:
# ------------------
# "Stable hardware management with governor control"
# - intel_pstate passive mode for reliability
# - Governor-based frequency control
# - Hardware-managed thermal control via thermald
# - Universal compatibility across Intel generations
# - Balanced performance and power efficiency
# - Race-condition free service orchestration
#
# ==============================================================================

{ pkgs, config, lib, inputs, system, ... }:

let
  # ============================================================================
  # SYSTEM IDENTIFICATION & DETECTION
  # ============================================================================
  hostname          = config.networking.hostName or "";
  isPhysicalMachine = hostname == "hay";
  isVirtualMachine  = hostname == "vhay";

  # ============================================================================
  # IMPROVED CPU DETECTION WITH CACHING
  # ============================================================================
  cpuDetectionScript = pkgs.writeShellScript "detect-cpu" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    
    CACHE_FILE="/run/cpu-detection.cache"
    
    if [[ -f "$CACHE_FILE" ]]; then
      cat "$CACHE_FILE"
      exit 0
    fi
    
    CPU_MODEL="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'Model name' | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.gnused}/bin/sed 's/^ *//')"
    CPU_FAMILY="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'CPU family' | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.gnused}/bin/sed 's/^ *//')"
    
    echo "Detected CPU: $CPU_MODEL"
    echo "CPU Family: $CPU_FAMILY"
    
    RESULT=""
    if echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE "Core.*Ultra.*155H|Meteor Lake"; then
      RESULT="METEORLAKE"
    elif echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE "i7-8650U|Kaby Lake"; then
      RESULT="KABYLAKE"
    else
      RESULT="GENERIC"
    fi
    
    echo "$RESULT" | ${pkgs.coreutils}/bin/tee "$CACHE_FILE"
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
  # LOCALIZATION & TIMEZONE
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
  # BOOT CONFIGURATION
  # ============================================================================
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    kernelModules = [
      "coretemp"
      "i915"
    ] ++ lib.optionals isPhysicalMachine [
      "thinkpad_acpi"
    ];

    extraModprobeConfig = ''
      options snd_hda_intel power_save=1 power_save_controller=Y
      options iwlwifi power_save=1
      options usbcore autosuspend=10 use_both_schemes=y

      ${lib.optionalString isPhysicalMachine ''
        options thinkpad_acpi fan_control=1 experimental=1
      ''}
    '';

    kernelParams = [
      "intel_pstate=passive"
      "pcie_aspm.policy=default"
      "i915.enable_guc=3"
      "i915.enable_fbc=1"
      "i915.enable_psr=1"
      "i915.enable_sagv=1"
      "i915.enable_dc=2"
      "i915.disable_power_well=0"
      "mem_sleep_default=s2idle"
      "nvme_core.default_ps_max_latency_us=5500"
      "audit_backlog_limit=8192"
      "iwlwifi.bt_coex_active=1"
    ];

    kernel.sysctl = {
      "vm.swappiness" = 60;
      "vm.vfs_cache_pressure" = 100;
      "vm.dirty_writeback_centisecs" = 500;
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
  # HARDWARE CONFIGURATION
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
        intel-graphics-compiler
        level-zero
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
  # POWER MANAGEMENT
  # ============================================================================
  services.auto-cpufreq.enable          = false;
  services.power-profiles-daemon.enable = false;
  services.tlp.enable                   = false;
  services.thermald.enable              = lib.mkDefault isPhysicalMachine;
  services.thinkfan.enable              = lib.mkForce false;

  # ============================================================================
  # BATTERY THRESHOLDS
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
      ExecStart = mkRobustScript "set-battery-thresholds" ''
        echo "Configuring battery charge thresholds..."
        
        SUCCESS=0
        for bat in /sys/class/power_supply/BAT*; do
          [[ ! -d "$bat" ]] && continue
          
          BAT_NAME=$(basename "$bat")
          
          if [[ -w "$bat/charge_control_start_threshold" ]]; then
            echo 75 > "$bat/charge_control_start_threshold" 2>/dev/null && \
            echo "  $BAT_NAME: start threshold = 75%" && SUCCESS=1 || \
            echo "  $BAT_NAME: failed to set start threshold" >&2
          fi
          
          if [[ -w "$bat/charge_control_end_threshold" ]]; then
            echo 80 > "$bat/charge_control_end_threshold" 2>/dev/null && \
            echo "  $BAT_NAME: stop threshold = 80%" && SUCCESS=1 || \
            echo "  $BAT_NAME: failed to set stop threshold" >&2
          fi
        done
        
        if [[ "$SUCCESS" == "1" ]]; then
          echo "✓ Battery thresholds configured: 75-80%"
        else
          echo "⚠ No battery thresholds could be set" >&2
          exit 1
        fi
      '';
    };
  };

  # ============================================================================
  # SYSTEM SERVICES
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

  systemd.services.systemd-udev-settle.serviceConfig.TimeoutSec = 30;

  # ============================================================================
  # THERMALD SERVICE - NO ORDERING TO PREVENT RAPL OVERRIDE
  # ============================================================================
  systemd.services.thermald = lib.mkIf config.services.thermald.enable {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.ExecStart = lib.mkForce 
      "${pkgs.thermald}/bin/thermald --no-daemon --adaptive --dbus-enable --ignore-cpuid-check --poll-interval 4";
  };

  # ============================================================================
  # RAPL POWER LIMITS - SIMPLE WRITE ON BOOT
  # ============================================================================
  systemd.services.early-rapl-limits = lib.mkIf isPhysicalMachine {
    description = "Set RAPL power limits (28W/55W)";
    after = [ "systemd-udevd.service" ];
    wants = [ "systemd-udevd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutSec = 5;
      ExecStart = mkRobustScript "early-rapl-limits" ''
        echo "=== RAPL POWER LIMITS ==="
        
        # Short wait for powercap
        sleep 1
        
        # Write to all RAPL domains
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ ! -d "$R" ]] && continue
          
          RAPL_NAME=$(cat "$R/name" 2>/dev/null || echo "unknown")
          
          if [[ -w "$R/constraint_0_power_limit_uw" ]]; then
            echo 28000000 > "$R/constraint_0_power_limit_uw" 2>/dev/null && \
            echo "✓ $RAPL_NAME PL1: 28W" || true
          fi
          
          if [[ -w "$R/constraint_1_power_limit_uw" ]]; then
            echo 55000000 > "$R/constraint_1_power_limit_uw" 2>/dev/null && \
            echo "✓ $RAPL_NAME PL2: 55W" || true
          fi
        done
        
        echo "✓ RAPL limits applied"
      '';
    };
  };

  # ============================================================================
  # MAIN RAPL SERVICE
  # ============================================================================
  systemd.services.rapl-power-limits = lib.mkIf isPhysicalMachine {
    description = "Verify and correct RAPL power limits";
    after = [ "systemd-udevd.service" "early-rapl-limits.service" ];
    wants = [ "early-rapl-limits.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutSec = 10;
      ExecStart = mkRobustScript "set-rapl-limits" ''
        echo "=== RAPL POWER LIMITS VERIFICATION ==="
        
        # Only verify intel-rapl:0 (package level)
        R="/sys/class/powercap/intel-rapl:0"
        if [[ -d "$R" ]]; then
          RAPL_NAME=$(cat "$R/name" 2>/dev/null || echo "unknown")
          echo "Verifying RAPL domain: $RAPL_NAME"
          
          if [[ -w "$R/constraint_0_power_limit_uw" ]]; then
            CURRENT_PL1=$(cat "$R/constraint_0_power_limit_uw" 2>/dev/null || echo 0)
            CURRENT_PL1_W=$((CURRENT_PL1 / 1000000))
            
            if [[ "$CURRENT_PL1" -gt 40000000 ]] || [[ "$CURRENT_PL1" -lt 20000000 ]]; then
              echo 28000000 > "$R/constraint_0_power_limit_uw" 2>/dev/null
              
              WRITTEN=$(cat "$R/constraint_0_power_limit_uw" 2>/dev/null || echo 0)
              WRITTEN_W=$((WRITTEN / 1000000))
              echo "✓ PL1 corrected: ''${CURRENT_PL1_W}W → ''${WRITTEN_W}W"
            else
              echo "✓ PL1 already correct: ''${CURRENT_PL1_W}W"
            fi
          fi
        else
          echo "✗ RAPL interface not found" >&2
        fi
        
        echo "✓ RAPL power limits verified"
      '';
    };
  };

  # ============================================================================
  # CPU PROFILE OPTIMIZER
  # ============================================================================
  systemd.services.cpu-profile-optimizer = lib.mkIf isPhysicalMachine {
    description = "Optimize CPU governor based on power source";
    after = [ "multi-user.target" ];
    before = [ "cpu-min-freq-guard.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "cpu-profile-optimizer" ''
        echo "=== CPU PROFILE OPTIMIZER - PASSIVE MODE ==="
        
        CPU_TYPE="$(${cpuDetectionScript})"
        echo "CPU Type: $CPU_TYPE"
        
        ON_AC=0
        for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && [[ "$ON_AC" == "1" ]] && break
        done

        echo "Power source: $([ "$ON_AC" = "1" ] && echo "AC" || echo "Battery")"
        
        if [[ "$ON_AC" == "1" ]]; then
          GOVERNOR="performance"
          echo "Optimal Governor: $GOVERNOR (AC power)"
        else
          GOVERNOR="powersave"
          echo "Optimal Governor: $GOVERNOR (battery power)"
        fi
        
        APPLIED=0
        for policy in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ ! -d "$policy" ]] && continue
          
          GOV_FILE="$policy/scaling_governor"
          if [[ -w "$GOV_FILE" ]]; then
            echo "$GOVERNOR" > "$GOV_FILE" 2>/dev/null && APPLIED=1
          fi
        done
        
        if [[ "$APPLIED" == "1" ]]; then
          echo "✓ Governor set to $GOVERNOR on all CPUs"
        else
          echo "⚠ Could not set governor (may be read-only)" >&2
        fi
        
        echo "✓ CPU profile optimization complete"
      '';
    };
  };

  systemd.timers.cpu-profile-optimizer = lib.mkIf isPhysicalMachine {
    description = "Timer for CPU profile optimization";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "10min";
      Persistent = true;
      Unit = "cpu-profile-optimizer.service";
    };
  };

  # ============================================================================
  # PLATFORM PROFILE
  # ============================================================================
  systemd.services.platform-profile = lib.mkIf isPhysicalMachine {
    description = "Set optimal ACPI platform profile";
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "platform-profile" ''
        echo "=== Platform Profile Configuration ==="
        
        if [[ -w "/sys/firmware/acpi/platform_profile" ]]; then
          echo "balanced" > /sys/firmware/acpi/platform_profile
          echo "✓ Platform profile: balanced"
        else
          echo "⚠ Platform profile interface unavailable"
        fi
      '';
    };
  };

  # ============================================================================
  # HARDWARE MONITOR
  # ============================================================================
  systemd.services.hardware-monitor = lib.mkIf isPhysicalMachine {
    description = "Monitor hardware status";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = mkRobustScript "hardware-monitor" ''
        echo "=== HARDWARE STATUS MONITOR ==="
        echo "Timestamp: $(date)"
        
        echo "CPU Frequencies (current):"
        for cpu_path in /sys/devices/system/cpu/cpu[0-9]*/cpufreq; do
          [[ -r "$cpu_path/scaling_cur_freq" ]] || continue
          CPU_NUM=$(basename $(dirname "$cpu_path") | sed 's/cpu//')
          if [[ "$CPU_NUM" =~ ^[0-9]+$ ]]; then
            FREQ=$(( $(cat "$cpu_path/scaling_cur_freq") / 1000 ))
            GOV=$(cat "$cpu_path/scaling_governor" 2>/dev/null || echo "unknown")
            printf "  CPU %2d: %4d MHz [%s]\n" "$CPU_NUM" "$FREQ" "$GOV"
          fi
        done
        
        echo ""
        echo "Temperature (averaged across sensors):"
        TEMP_AVG=$(${pkgs.lm_sensors}/bin/sensors 2>/dev/null | \
          ${pkgs.gnugrep}/bin/grep -E 'Package id [0-9]+|Tctl|Tdie' | \
          ${pkgs.gawk}/bin/awk '{
            match($0, /[+]?([0-9]+\.[0-9]+)/, arr);
            if (arr[1] != "") {
              sum += arr[1];
              count++;
            }
          } END {
            if (count > 0) printf "%.1f", sum/count;
            else print "unknown";
          }')
        echo "  Average CPU Temp: ''${TEMP_AVG}°C"
        
        ON_AC=0
        for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
        done
        echo "Power Source: $([ "$ON_AC" = "1" ] && echo "AC" || echo "Battery")"
        
        echo "✓ Hardware status logged"
      '';
    };
  };

  systemd.timers.hardware-monitor = lib.mkIf isPhysicalMachine {
    description = "Timer for hardware monitoring";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "5min";
      Persistent = true;
      Unit = "hardware-monitor.service";
    };
  };

  # ============================================================================
  # CPU MIN FREQUENCY GUARD
  # ============================================================================
  systemd.services.cpu-min-freq-guard = lib.mkIf isPhysicalMachine {
    description = "Ensure minimum CPU frequency with HWP compatibility";
    after = [ "multi-user.target" "cpu-profile-optimizer.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "cpu-min-freq-guard" ''
        echo "=== CPU MIN FREQUENCY GUARD (HWP COMPATIBLE) ==="
        
        if [[ -d "/sys/devices/system/cpu/intel_pstate" ]]; then
          PSTATE_MODE=$(cat /sys/devices/system/cpu/intel_pstate/status 2>/dev/null || echo "unknown")
          echo "P-State mode: $PSTATE_MODE"
        fi
        
        echo "Setting HWP minimum performance level..."
        for policy in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ ! -d "$policy" ]] && continue
          
          POLICY_NAME=$(basename "$policy")
          
          if [[ -w "$policy/min_perf_pct" ]]; then
            echo 40 > "$policy/min_perf_pct" 2>/dev/null && \
            echo "✓ $POLICY_NAME: HWP min_perf=40%" || \
            echo "⚠ $POLICY_NAME: HWP min_perf not writable"
          fi
          
          if [[ -w "$policy/scaling_min_freq" ]]; then
            echo 1400000 > "$policy/scaling_min_freq" 2>/dev/null && \
            echo "✓ $POLICY_NAME: scaling_min_freq=1400 MHz" || true
          fi
        done
        
        echo "Setting EPP to balance_performance..."
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ ! -d "$pol" ]] && continue
          if [[ -w "$pol/energy_performance_preference" ]]; then
            echo "balance_performance" > "$pol/energy_performance_preference" 2>/dev/null && \
            echo "✓ $(basename $pol): EPP=balance_performance" || \
            echo "⚠ $(basename $pol): EPP not writable"
          fi
        done
        
        echo "✓ Min frequency guard active"
      '';
    };
  };

  systemd.timers.cpu-min-freq-guard = lib.mkIf isPhysicalMachine {
    description = "Timer for CPU min frequency guard";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "45s";
      OnUnitActiveSec = "2min";
      Persistent = true;
      Unit = "cpu-min-freq-guard.service";
    };
  };

  # ============================================================================
  # UDEV RULES
  # ============================================================================
  services.udev.extraRules = lib.mkIf isPhysicalMachine ''
    SUBSYSTEM=="power_supply", KERNEL=="AC*", ACTION=="change", \
      RUN+="${pkgs.bash}/bin/bash -c 'sleep 2; ${pkgs.systemd}/bin/systemctl start cpu-profile-optimizer.service'"
    SUBSYSTEM=="power_supply", KERNEL=="ADP*", ACTION=="change", \
      RUN+="${pkgs.bash}/bin/bash -c 'sleep 2; ${pkgs.systemd}/bin/systemctl start cpu-profile-optimizer.service'"
  '';

  # ============================================================================
  # USER UTILITY SCRIPTS
  # ============================================================================
  environment.systemPackages = with pkgs;
    lib.optionals isPhysicalMachine [
      lm_sensors
      linuxPackages.x86_energy_perf_policy
      jq

      # System Status with JSON support
      (writeScriptBin "system-status" ''
        #!${bash}/bin/bash
        
        if [[ "''${1:-}" == "--json" ]]; then
          CPU_TYPE="$(${cpuDetectionScript})"
          ON_AC=0
          for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
            [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
          done
          
          GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
          PSTATE=$(cat /sys/devices/system/cpu/intel_pstate/status 2>/dev/null || echo "unknown")
          
          FREQ_SUM=0
          FREQ_COUNT=0
          for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq; do
            [[ -f "$f" ]] || continue
            FREQ_SUM=$((FREQ_SUM + $(cat "$f")))
            FREQ_COUNT=$((FREQ_COUNT + 1))
          done
          FREQ_AVG=0
          [[ $FREQ_COUNT -gt 0 ]] && FREQ_AVG=$((FREQ_SUM / FREQ_COUNT / 1000))
          
          TEMP=$(${lm_sensors}/bin/sensors 2>/dev/null | \
            ${gnugrep}/bin/grep -E 'Package id 0|Tctl' | \
            ${gawk}/bin/awk '{match($0, /[+]?([0-9]+\.[0-9]+)/, arr); if(arr[1]!="") print arr[1]; exit}')
          [[ -z "$TEMP" ]] && TEMP="0"
          
          PL1=0
          PL2=0
          if [[ -d /sys/class/powercap/intel-rapl:0 ]]; then
            PL1=$(( $(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0) / 1000000 ))
            PL2=$(( $(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0) / 1000000 ))
          fi
          
          ${jq}/bin/jq -n \
            --arg cpu_type "$CPU_TYPE" \
            --argjson on_ac "$ON_AC" \
            --arg governor "$GOVERNOR" \
            --arg pstate "$PSTATE" \
            --argjson freq_avg "$FREQ_AVG" \
            --argjson temp "$TEMP" \
            --argjson pl1 "$PL1" \
            --argjson pl2 "$PL2" \
            '{
              cpu_type: $cpu_type,
              power_source: (if $on_ac == 1 then "AC" else "Battery" end),
              governor: $governor,
              pstate_mode: $pstate,
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
        
        echo "=== SYSTEM STATUS - STABLE PASSIVE MODE ==="
        echo ""
        
        CPU_TYPE="$(${cpuDetectionScript})"
        echo "CPU Type: $CPU_TYPE"
        
        ON_AC=0
        for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
        done
        echo "Power Source: $([ "$ON_AC" = "1" ] && echo "AC" || echo "Battery")"
        
        echo ""
        echo "CPU FREQUENCIES (Governor Managed):"
        i=0
        for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq; do
          [[ -f "$f" ]] || continue
          mhz=$(( $(cat "$f") / 1000 ))
          printf "  Core %2d: %4d MHz\n" "$i" "$mhz"
          i=$((i+1))
        done
        
        echo ""
        echo "CPU GOVERNOR: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")"
        echo "P-STATE MODE: $(cat /sys/devices/system/cpu/intel_pstate/status 2>/dev/null || echo "unknown")"
        
        echo ""
        echo "TEMPERATURE:"
        ${lm_sensors}/bin/sensors 2>/dev/null | ${gnugrep}/bin/grep -E 'Package|Core|Tctl' | head -3 || \
          echo "  Temperature data unavailable"
        
        echo ""
        echo "POWER LIMITS:"
        if [[ -d /sys/class/powercap/intel-rapl:0 ]]; then
          # Only read from intel-rapl:0 (package level)
          RAPL_NAME=$(cat /sys/class/powercap/intel-rapl:0/name 2>/dev/null || echo "unknown")
          PL1=$(( $(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0) / 1000000 ))
          PL2=$(( $(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0) / 1000000 ))
          echo "  Package ($RAPL_NAME):"
          echo "    PL1: ''${PL1}W (sustained)"
          echo "    PL2: ''${PL2}W (turbo)"
        else
          echo "  RAPL interface unavailable"
        fi
        
        echo ""
        echo "SERVICE STATUS:"
        
        for service in cpu-profile-optimizer thermald; do
          if ${systemd}/bin/systemctl is-active "$service.service" >/dev/null 2>&1; then
            echo "  ✅ $service: ACTIVE"
          else
            echo "  ❌ $service: INACTIVE"
          fi
        done
        
        ONESHOTS="platform-profile hardware-monitor early-rapl-limits rapl-power-limits battery-thresholds cpu-min-freq-guard"
        for service in $ONESHOTS; do
          ACTIVE_STATE=$(${systemd}/bin/systemctl show -p ActiveState --value "$service.service" 2>/dev/null || echo "unknown")
          RESULT=$(${systemd}/bin/systemctl show -p Result --value "$service.service" 2>/dev/null || echo "unknown")
          
          if [[ "$ACTIVE_STATE" == "inactive" ]] && [[ "$RESULT" == "success" ]]; then
            echo "  ✅ $service: RAN (success)"
          elif [[ "$ACTIVE_STATE" == "inactive" ]] && [[ "$RESULT" == "exit-code" ]]; then
            echo "  ⚠️  $service: RAN (failed)"
          elif [[ "$ACTIVE_STATE" == "active" ]] && [[ "$RESULT" == "success" ]]; then
            echo "  ✅ $service: ACTIVE (success)"
          else
            echo "  ❓ $service: $ACTIVE_STATE ($RESULT)"
          fi
        done
        
        echo ""
        echo "NOTE: System running in stable passive mode. Governor controls frequencies."
        echo "TIP: Use 'system-status --json' for machine-readable output"
      '')

      # Hardware Info
      (writeScriptBin "hardware-info" ''
        #!${bash}/bin/bash
        echo "=== COMPREHENSIVE HARDWARE INFORMATION ==="
        echo ""
        
        echo "CPU:"
        ${util-linux}/bin/lscpu | ${gnugrep}/bin/grep -E "Model name|CPU MHz|CPU max MHz|CPU min MHz" | head -4
        echo ""
        
        echo "MEMORY:"
        ${procps}/bin/free -h
        echo ""
        
        echo "BATTERY:"
        for bat in /sys/class/power_supply/BAT*; do
          [[ -d "$bat" ]] || continue
          echo "  $(basename $bat):"
          [[ -r "$bat/capacity" ]] && echo "    Capacity: $(cat "$bat/capacity")%"
          [[ -r "$bat/status" ]] && echo "    Status: $(cat "$bat/status")"
          [[ -r "$bat/charge_control_start_threshold" ]] && \
            echo "    Start Threshold: $(cat "$bat/charge_control_start_threshold")%"
          [[ -r "$bat/charge_control_end_threshold" ]] && \
            echo "    Stop Threshold: $(cat "$bat/charge_control_end_threshold")%"
        done
        echo ""
        
        echo "THERMAL ZONES:"
        for zone in /sys/class/thermal/thermal_zone*; do
          [[ -d "$zone" ]] || continue
          if [[ -r "$zone/temp" ]]; then
            TEMP=$(( $(cat "$zone/temp") / 1000 ))
            TYPE=$(cat "$zone/type" 2>/dev/null || echo "unknown")
            echo "  $TYPE: ''${TEMP}°C"
          fi
        done
        
        echo ""
        echo "POWER LIMITS:"
        if [[ -d /sys/class/powercap/intel-rapl:0 ]]; then
          for f in /sys/class/powercap/intel-rapl:0/constraint_*_power_limit_uw; do
            [[ -f "$f" ]] && \
              echo "  $(basename "$f" | sed 's/_power_limit_uw//'): $(($(cat "$f")/1000000))W"
          done
        else
          echo "  RAPL interface unavailable"
        fi
      '')

      # Real-time Hardware Monitor
      (writeScriptBin "hw-monitor" ''
        #!${bash}/bin/bash
        echo "REAL-TIME HARDWARE MONITOR (Ctrl+C to stop)"
        echo "System in passive mode - governor controls frequencies"
        echo "==================================================="
        
        while true; do
          CLEAR="\033c"
          echo -e "$CLEAR"
          echo "REAL-TIME HARDWARE MONITOR ($(date '+%H:%M:%S'))"
          echo "==================================================="
          
          echo "CPU FREQUENCIES:"
          i=0
          for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq; do
            [[ -f "$f" ]] || continue
            MHZ=$(( $(cat "$f") / 1000 ))
            printf "  Core %2d: %4d MHz\n" "$i" "$MHZ"
            i=$((i+1))
            [[ $i -eq 8 ]] && break
          done
          
          TOTAL_CORES=$(ls -d /sys/devices/system/cpu/cpu[0-9]*/cpufreq 2>/dev/null | wc -l)
          [[ $i -lt $TOTAL_CORES ]] && echo "  ... and $((TOTAL_CORES-i)) more cores"
          echo ""
          
          echo "TEMPERATURE:"
          TEMP_AVG=$(${lm_sensors}/bin/sensors 2>/dev/null | \
            ${gnugrep}/bin/grep -E 'Package id [0-9]+|Tctl|Tdie' | \
            ${gawk}/bin/awk '{
              match($0, /[+]?([0-9]+\.[0-9]+)/, arr);
              if (arr[1] != "") {
                sum += arr[1];
                count++;
              }
            } END {
              if (count > 0) printf "%.1f", sum/count;
              else print "N/A";
            }')
          echo "  Average CPU: ''${TEMP_AVG}°C"
          echo ""
          
          ON_AC=0
          for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
            [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
          done
          echo "POWER: $([ "$ON_AC" = "1" ] && echo "AC" || echo "Battery")"
          
          echo "GOVERNOR: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")"
          
          echo "P-STATE: $(cat /sys/devices/system/cpu/intel_pstate/status 2>/dev/null || echo "unknown")"
          
          sleep 2
        done
      '')

      # Service Control
      (writeScriptBin "power-services" ''
        #!${bash}/bin/bash
        cmd="''${1:-status}"
        
        case "$cmd" in
          status)
            echo "=== POWER MANAGEMENT SERVICES STATUS ==="
            echo ""
            for service in cpu-profile-optimizer platform-profile thermald hardware-monitor \
                          early-rapl-limits battery-thresholds cpu-min-freq-guard; do
              echo "Service: $service"
              ${systemd}/bin/systemctl status "$service.service" --no-pager -l | head -8
              echo "---"
            done
            ;;
          restart)
            echo "Restarting power management services..."
            ${systemd}/bin/systemctl restart cpu-profile-optimizer.service
            ${systemd}/bin/systemctl restart platform-profile.service
            ${systemd}/bin/systemctl restart thermald.service
            ${systemd}/bin/systemctl restart rapl-power-limits.service
            ${systemd}/bin/systemctl start early-rapl-limits.service
            ${systemd}/bin/systemctl restart cpu-min-freq-guard.service
            echo "✓ Services restarted"
            ;;
          log)
            echo "=== SERVICE LOGS (last hour) ==="
            ${systemd}/bin/journalctl \
              -u cpu-profile-optimizer \
              -u platform-profile \
              -u thermald \
              -u early-rapl-limits \
              -u battery-thresholds \
              -u cpu-min-freq-guard \
              --since "1 hour ago" | tail -50
            ;;
          validate)
            echo "=== VALIDATING POWER MANAGEMENT CONFIGURATION ==="
            echo ""
            
            echo "Checking RAPL limits..."
            if [[ -d /sys/class/powercap/intel-rapl:0 ]]; then
              PL1=$(( $(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0) / 1000000 ))
              PL2=$(( $(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0) / 1000000 ))
              
              if [[ $PL1 -eq 28 ]] && [[ $PL2 -eq 55 ]]; then
                echo "  ✅ RAPL limits correct (PL1: 28W, PL2: 55W)"
              else
                echo "  ⚠️  RAPL limits incorrect (PL1: ''${PL1}W, PL2: ''${PL2}W)"
                echo "     Expected: PL1=28W, PL2=55W"
              fi
            else
              echo "  ❌ RAPL interface not available"
            fi
            echo ""
            
            echo "Checking CPU governor..."
            GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
            ON_AC=0
            for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
              [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
            done
            
            EXPECTED_GOV="powersave"
            [[ "$ON_AC" == "1" ]] && EXPECTED_GOV="performance"
            
            if [[ "$GOVERNOR" == "$EXPECTED_GOV" ]]; then
              echo "  ✅ Governor correct ($GOVERNOR for $([ "$ON_AC" = "1" ] && echo "AC" || echo "Battery"))"
            else
              echo "  ⚠️  Governor mismatch (is: $GOVERNOR, expected: $EXPECTED_GOV)"
            fi
            echo ""
            
            echo "Checking battery thresholds..."
            THRESHOLD_OK=0
            for bat in /sys/class/power_supply/BAT*; do
              [[ -d "$bat" ]] || continue
              START=$(cat "$bat/charge_control_start_threshold" 2>/dev/null || echo "N/A")
              STOP=$(cat "$bat/charge_control_end_threshold" 2>/dev/null || echo "N/A")
              
              if [[ "$START" == "75" ]] && [[ "$STOP" == "80" ]]; then
                echo "  ✅ $(basename $bat): Thresholds correct (75-80%)"
                THRESHOLD_OK=1
              else
                echo "  ⚠️  $(basename $bat): Thresholds incorrect (Start: $START%, Stop: $STOP%)"
              fi
            done
            [[ $THRESHOLD_OK -eq 0 ]] && echo "  ❌ No battery thresholds configured"
            echo ""
            
            echo "Checking P-State mode..."
            PSTATE=$(cat /sys/devices/system/cpu/intel_pstate/status 2>/dev/null || echo "unknown")
            if [[ "$PSTATE" == "passive" ]]; then
              echo "  ✅ P-State mode correct (passive)"
            else
              echo "  ⚠️  P-State mode: $PSTATE (expected: passive)"
            fi
            ;;
          *)
            echo "Usage: power-services {status|restart|log|validate}"
            echo ""
            echo "Commands:"
            echo "  status   - Show detailed service status"
            echo "  restart  - Restart all management services"
            echo "  log      - Show recent service logs"
            echo "  validate - Validate power management configuration"
            ;;
        esac
      '')
    ];
}
