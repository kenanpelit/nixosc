# modules/core/hardware/default.nix
# ==============================================================================
# Advanced Hardware & Power Management (ThinkPad-optimized)
# ==============================================================================
# Scope:
# - Robust CPU detection + per-platform power/thermal profiles
# - Intel RAPL power limits (PL1/PL2) with safe verification
# - Governor/EPP + *minimum performance floor* (AC/Battery aware)
# - HWP Dynamic Boost enabled (snappier boosts on Intel)
# - Smart fan control (thinkfan), thermald, sleep hooks
# - Battery charge thresholds, journal, dbus-broker, udev triggers
# - Enhanced suspend/resume recovery for Meteor Lake (fixes stuck 400MHz issue)
#
# Supported (tested profiles):
# - ThinkPad E14 Gen 6 (Intel Core Ultra 7 155H, a.k.a. Meteor Lake)
# - ThinkPad X1 Carbon 6th (Intel i7-8650U, Kaby Lake-R)
#
# Known Issues Fixed:
# - CPU stuck at 400MHz after suspend (Meteor Lake)
# - EPP showing "default" instead of proper performance mode
# - Power limits not properly restored after resume
#
# Version: 5.0.0
# Author:  Kenan Pelit
# Date:    2025-09-01
# ==============================================================================

{ config, lib, pkgs, ... }:

let
  # ----------------------------------------------------------------------------
  # CPU DETECTION (safe & extended)
  # Returns: "meteorlake" | "raptorlake" | "kabylaker" | "amdzen4" | "amdzen3"
  # ----------------------------------------------------------------------------
  detectCpuScript = pkgs.writeShellScript "detect-cpu" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    MODEL="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'Model name' | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.coreutils}/bin/tr -s ' ' | ${pkgs.coreutils}/bin/tr -d '\n')"

    # Intel families
    if echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Core *Ultra|155H|Meteor *Lake'; then
      echo "meteorlake"
    elif echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE '13th *Gen|Raptor *Lake|1370P|1360P|1355U'; then
      echo "raptorlake"
    elif echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE '8650U|8550U|8350U|8250U|Kaby *Lake'; then
      echo "kabylaker"
    # AMD families
    elif echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Ryzen.*7040|Ryzen.*7840|Phoenix'; then
      echo "amdzen4"
    elif echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Ryzen.*6000|Ryzen.*5000|Rembrandt|Cezanne'; then
      echo "amdzen3"
    else
      echo "kabylaker"  # safe fallback
    fi
  '';

  # ----------------------------------------------------------------------------
  # CPU PROFILES (Watts for PL1/PL2 + thermal + battery thresholds)
  # Enhanced for better performance and recovery
  # ----------------------------------------------------------------------------
  meteorLake = {
    battery = { pl1 = 28; pl2 = 42; };  # balanced on battery
    ac      = { pl1 = 42; pl2 = 64; };  # more aggressive on AC (increased PL2)
    thermal = { trip = 82; tripAc = 88; warning = 92; critical = 100; };
    battery_threshold = { start = 65; stop = 85; };
  };

  kabyLakeR = {
    battery = { pl1 = 15; pl2 = 25; };
    ac      = { pl1 = 25; pl2 = 35; };
    thermal = { trip = 78; tripAc = 82; warning = 85; critical = 95; };
    battery_threshold = { start = 75; stop = 80; };
  };

  systemctl = "${pkgs.systemd}/bin/systemctl";
