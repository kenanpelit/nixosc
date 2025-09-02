# ============================================================================
# modules/core/hardware/default.nix
# ----------------------------------------------------------------------------
# Advanced Hardware & Power Management (ThinkPad-optimized) — v4.5.1
# ----------------------------------------------------------------------------
# Hedef: Performans + Sessizlik, takılmasız görüntü, basit suspend/resume
# - i915 PSR/SAGV/FBC kapalı (çoklu monitör + Wayland akıcılık için)
# - AC/Batarya sade profiller + MTL RAPL
# - Min CPU frekansı tabanı: 1600 MHz (her zaman)
# - Lid kapatınca suspend (docked/AC’deyken de)
# ----------------------------------------------------------------------------

{ config, lib, pkgs, ... }:

let
  systemctl = "${pkgs.systemd}/bin/systemctl";

  # CPU model aile tespiti (sade)
  detectCpuScript = pkgs.writeShellScript "detect-cpu" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    MODEL="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'Model name' | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.coreutils}/bin/tr -s ' ' | ${pkgs.coreutils}/bin/tr -d '\n')"

    echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Core *Ultra|155H|Meteor *Lake' && { echo meteorlake; exit 0; }
    echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE '13th *Gen|Raptor *Lake' && { echo raptorlake; exit 0; }
    echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Ryzen.*7040|Ryzen.*7840|Phoenix' && { echo amdzen4; exit 0; }
    echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Ryzen.*6000|Ryzen.*5000|Rembrandt|Cezanne' && { echo amdzen3; exit 0; }
    echo kabylaker
  '';

  # Meteor Lake için konservatif RAPL limitleri (sessiz fan için)
  meteorLake = {
    battery = { pl1 = 28; pl2 = 42; };
    ac      = { pl1 = 42; pl2 = 60; };
    battery_threshold = { start = 65; stop = 85; };
  };

  # 1600 MHz altına düşmeme hedefi
  minFloorHz = 1600000;

  # Ana uygulama betiği (AC'ye göre governor/EPP ve RAPL, min frekans tabanı)
  cpuApplyScript = pkgs.writeShellScript "cpu-apply" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    CPU_TYPE="$(${detectCpuScript})"

    # AC/Batarya tespiti
    ON_AC=0
    for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/AC/online /sys/class/power_supply/AC0/online; do
      [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
    done

    apply_rapl() {
      local PL1_W="$1" PL2_W="$2"; local RAPL="/sys/class/powercap/intel-rapl:0"
      [[ -d "$RAPL" ]] || return 0
      echo $(( PL1_W * 1000000 )) > "$RAPL/constraint_0_power_limit_uw" 2>/dev/null || true
      echo $(( PL2_W * 1000000 )) > "$RAPL/constraint_1_power_limit_uw" 2>/dev/null || true
    }

    set_policy() {
      local GOV="$1" EPP="$2" MIN_PCT="$3" MAX_PCT="$4"
      for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo "$GOV" > "$g" 2>/dev/null || true; done
      for p in /sys/devices/system/cpu/cpufreq/policy*; do
        [[ -f "$p/energy_performance_preference" ]] && echo "$EPP" > "$p/energy_performance_preference" 2>/dev/null || true
      done
      [[ -w /sys/devices/system/cpu/intel_pstate/min_perf_pct ]] && echo "$MIN_PCT" > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || true
      [[ -w /sys/devices/system/cpu/intel_pstate/max_perf_pct ]] && echo "$MAX_PCT" > /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null || true
      echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
      echo 1 > /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost 2>/dev/null || true
    }

    set_min_floor() {
      for p in /sys/devices/system/cpu/cpufreq/policy*; do
        [[ -f "$p/cpuinfo_max_freq" ]] || continue
        MAX=$(cat "$p/cpuinfo_max_freq")
        MIN=${toString minFloorHz}
        [[ "$MIN" -ge "$MAX" ]] && MIN=$((MAX - 1))
        echo "$MIN" > "$p/scaling_min_freq" 2>/dev/null || true
        echo "$MAX" > "$p/scaling_max_freq" 2>/dev/null || true
      done
      if [[ -r /sys/devices/system/cpu/cpufreq/policy0/cpuinfo_max_freq ]]; then
        P0MAX=$(cat /sys/devices/system/cpu/cpufreq/policy0/cpuinfo_max_freq)
        PCT=$(( ${toString minFloorHz} * 100 / P0MAX ))
        [[ -w /sys/devices/system/cpu/intel_pstate/min_perf_pct ]] && echo "$PCT" > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || true
      fi
    }

    case "$CPU_TYPE" in
      meteorlake|raptorlake)
        if [[ "$ON_AC" == "1" ]]; then
          apply_rapl ${toString meteorLake.ac.pl1} ${toString meteorLake.ac.pl2}
          set_policy performance performance 70 100
        else
          apply_rapl ${toString meteorLake.battery.pl1} ${toString meteorLake.battery.pl2}
          set_policy powersave balance_performance 50 80
        fi
        ;;
      *)
        if [[ "$ON_AC" == "1" ]]; then
          set_policy performance performance 70 100
        else
          set_policy powersave balance_power 50 80
        fi
        ;;
    esac

    set_min_floor
    echo "Applied: AC=$ON_AC CPU=$CPU_TYPE; min_freq_floor=${toString minFloorHz}Hz"
  '';

