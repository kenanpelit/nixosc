# ============================================================================
# modules/core/hardware/default.nix
# ----------------------------------------------------------------------------
# Advanced Hardware & Power Management (ThinkPad-optimized) — v4.6.2
# ----------------------------------------------------------------------------
# - i915 PSR/SAGV/FBC kapalı (çoklu monitör + Wayland akıcılık)
# - AC/Batarya sade profiller + MTL RAPL
# - Min CPU frekansı tabanı: 2000 MHz (her zaman)  ← burayı istersen değiştir
# - Lid kapatınca suspend (docked/AC’deyken de)
# - Boot + her 10 dakikada bir + AC değişiminde + resume sonrası otomatik uygula
# ----------------------------------------------------------------------------

{ config, lib, pkgs, ... }:

let
  systemctl = "${pkgs.systemd}/bin/systemctl";

  # --------- PARAMETRE: Min frekans tabanı (Hz) ---------
  minFloorHz = 2000000;  # 2.0 GHz

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

  meteorLake = {
    battery = { pl1 = 28; pl2 = 42; };
    ac      = { pl1 = 42; pl2 = 60; };
    battery_threshold = { start = 65; stop = 85; };
  };

  cpuApplyScript = pkgs.writeShellScript "cpu-power-limit-apply" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    CPU_TYPE="$(${detectCpuScript})"

    # AC/Batarya tespiti
    ON_AC=0
    for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/AC/online /sys/class/power_supply/AC0/online; do
      [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
    done

    apply_rapl() {
      local PL1_W="$1" PL2_W="$2"
      local RAPL="/sys/class/powercap/intel-rapl:0"
      [[ -d "$RAPL" ]] || return 0
      echo $(( PL1_W * 1000000 )) > "$RAPL/constraint_0_power_limit_uw" 2>/dev/null || true
      echo $(( PL2_W * 1000000 )) > "$RAPL/constraint_1_power_limit_uw" 2>/dev/null || true
    }

    set_policy() {
      local GOV="$1" EPP="$2" MIN_PCT="$3" MAX_PCT="$4"
      # Governor
      for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "$GOV" > "$g" 2>/dev/null || true
      done
      # EPP (tüm policy’lere yaz)
      for p in /sys/devices/system/cpu/cpufreq/policy*; do
        [[ -f "$p/energy_performance_preference" ]] && echo "$EPP" > "$p/energy_performance_preference" 2>/dev/null || true
      done
      # intel_pstate yüzdeleri
      if [[ -w /sys/devices/system/cpu/intel_pstate/min_perf_pct ]]; then
        echo "$MIN_PCT" > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || true
      fi
      if [[ -w /sys/devices/system/cpu/intel_pstate/max_perf_pct ]]; then
        echo "$MAX_PCT" > /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null || true
      fi
      # Turbo / HWP boost açık
      echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
      echo 1 > /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost 2>/dev/null || true
    }

    set_min_floor() {
      # Her policy için min/max frekansları ayarla
      for p in /sys/devices/system/cpu/cpufreq/policy*; do
        [[ -f "$p/cpuinfo_max_freq" ]] || continue
        MAX=$(cat "$p/cpuinfo_max_freq")
        MIN='${builtins.toString minFloorHz}'
        [[ "$MIN" -ge "$MAX" ]] && MIN=$((MAX - 1))
        echo "$MIN" > "$p/scaling_min_freq" 2>/dev/null || true
        echo "$MAX" > "$p/scaling_max_freq" 2>/dev/null || true
      done

      # min_perf_pct'i minFloorHz'e göre hesapla (yaklaşık)
      if [[ -r /sys/devices/system/cpu/cpufreq/policy0/cpuinfo_max_freq ]]; then
        P0MAX=$(cat /sys/devices/system/cpu/cpufreq/policy0/cpuinfo_max_freq)
        PCT=$(( ${builtins.toString minFloorHz} * 100 / P0MAX ))
        (( PCT < 1 )) && PCT=1
        (( PCT > 100 )) && PCT=100
        [[ -w /sys/devices/system/cpu/intel_pstate/min_perf_pct ]] && echo "$PCT" > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || true
      fi
    }

    case "$CPU_TYPE" in
      meteorlake|raptorlake)
        if [[ "$ON_AC" == "1" ]]; then
          apply_rapl ${builtins.toString meteorLake.ac.pl1} ${builtins.toString meteorLake.ac.pl2}
          set_policy performance performance 70 100
        else
          apply_rapl ${builtins.toString meteorLake.battery.pl1} ${builtins.toString meteorLake.battery.pl2}
          set_policy powersave balance_performance 50 85
        fi
        ;;
      *)
        if [[ "$ON_AC" == "1" ]]; then
          set_policy performance performance 70 100
        else
          set_policy powersave balance_power 50 85
        fi
        ;;
    esac

    set_min_floor

    # Kısa dürtme: bazı firmware’lerde HWP’nin “uyanması” için işe yarıyor
    timeout 0.3 dd if=/dev/zero of=/dev/null bs=1M count=50 2>/dev/null || true

    echo "Applied: AC=$ON_AC CPU=$CPU_TYPE; min_freq_floor=${builtins.toString minFloorHz}Hz"
  '';

in
{
  # ------------------------ Donanım ------------------------
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

  # ------------------------ Servisler ------------------------
  services = {
    thermald.enable = true;
    power-profiles-daemon.enable = false;
    tlp.enable = false;
    upower.enable = true;

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
    };
  };

  # -------------------- Boot & Kernel -----------------------
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
      "i915.enable_guc=3"
      "i915.enable_fbc=0"
      "i915.enable_psr=0"
      "i915.enable_sagv=0"
      "nvme_core.default_ps_max_latency_us=5500"
      "mem_sleep_default=deep"  # Sende yoksa kernel yok sayar; diğer makinede aktif
    ];

    kernel.sysctl = {
      "vm.swappiness" = 10;
      "kernel.sched_autogroup_enabled" = 1;
    };
  };

  # -------------- systemd servisleri + timer ---------------
  systemd.services = {
    # İSİM UYUMU: osc-perf-mode 'cpu-power-limit' bekliyor
    cpu-power-limit = {
      description = "Apply CPU power limits, EPP and min frequency floor (>=2.0GHz)";
      wantedBy = lib.mkForce [ ];  # Timer yönetecek
      after = [ "multi-user.target" "systemd-udev-settle.service" "thermald.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = cpuApplyScript;
      };
    };

    # Resume sonrası geri uygula
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

    # deep’i sadece destekleyen makinelerde zorla (sende s2idle tek; diğerinde çalışır)
    mem-sleep-deep = {
      description = "Force mem_sleep=deep when available";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "force-mem-sleep-deep" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          if [[ -w /sys/power/mem_sleep ]] && grep -q 'deep' /sys/power/mem_sleep; then
            echo deep > /sys/power/mem_sleep || true
          fi
        '';
      };
    };
  };

  # Timer: boot’tan 1 sn sonra ve her 10 dk’da bir tekrar uygula
  systemd.timers.cpu-power-limit = {
    description = "Timer: apply CPU power policy periodically";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1s";
      OnUnitActiveSec = "10min";
      Persistent = true;
    };
  };

  # AC tak/çıkar olduğunda hemen uygula
  services.udev.extraRules = lib.mkAfter ''
    SUBSYSTEM=="power_supply", KERNEL=="AC*", ACTION=="change", RUN+="${systemctl} start cpu-power-limit.service"
  '';
}