in
{
  # =============================================================================
  # HARDWARE
  # =============================================================================
  hardware = {
    trackpoint = { enable = true; speed = 200; sensitivity = 200; emulateWheel = true; };

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
      extraPackages32 = with pkgs.pkgsi686Linux; [ intel-media-driver ];
    };

    enableRedistributableFirmware = true;
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = true;

    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General = {
        FastConnectable = false;
        ReconnectAttempts = 7;
        ReconnectIntervals = "1,2,4,8,16,32,64";
      };
    };
  };

  # =============================================================================
  # SERVICES (Power & Thermal)
  # =============================================================================
  services = {
    # ---------- Thermal orchestration ----------
    thermald.enable = true;

    # Avoid policy conflicts with our manual/tuned approach:
    power-profiles-daemon.enable = false;
    tlp.enable = false;

    # ---------- Thinkfan: quiet fan curve with hysteresis ----------
    thinkfan = {
      enable = true;
      smartSupport = true;  # use NVMe/SATA sensors too
      # [level  min_temp  max_temp]  (min=max *down* threshold; max=*up* threshold)
      levels = [
        [0  0   54]
        [1  50  61]
        [2  57  67]
        [3  63  73]
        [4  69  79]
        [5  75  85]
        [6  81  90]
        [7  86  32767]
      ];
    };

    # ---------- UPower battery policy ----------
    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";
      percentageLow = 20;
      percentageCritical = 5;
      percentageAction = 3;
      usePercentageForPolicy = true;
    };

    # ---------- Logind behavior ----------
    logind.settings.Login = {
      HandlePowerKey = "ignore";
      HandlePowerKeyLongPress = "poweroff";
      HandleSuspendKey = "suspend";
      HandleHibernateKey = "hibernate";
      HandleLidSwitch = "suspend";
      HandleLidSwitchDocked = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      IdleAction = "ignore";
      IdleActionSec = "30min";
      InhibitDelayMaxSec = "5";
      InhibitorsMax = "8192";
      UserTasksMax = "33%";
      RuntimeDirectorySize = "50%";
      RemoveIPC = "yes";
    };

    # ---------- Journald (SSD-friendly) ----------
    journald.extraConfig = ''
      SystemMaxUse=2G
      SystemMaxFileSize=100M
      MaxRetentionSec=1week
      MaxFileSec=1day
      SyncIntervalSec=300
      RateLimitIntervalSec=30
      RateLimitBurst=1000
      Compress=yes
      ForwardToSyslog=no
    '';

    # ---------- D-Bus broker ----------
    dbus = {
      implementation = "broker";
      packages = [ pkgs.dconf ];
    };
  };

  # =============================================================================
  # BOOT & KERNEL
  # =============================================================================
  boot = {
    kernelModules = [ "thinkpad_acpi" "coretemp" "intel_rapl" "msr" "kvm-intel" "i915" ];

    extraModprobeConfig = ''
      # ThinkPad ACPI: userland fan control
      options thinkpad_acpi fan_control=1 brightness_mode=1 volume_mode=1 experimental=1

      # Intel pstate: enable HWP Dynamic Boost for faster ramp-ups
      options intel_pstate hwp_dynamic_boost=1

      # Audio power save
      options snd_hda_intel power_save=10 power_save_controller=Y

      # Wi-Fi power save defaults (tweak as you like)
      options iwlwifi power_save=1 power_level=3
      options iwlmvm power_scheme=3

      # USB autosuspend after 5s
      options usbcore autosuspend=5

      # NVMe APST
      options nvme_core default_ps_max_latency_us=5500
    '';

    kernelParams = [
      # IOMMU
      "intel_iommu=on" "iommu=pt"

      # Intel pstate - use active mode for better control
      "intel_pstate=active"
      "intel_pstate.hwp_dynamic_boost=1"
      
      # C-state control for better resume behavior
      "intel_idle.max_cstate=9"
      "processor.max_cstate=9"

      # NVMe tuning
      "nvme_core.default_ps_max_latency_us=5500"
      "nvme_core.io_timeout=30"

      # i915 tuning (modern Intel iGPU)
      "i915.enable_guc=3"
      "i915.enable_fbc=1"
      "i915.enable_psr=1"
      "i915.fastboot=1"
      "i915.enable_sagv=1"

      # PCIe ASPM
      "pcie_aspm=default"

      # Wi-Fi debug off
      "iwlwifi.debug=0x0"

      # Prefer deep sleep (if platform supports)
      "mem_sleep_default=deep"
      
      # ACPI improvements for better suspend/resume
      "acpi_osi=Linux"
      "acpi_enforce_resources=lax"
    ];

    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_writeback_centisecs" = 1500;
      "vm.dirty_background_ratio" = 5;
      "vm.dirty_ratio" = 10;
      "vm.laptop_mode" = 5;
      "vm.page-cluster" = 0;
      "vm.compact_unevictable_allowed" = 1;

      "kernel.nmi_watchdog" = 0;
      "kernel.sched_autogroup_enabled" = 1;
      "kernel.sched_cfs_bandwidth_slice_us" = 3000;
    };
  };

  # =============================================================================
  # systemd SERVICES — RAPL + Governor/EPP + Battery + LEDs + Sleep hooks
  # =============================================================================
  systemd.services = {
    # --------------------------------------------------------------------------
    # CPU POWER LIMITS + GOVERNOR/EPP + MIN PERF FLOOR
    # Enhanced with better EPP handling and Meteor Lake fixes
    # --------------------------------------------------------------------------
    cpu-power-limit = {
      description = "Apply per-CPU power limits and performance floors (AC/Battery aware)";
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "cpu-power-limit" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail

          CPU_TYPE="$(${detectCpuScript})"

          # AC (1) / Battery (0)
          ON_AC=0
          for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/AC/online /sys/class/power_supply/AC0/online; do
            [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
          done

          # --- Helpers ---------------------------------------------------------
          apply_limits () {
            # Intel RAPL only (skip silently if unavailable)
            local PL1_W="$1" PL2_W="$2" TW1_US="$3" TW2_US="$4"
            local RAPL="/sys/class/powercap/intel-rapl:0"
            [[ -d "$RAPL" ]] || { echo "RAPL not available; skipping limits"; return 0; }

            echo $(( PL1_W * 1000000 )) > "$RAPL/constraint_0_power_limit_uw" || true
            echo $(( PL2_W * 1000000 )) > "$RAPL/constraint_1_power_limit_uw" || true
            echo "$TW1_US" > "$RAPL/constraint_0_time_window_us" || true
            echo "$TW2_US" > "$RAPL/constraint_1_time_window_us" || true

            # Verify safely
            if [[ -r "$RAPL/constraint_0_power_limit_uw" && -r "$RAPL/constraint_1_power_limit_uw" ]]; then
              ACTUAL_PL1=$(cat "$RAPL/constraint_0_power_limit_uw")
              ACTUAL_PL2=$(cat "$RAPL/constraint_1_power_limit_uw")
              printf 'RAPL set: PL1=%sW PL2=%sW (AC=%s)\n' "$((ACTUAL_PL1/1000000))" "$((ACTUAL_PL2/1000000))" "$ON_AC"
            fi
          }

          set_governor_epp () {
            # Enhanced EPP handling to prevent "default" state
            # Usage: set_governor_epp <GOV> <EPP> <MIN_PCT>
            local GOV="$1" EPP="$2" MIN_PCT="$3"
            
            # First, ensure pstate driver is active
            echo "active" > /sys/devices/system/cpu/intel_pstate/status 2>/dev/null || true
            
            # Enable HWP dynamic boost
            echo 1 > /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost 2>/dev/null || true

            # Scale governors
            for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
              echo "$GOV" > "$g" 2>/dev/null || true
            done

            # EPP with reset mechanism to avoid "default" state
            for p in /sys/devices/system/cpu/cpufreq/policy*; do
              # Reset EPP by cycling through states
              echo "balance_performance" > "$p/energy_performance_preference" 2>/dev/null || true
              sleep 0.05
              echo "$EPP" > "$p/energy_performance_preference" 2>/dev/null || true
              
              # Verify EPP was set
              ACTUAL_EPP=$(cat "$p/energy_performance_preference" 2>/dev/null || echo "unknown")
              if [[ "$ACTUAL_EPP" == "default" ]]; then
                # Force reset if still default
                echo "balance_power" > "$p/energy_performance_preference" 2>/dev/null || true
                sleep 0.1
                echo "$EPP" > "$p/energy_performance_preference" 2>/dev/null || true
              fi
            done

            # Set min/max frequencies
            for p in /sys/devices/system/cpu/cpufreq/policy*; do
              if [[ -f "$p/cpuinfo_max_freq" ]] && [[ "$MIN_PCT" =~ ^[0-9]+$ ]]; then
                MAX=$(cat "$p/cpuinfo_max_freq")
                MIN=$(( MAX * MIN_PCT / 100 ))
                echo "$MIN" > "$p/scaling_min_freq" 2>/dev/null || true
                echo "$MAX" > "$p/scaling_max_freq" 2>/dev/null || true
              fi
            done

            # Global min performance percent (Intel & AMD pstate)
            if [[ -w /sys/devices/system/cpu/intel_pstate/min_perf_pct ]]; then
              echo "$MIN_PCT" > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || true
            elif [[ -w /sys/devices/system/cpu/amd_pstate/min_perf_pct ]]; then
              echo "$MIN_PCT" > /sys/devices/system/cpu/amd_pstate/min_perf_pct 2>/dev/null || true
            fi

            # Ensure turbo is enabled
            echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
            
            echo "Governor/EPP applied: $GOV/$EPP with min_perf=$MIN_PCT%"
          }

          # --- Policy application ----------------------------------------------
          case "$CPU_TYPE" in
            meteorlake)
              if [[ "$ON_AC" == "1" ]]; then
                # AC: Maximum performance with aggressive limits
                apply_limits ${toString meteorLake.ac.pl1} ${toString meteorLake.ac.pl2} 28000000 10000
                
                # Special handling for Meteor Lake EPP issues
                for i in {0..15}; do  # Up to 16 cores/threads
                  policy="/sys/devices/system/cpu/cpufreq/policy$i"
                  if [[ -d "$policy" ]]; then
                    # Force clear default state
                    echo "balance_performance" > "$policy/energy_performance_preference" 2>/dev/null || true
                    sleep 0.02
                    echo "performance" > "$policy/energy_performance_preference" 2>/dev/null || true
                  fi
                done
                
                # Set governor to performance
                for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                  echo "performance" > "$g" 2>/dev/null || true
                done
                
                # High minimum performance floor
                echo 85 > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || true
                
              else
                # Battery: Balanced with reasonable performance
                apply_limits ${toString meteorLake.battery.pl1} ${toString meteorLake.battery.pl2} 28000000 10000
                set_governor_epp powersave balance_performance 45
              fi
              ;;
              
            raptorlake)
              if [[ "$ON_AC" == "1" ]]; then
                apply_limits 35 55 28000000 10000
                set_governor_epp performance performance 75
              else
                apply_limits 20 35 28000000 10000
                set_governor_epp powersave balance_performance 40
              fi
              ;;
              
            kabylaker)
              if [[ "$ON_AC" == "1" ]]; then
                apply_limits ${toString kabyLakeR.ac.pl1} ${toString kabyLakeR.ac.pl2} 28000000 10000
                set_governor_epp performance balance_performance 65
              else
                apply_limits ${toString kabyLakeR.battery.pl1} ${toString kabyLakeR.battery.pl2} 28000000 10000
                set_governor_epp powersave balance_power 35
              fi
              ;;
              
            amdzen4|amdzen3)
              # No Intel RAPL; just governor/EPP floors
              if [[ "$ON_AC" == "1" ]]; then
                set_governor_epp performance performance 70
              else
                set_governor_epp powersave balance_power 40
              fi
              ;;
              
            *)
              # Fallback
              if [[ "$ON_AC" == "1" ]]; then
                apply_limits 25 35 28000000 10000
                set_governor_epp performance balance_performance 60
              else
                apply_limits 15 25 28000000 10000
                set_governor_epp powersave balance_power 35
              fi
              ;;
          esac

          # Final verification for Meteor Lake
          if [[ "$CPU_TYPE" == "meteorlake" ]] && [[ "$ON_AC" == "1" ]]; then
            sleep 0.5
            # Double-check EPP isn't stuck at default
            for p in /sys/devices/system/cpu/cpufreq/policy*; do
              EPP_CHECK=$(cat "$p/energy_performance_preference" 2>/dev/null || echo "unknown")
              if [[ "$EPP_CHECK" == "default" ]]; then
                echo "WARNING: EPP stuck at default for $p, forcing reset..."
                echo "balance_power" > "$p/energy_performance_preference" 2>/dev/null || true
                sleep 0.1
                echo "performance" > "$p/energy_performance_preference" 2>/dev/null || true
              fi
            done
          fi

          echo "CPU power configuration completed (AC=$ON_AC, CPU=$CPU_TYPE)"
        '';
      };
    };

    # --------------------------------------------------------------------------
    # LED states (ThinkPad)
    # --------------------------------------------------------------------------
    fix-led-state = {
      description = "Configure ThinkPad LED states";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "fix-leds" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail

          if [[ -d /sys/class/leds/platform::micmute ]]; then
            echo "audio-micmute" > /sys/class/leds/platform::micmute/trigger 2>/dev/null || true
            echo 0 > /sys/class/leds/platform::micmute/brightness 2>/dev/null || true
          fi
          if [[ -d /sys/class/leds/platform::mute ]]; then
            echo "audio-mute" > /sys/class/leds/platform::mute/trigger 2>/dev/null || true
            echo 0 > /sys/class/leds/platform::mute/brightness 2>/dev/null || true
          fi
          if [[ -d /sys/class/leds/tpacpi::lid_logo_dot ]]; then
            echo 0 > /sys/class/leds/tpacpi::lid_logo_dot/brightness 2>/dev/null || true
          fi
        '';
      };
    };

    # --------------------------------------------------------------------------
    # Battery charge thresholds
    # --------------------------------------------------------------------------
    battery-charge-threshold = {
      description = "Configure battery charge thresholds (BAT0)";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "battery-threshold" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          BAT="/sys/class/power_supply/BAT0"
          [[ -d "$BAT" ]] || { echo "Battery not found"; exit 0; }

          CPU_TYPE="$(${detectCpuScript})"
          if [[ "$CPU_TYPE" == "meteorlake" || "$CPU_TYPE" == "raptorlake" ]]; then
            START=${toString meteorLake.battery_threshold.start}
            STOP=${toString meteorLake.battery_threshold.stop}
          else
            START=${toString kabyLakeR.battery_threshold.start}
            STOP=${toString kabyLakeR.battery_threshold.stop}
          fi

          CUR_START="$(cat "$BAT/charge_control_start_threshold" 2>/dev/null || echo 0)"
          CUR_STOP="$(cat "$BAT/charge_control_end_threshold" 2>/dev/null || echo 100)"

          [[ "$CUR_START" = "$START" ]] || { echo "$START" > "$BAT/charge_control_start_threshold" || true; }
          [[ "$CUR_STOP"  = "$STOP"  ]] || { echo "$STOP"  > "$BAT/charge_control_end_threshold"  || true; }

          echo "Battery thresholds → Start=$START% Stop=$STOP%"
        '';
      };
    };

    # --------------------------------------------------------------------------
    # Sleep hooks — Enhanced for Meteor Lake
    # --------------------------------------------------------------------------
    thinkfan-sleep-pre = {
      description = "Prepare system before suspend/hibernate";
      wantedBy = [ "sleep.target" ];
      before   = [ "sleep.target" ];
      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "thinkfan-sleep-pre" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail

          # Stop thinkfan service
          ${pkgs.systemd}/bin/systemctl stop thinkfan.service 2>/dev/null || true
          
          # Set fan to auto mode
          if [[ -w /proc/acpi/ibm/fan ]]; then
            echo "level auto" > /proc/acpi/ibm/fan 2>/dev/null || true
          fi
          
          # Save current EPP state for comparison after resume
          for p in /sys/devices/system/cpu/cpufreq/policy*; do
            if [[ -r "$p/energy_performance_preference" ]]; then
              cat "$p/energy_performance_preference" > "/tmp/epp_$(basename $p)_pre_suspend" 2>/dev/null || true
            fi
          done
          
          echo "System prepared for suspend"
        '';
      };
    };

    thinkfan-sleep-post = {
      description = "Restore system after resume (enhanced recovery)";
      wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
      after    = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "thinkfan-sleep-post" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          
          echo "Starting system restore after resume..."
          
          # Reload MSR module for CPU control
          ${pkgs.kmod}/bin/modprobe -r msr 2>/dev/null || true
          sleep 0.2
          ${pkgs.kmod}/bin/modprobe msr 2>/dev/null || true
          
          # Ensure Intel pstate is active
          echo "active" > /sys/devices/system/cpu/intel_pstate/status 2>/dev/null || true
          
          # Re-enable HWP dynamic boost
          echo 1 > /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost 2>/dev/null || true
          
          # Re-enable turbo
          echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
          
          # Wait for sysfs to stabilize
          sleep 1
          
          # Force EPP reset if stuck at default (Meteor Lake specific)
          CPU_TYPE="$(${detectCpuScript})"
          if [[ "$CPU_TYPE" == "meteorlake" ]]; then
            echo "Applying Meteor Lake specific EPP recovery..."
            
            # Check AC status
            ON_AC=0
            for PS in /sys/class/power_supply/AC*/online; do
              [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
            done
            
            if [[ "$ON_AC" == "1" ]]; then
              # Force performance mode on all policies
              for p in /sys/devices/system/cpu/cpufreq/policy*; do
                if [[ -d "$p" ]]; then
                  # Triple-reset to ensure EPP takes effect
                  echo "balance_power" > "$p/energy_performance_preference" 2>/dev/null || true
                  sleep 0.05
                  echo "balance_performance" > "$p/energy_performance_preference" 2>/dev/null || true
                  sleep 0.05
                  echo "performance" > "$p/energy_performance_preference" 2>/dev/null || true
                fi
              done
              
              # Force performance governor
              for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                echo "performance" > "$g" 2>/dev/null || true
              done
              
              # Set high minimum performance
              echo 85 > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || true
            fi
          fi
          
          # Restart CPU power limit service (applies full configuration)
          ${pkgs.systemd}/bin/systemctl restart cpu-power-limit.service || true
          
          # Wait for power service to complete
          sleep 2
          
          # Verify EPP recovery
          RECOVERY_NEEDED=0
          for p in /sys/devices/system/cpu/cpufreq/policy*; do
            if [[ -r "$p/energy_performance_preference" ]]; then
              EPP=$(cat "$p/energy_performance_preference")
              if [[ "$EPP" == "default" ]]; then
                echo "WARNING: $p still at default EPP, forcing recovery..."
                RECOVERY_NEEDED=1
              fi
            fi
          done
          
          if [[ "$RECOVERY_NEEDED" == "1" ]]; then
            # Emergency recovery
            ${pkgs.systemd}/bin/systemctl restart cpu-power-limit.service || true
          fi
          
          # Restart thinkfan
          if ${pkgs.systemd}/bin/systemctl is-enabled thinkfan.service >/dev/null 2>&1; then
            ${pkgs.systemd}/bin/systemctl restart thinkfan.service || true
          fi
          
          echo "System restore completed after resume"
        '';
      };
    };
  };

  # =============================================================================
  # systemd TIMERS — periodic enforcement
  # =============================================================================
  systemd.timers.cpu-power-limit = {
    description = "Timer for CPU power limit application";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";       # Initial delay after boot
      OnUnitActiveSec = "10min";  # Reapply every 10 minutes (more frequent)
      Persistent = true;
    };
  };

  # =============================================================================
  # UDEV RULES — AC change triggers and hardware events
  # =============================================================================
  services.udev.extraRules = lib.mkAfter ''
    # LED permissions
    SUBSYSTEM=="leds", KERNEL=="platform::micmute", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 664 /sys/class/leds/%k/brightness"
    SUBSYSTEM=="leds", KERNEL=="platform::mute",    ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 664 /sys/class/leds/%k/brightness"

    # USB autosuspend defaults; keep HID awake
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usbhid", ATTR{power/control}="on"

    # AC adapter online/offline → immediately reapply power limits
    SUBSYSTEM=="power_supply", KERNEL=="AC*", ACTION=="change", RUN+="${systemctl} restart cpu-power-limit.service"
    
    # Lid events → ensure proper power state
    SUBSYSTEM=="button", KERNEL=="lid", ACTION=="open", RUN+="${systemctl} restart cpu-power-limit.service"
  '';

  # =============================================================================
  # ENV & TOOLS (Enhanced with recovery scripts)
  # =============================================================================
  environment = {
    systemPackages = with pkgs; [
      lm_sensors
      powertop
      intel-gpu-tools
      bc
      
      # Emergency CPU fix script for manual intervention
      (pkgs.writeScriptBin "fix-cpu-stuck" ''
        #!${pkgs.bash}/bin/bash
        echo "🔧 Fixing stuck CPU frequencies..."
        
        # Detect CPU type
        CPU_TYPE="$(${detectCpuScript})"
        echo "CPU Type: $CPU_TYPE"
        
        # Reload MSR module
        echo "Reloading MSR module..."
        sudo ${pkgs.kmod}/bin/modprobe -r msr 2>/dev/null || true
        sudo ${pkgs.kmod}/bin/modprobe msr 2>/dev/null || true
        
        # Force Intel pstate active
        echo "Activating Intel pstate..."
        sudo bash -c "echo active > /sys/devices/system/cpu/intel_pstate/status" 2>/dev/null || true
        
        # Enable HWP and turbo
        sudo bash -c "echo 1 > /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost" 2>/dev/null || true
        sudo bash -c "echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo" 2>/dev/null || true
        
        # Check AC status
        ON_AC=0
        for PS in /sys/class/power_supply/AC*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
        done
        echo "Power source: $([ "$ON_AC" = "1" ] && echo "AC" || echo "Battery")"
        
        # Force EPP reset for all policies
        echo "Resetting EPP for all CPU policies..."
        for p in /sys/devices/system/cpu/cpufreq/policy*; do
          if [[ -d "$p" ]]; then
            # Cycle through states to force reset
            sudo bash -c "echo balance_power > $p/energy_performance_preference" 2>/dev/null || true
            sleep 0.05
            sudo bash -c "echo balance_performance > $p/energy_performance_preference" 2>/dev/null || true
            sleep 0.05
            
            if [[ "$ON_AC" == "1" ]]; then
              sudo bash -c "echo performance > $p/energy_performance_preference" 2>/dev/null || true
            else
              sudo bash -c "echo balance_performance > $p/energy_performance_preference" 2>/dev/null || true
            fi
          fi
        done
        
        # Set governor
        echo "Setting CPU governor..."
        if [[ "$ON_AC" == "1" ]]; then
          for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            sudo bash -c "echo performance > $g" 2>/dev/null || true
          done
          sudo bash -c "echo 85 > /sys/devices/system/cpu/intel_pstate/min_perf_pct" 2>/dev/null || true
        else
          for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            sudo bash -c "echo powersave > $g" 2>/dev/null || true
          done
          sudo bash -c "echo 45 > /sys/devices/system/cpu/intel_pstate/min_perf_pct" 2>/dev/null || true
        fi
        
        # Restart power service
        echo "Restarting power management service..."
        sudo systemctl restart cpu-power-limit.service
        
        # Wait and verify
        sleep 2
        
        echo ""
        echo "✅ Recovery complete! Current status:"
        echo "=================================="
        
        # Show current frequencies
        echo "CPU Frequencies:"
        grep "cpu MHz" /proc/cpuinfo | head -4 | awk '{print "  Core " NR-1 ": " $4 " MHz"}'
        
        # Show EPP status
        echo ""
        echo "EPP Status:"
        for p in /sys/devices/system/cpu/cpufreq/policy*; do
          if [[ -r "$p/energy_performance_preference" ]]; then
            EPP=$(cat "$p/energy_performance_preference")
            echo "  $(basename $p): $EPP"
          fi
        done | head -4
        
        # Show governor
        echo ""
        echo "Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'N/A')"
        echo "Min Performance: $(cat /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || echo 'N/A')%"
        
        echo ""
        echo "💡 If frequencies are still stuck at 400MHz, try:"
        echo "   1. Run this command again"
        echo "   2. Manually set: sudo cpupower frequency-set -g performance"
        echo "   3. Reboot if the issue persists"
      '')
      
      # Performance mode script
      (pkgs.writeScriptBin "performance-mode" ''
        #!${pkgs.bash}/bin/bash
        echo "🚀 Forcing maximum performance mode..."
        
        # Set all cores to performance
        for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
          sudo bash -c "echo performance > $g" 2>/dev/null || true
        done
        
        # Set EPP to performance
        for p in /sys/devices/system/cpu/cpufreq/policy*; do
          sudo bash -c "echo performance > $p/energy_performance_preference" 2>/dev/null || true
        done
        
        # Maximum performance floor
        sudo bash -c "echo 100 > /sys/devices/system/cpu/intel_pstate/min_perf_pct" 2>/dev/null || true
        
        # Enable turbo
        sudo bash -c "echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo" 2>/dev/null || true
        
        echo "✅ Performance mode activated!"
      '')
    ];

    shellAliases = {
      # Battery management
      battery-status = "upower -i /org/freedesktop/UPower/devices/battery_BAT0";
      battery-info = ''
        echo "=== Battery Status ===" && \
        upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "state|percentage|time to|capacity" && \
        echo -e "\n=== Charge Thresholds ===" && \
        echo "Start: $(cat /sys/class/power_supply/BAT0/charge_control_start_threshold 2>/dev/null || echo 'N/A')%" && \
        echo "Stop:  $(cat /sys/class/power_supply/BAT0/charge_control_end_threshold   2>/dev/null || echo 'N/A')%"
      '';

      # Power management
      power-report = "sudo powertop --html=power-report-$(date +%Y%m%d-%H%M).html --time=10 && echo 'Power report saved'";
      power-usage  = "sudo powertop";
      fix-power    = "sudo systemctl restart cpu-power-limit && echo 'Power limits reapplied'";
      
      # CPU stuck fix (quick access)
      fix-cpu = "fix-cpu-stuck";
      perf-mode = "performance-mode";

      # Thermal monitoring
      thermal-status = ''
        echo "=== Thermal Status ===" && sensors 2>/dev/null || echo "lm-sensors not available"; echo; \
        echo "=== ACPI Thermal ===" && cat /proc/acpi/ibm/thermal 2>/dev/null || echo "ThinkPad ACPI thermal not available"; echo; \
        echo "=== Thermal Zones ==="; \
        for z in /sys/class/thermal/thermal_zone*/temp; do \
          [[ -r "$z" ]] || continue; t=$(cat "$z"); \
          printf "%s: %s°C\n" "$(basename "$(dirname "$z")")" "$((t/1000))"; \
        done
      '';

      # CPU frequency and power state
      cpu-freq = ''
        echo "=== CPU Frequency ==="; \
        grep "cpu MHz" /proc/cpuinfo | awk '{print "Core " NR-1 ": " $4 " MHz"}'; echo; \
        echo "=== Governor ==="; \
        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true; echo; \
        echo "=== EPP (Energy Performance Preference) ==="; \
        for p in /sys/devices/system/cpu/cpufreq/policy*; do \
          if [[ -r "$p/energy_performance_preference" ]]; then \
            EPP=$(cat "$p/energy_performance_preference"); \
            echo "$(basename $p): $EPP"; \
          fi; \
        done | head -4; echo; \
        echo "=== Min Performance % ==="; \
        cat /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || echo "N/A"
      '';

      cpu-type = "${detectCpuScript}";

      # Complete performance summary
      perf-summary = ''
        echo "=== System Performance Summary ==="; \
        echo "CPU: $(${detectCpuScript})"; \
        echo "Power: $([ "$(cat /sys/class/power_supply/AC*/online 2>/dev/null | head -1)" = "1" ] && echo "AC" || echo "Battery")"; \
        echo "Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"; \
        echo "EPP: $(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null || echo 'N/A')"; \
        echo "Min Perf: $(cat /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || echo 'N/A')%"; \
        echo "Turbo: $([ "$(cat /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null)" = "0" ] && echo "Enabled" || echo "Disabled")"; \
        echo "Memory: $(free -h | awk "/^Mem:/ {print \$3 \" / \" \$2}")"; \
        echo "Load: $(uptime | awk -F'load average:' '{print $2}')"; \
        echo; \
        echo "=== Power Limits (RAPL) ==="; \
        PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0); \
        PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0); \
        echo "PL1: $((PL1/1000000))W"; \
        echo "PL2: $((PL2/1000000))W"; \
        echo; \
        echo "=== Current CPU Frequencies ==="; \
        grep "cpu MHz" /proc/cpuinfo | head -4 | awk '{print "Core " NR-1 ": " $4 " MHz"}'
      '';
      
      # Quick status check
      cpu-status = "perf-summary";
      
      # Suspend/resume test
      test-suspend = ''
        echo "Testing suspend/resume cycle..."; \
        echo "Current EPP before suspend:"; \
        cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null; \
        echo "Suspending in 5 seconds... (Ctrl+C to cancel)"; \
        sleep 5 && sudo systemctl suspend
      '';
    };

    variables = {
      VDPAU_DRIVER = "va_gl";
      LIBVA_DRIVER_NAME = "iHD";
    };
  };

  # =============================================================================
  # ZRAM — fast compressed swap
  # =============================================================================
  zramSwap = {
    enable = true;
    priority = 5000;
    algorithm = "zstd";
    memoryPercent = lib.mkDefault 30;
  };
}