in
{
  # Donanım (yalın)
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

    bluetooth.enable = true;
  };

  # Servisler
  services = {
    thermald.enable = true;
    power-profiles-daemon.enable = false;
    tlp.enable = false;
    upower.enable = true;

    # LID → suspend (docked ve AC’deyken de), güç tuşu davranışları
    logind.extraConfig = ''
      HandlePowerKey=ignore
      HandlePowerKeyLongPress=poweroff
      HandleSuspendKey=suspend
      HandleHibernateKey=hibernate

      HandleLidSwitch=suspend
      HandleLidSwitchDocked=suspend
      HandleLidSwitchExternalPower=suspend

      IdleAction=ignore
      IdleActionSec=30min
      InhibitDelayMaxSec=5
    '';
  };

  # Boot & Kernel (video akıcılık için güvenli set)
  boot = {
    kernelModules = [ "thinkpad_acpi" "coretemp" "intel_rapl" "i915" ];

    extraModprobeConfig = ''
      options intel_pstate hwp_dynamic_boost=1
      options snd_hda_intel power_save=10 power_save_controller=Y
      options iwlwifi power_save=1 power_level=3
      options usbcore autosuspend=5
      options nvme_core default_ps_max_latency_us=5500
    '';

    kernelParams = [
      "intel_pstate=active"
      "intel_pstate.hwp_dynamic_boost=1"
      "i915.enable_guc=3"      # GuC/HuC açık
      "i915.enable_fbc=0"      # FBC kapalı
      "i915.enable_psr=0"      # PSR kapalı
      "i915.enable_sagv=0"     # SAGV kapalı
      "nvme_core.default_ps_max_latency_us=5500"
      "mem_sleep_default=deep"
    ];

    kernel.sysctl = {
      "vm.swappiness" = 10;
      "kernel.sched_autogroup_enabled" = 1;
    };
  };

  # Basit systemd servisleri: uygulama + suspend toparlama
  systemd.services = {
    cpu-perf-apply = {
      description = "Apply CPU power & frequency floor (>=1.6GHz)";
      after = [ "multi-user.target" "systemd-udev-settle.service" "thermald.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = cpuApplyScript;
      };
    };

    system-resume-post = {
      description = "Restore CPU policy after resume";
      wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
      after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
      unitConfig = { DefaultDependencies = false; };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = cpuApplyScript;
      };
    };
  };

  # AC tak/çıkar olduğunda politikayı yeniden uygula
  services.udev.extraRules = lib.mkAfter ''
    SUBSYSTEM=="power_supply", KERNEL=="AC*", ACTION=="change", RUN+="${systemctl} start cpu-perf-apply.service"
  '';
}


