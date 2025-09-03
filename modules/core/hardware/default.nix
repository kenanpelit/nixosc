# ============================================================================
# modules/core/hardware/default.nix
# ----------------------------------------------------------------------------
# Advanced Hardware & Power Management (ThinkPad‑optimized) — v7.0 STABLE
# ----------------------------------------------------------------------------
# • Tek otorite: auto-cpufreq (frekans tavan/tabanları burada)
# • EPP & HWP ayarları: sağlam uygulama (governor kilidinde EPP için fallback)
# • Meteor Lake (Core Ultra 7 155H) & Kaby Lake odaklı; çakışma yok
# • AC/Batarya otomatik profil geçişi, AC’de güçlü taban (saplanma yok)
# • i915 PSR/SAGV/FBC kapalı (Wayland + çoklu monitör akıcılık)
# • ThinkPad fan & batarya eşikleri
# ----------------------------------------------------------------------------

{ config, lib, pkgs, ... }:

{
  # ======================== CPU FREKANS YÖNETİMİ ========================
  # Tek yönetici: auto-cpufreq
  services.tlp.enable = false;
  services.power-profiles-daemon.enable = false;

  services.auto-cpufreq = {
    enable = true;
    settings = {
      # ---------------------------- AC MODU ----------------------------
      charger = {
        governor = "performance";
        turbo = "auto";
        scaling_min_freq = 1600000;   # 1.6 GHz taban (AC)
        scaling_max_freq = 4800000;   # 4.8 GHz tavan
        energy_performance_preference = "performance";  # EPP → güçlü
      };

      # -------------------------- BATARYA MODU ------------------------
      battery = {
        governor = "powersave";
        turbo = "auto";
        scaling_min_freq = 800000;    # 0.8 GHz taban (Batarya)
        scaling_max_freq = 3500000;   # 3.5 GHz tavan (Batarya)
        energy_performance_preference = "balance_power"; # EPP → tasarruf
      };
    };
  };

  # ================== CPU TİPİNE ÖZEL (ÇAKIŞMASIZ) AYAR ==================
  # Not: intel_pstate min/max yüzdeleri sadece taban güvenliği için ayarlanır.
  # EPP yazımı governor=performance altında kilitlenebileceği için fallback içerir.
  systemd.services.cpu-type-optimizer = {
    description = "CPU type specific optimizations (EPP/HWP/turbo + safe floor)";
    after = [ "auto-cpufreq.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "cpu-type-optimizer" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        export PATH="${pkgs.util-linux}/bin:${pkgs.gnugrep}/bin:${pkgs.coreutils}/bin:$PATH"

        # Güç kaynağı tespiti
        ON_AC=0
        for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/AC/online /sys/class/power_supply/AC0/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
        done

        # Hedef EPP & taban yüzdesi
        if [[ "$ON_AC" == "1" ]]; then
          EPP="performance"; MIN_PCT=50; MAX_PCT=100; FLOOR=1600000
        else
          EPP="balance_power"; MIN_PCT=15; MAX_PCT=80;  FLOOR=800000
        fi

        # ----- EPP sağlam yazımı (governor kilidi varsa powersave geçişi) -----
        for policy in /sys/devices/system/cpu/cpufreq/policy*; do
          PREF="$policy/energy_performance_preference"
          GOV="$policy/scaling_governor"
          if [[ -w "$PREF" ]]; then
            if ! echo "$EPP" > "$PREF" 2>/dev/null; then
              # Governor kilitliyse geçici powersave → EPP yaz → geri al
              if [[ -w "$GOV" ]]; then
                CURGOV="$(cat "$GOV" 2>/dev/null || echo unknown)"
                echo powersave > "$GOV" 2>/dev/null || true
                echo "$EPP" > "$PREF" 2>/dev/null || true
                # AC'de performance'a geri; bataryada powersave kalsın
                if [[ "$ON_AC" == "1" ]]; then
                  echo performance > "$GOV" 2>/dev/null || true
                fi
              fi
            fi
          fi
        done

        # ----- intel_pstate güvenli taban -----
        if [[ -w /sys/devices/system/cpu/intel_pstate/min_perf_pct ]]; then
          echo "$MIN_PCT" > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || true
          echo "$MAX_PCT" > /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null || true
        fi

        # ----- Ek emniyet: policy bazında min freq -----
        for policy in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$policy/scaling_min_freq" ]] && echo "$FLOOR" > "$policy/scaling_min_freq" 2>/dev/null || true
        done

        # Turbo + HWP Dynamic Boost
        echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
        echo 1 > /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost 2>/dev/null || true

        # Tanılama
        STATUS_FILE=/sys/devices/system/cpu/intel_pstate/status
        [[ -r "$STATUS_FILE" ]] && echo "intel_pstate status: $(cat $STATUS_FILE)" | systemd-cat -t cpu-type-optimizer || true
        for policy in /sys/devices/system/cpu/cpufreq/policy*; do
          PREF="$policy/energy_performance_preference"
          CUR="$policy/scaling_cur_freq"; MIN="$policy/scaling_min_freq"; MAX="$policy/scaling_max_freq"; GOV="$policy/scaling_governor"
          echo "$(basename $policy) GOV=$(cat $GOV 2>/dev/null) EPP=$(cat $PREF 2>/dev/null) cur=$(cat $CUR 2>/dev/null) min=$(cat $MIN 2>/dev/null) max=$(cat $MAX 2>/dev/null)" | systemd-cat -t cpu-type-optimizer || true
        done

        echo "cpu-type-optimizer: AC=$ON_AC EPP=$EPP min_pct=$MIN_PCT turbo=on hwp_boost=on"
      '';
    };
  };

  # AC/DC değişiminde ve pil olaylarında optimizer'ı tekrar çalıştır
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", KERNEL=="AC*", ACTION=="change", \
      RUN+="${pkgs.systemd}/bin/systemctl start cpu-type-optimizer.service"
    SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ACTION=="change", \
      RUN+="${pkgs.systemd}/bin/systemctl start cpu-type-optimizer.service"
    SUBSYSTEM=="power_supply", ATTR{status}=="Charging", ACTION=="change", \
      RUN+="${pkgs.systemd}/bin/systemctl start cpu-type-optimizer.service"
  '';

  # ======================== DONANIM YÖNETİMİ ========================
  hardware = {
    # TrackPoint
    trackpoint = { enable = true; speed = 200; sensitivity = 200; emulateWheel = true; };

    # Intel Graphics
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

  # ======================== SİSTEM SERVİSLERİ ========================
  services = {
    thermald.enable = true;
    upower.enable = true;

    # ThinkFan
    thinkfan = {
      enable = true;
      levels = [
        ["level auto" 0 55]
        [1 55 65]
        [3 65 75]
        [7 75 85]
      ];
    };

    # logind davranışları
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

  # ======================== KERNEL YÖNETİMİ ========================
  boot = {
    kernelModules = [ "thinkpad_acpi" "coretemp" "intel_rapl" "i915" ];

    extraModprobeConfig = ''
      # Intel P-State dynamic boost
      options intel_pstate hwp_dynamic_boost=1
      # Audio güç tasarrufu
      options snd_hda_intel power_save=10 power_save_controller=Y
      # WiFi güç
      options iwlwifi power_save=1 power_level=3
      # USB & NVMe
      options usbcore autosuspend=5
      options nvme_core default_ps_max_latency_us=5500
    '';

    # Çakışmasız kernel parametreleri (minimal)
    kernelParams = [
      "intel_pstate=active"
      "intel_pstate.hwp_dynamic_boost=1"

      # P-State min/max burada YAZMA → saplanma riskini önle

      # Güç yönetimi
      "pcie_aspm=off"

      # GPU (çoklu monitör + Wayland stabil)
      "i915.enable_guc=3"
      "i915.enable_fbc=0"
      "i915.enable_psr=0"
      "i915.enable_sagv=0"

      # Uyku & NVMe
      "nvme_core.default_ps_max_latency_us=5500"
      "mem_sleep_default=deep"
    ];

    # Sadelestirilmiş sysctl
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
    };
  };

  # ======================== THİNKPAD ÖZEL AYARLAR ========================
  systemd.services.thinkpad-battery-thresholds = {
    description = "ThinkPad battery charge thresholds";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "set-battery-thresholds" ''
        #!${pkgs.bash}/bin/bash
        if [[ -w /sys/class/power_supply/BAT0/charge_start_threshold ]]; then
          echo 65 > /sys/class/power_supply/BAT0/charge_start_threshold
          echo "Battery start threshold: 65%"
        fi
        if [[ -w /sys/class/power_supply/BAT0/charge_stop_threshold ]]; then
          echo 85 > /sys/class/power_supply/BAT0/charge_stop_threshold
          echo "Battery stop threshold: 85%"
        fi
        # Eski ThinkPad yolları (yoksa sessiz geç)
        echo 65 > /sys/devices/platform/smapi/BAT0/start_charge_thresh 2>/dev/null || true
        echo 85 > /sys/devices/platform/smapi/BAT0/stop_charge_thresh 2>/dev/null || true
      '';
    };
  };

  # Derin uyku zorlaması (destek varsa)
  systemd.services.mem-sleep-deep = {
    description = "Force deep sleep mode when available";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "set-deep-sleep" ''
        #!${pkgs.bash}/bin/bash
        if [[ -w /sys/power/mem_sleep ]] && grep -q 'deep' /sys/power/mem_sleep; then
          echo deep > /sys/power/mem_sleep
          echo "mem_sleep set to deep"
        else
          echo "mem_sleep: deep not available"
        fi
      '';
    };
  };

  # ======================== THINKPAD MUTE LED FIX ========================
  # Bootta ve uykudan dönünce micmute/mute LED'lerini kapat.
  systemd.services."thinkpad-led-fix" = {
    description = "Turn off stuck ThinkPad mute LEDs";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "disable-thinkpad-mute-leds" ''
        #!${pkgs.bash}/bin/bash
        for led in /sys/class/leds/platform::micmute /sys/class/leds/platform::mute; do
          [[ -w "$led/brightness" ]] && echo 0 > "$led/brightness"
        done
      '';
    };
  };

  # Uykudan (suspend/hibernate) uyanınca da LED'leri söndür
  systemd.services."thinkpad-led-fix-resume" = {
    description = "Turn off ThinkPad mute LEDs on resume";
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "sleep.target" ];
    after = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "disable-thinkpad-mute-leds-resume" ''
        #!${pkgs.bash}/bin/bash
        for led in /sys/class/leds/platform::micmute /sys/class/leds/platform::mute; do
          [[ -w "$led/brightness" ]] && echo 0 > "$led/brightness"
        done
      '';
    };
  };

  # ======================== SUSPEND ÖNCESİ/SONRASI FAN ========================
  # Suspend öncesi thinkfan'ı durdur ve fanı otomatiğe al; resume sonrası geri başlat.
  systemd.services."suspend-pre-fan" = {
    description = "Stop thinkfan before suspend & set auto";
    wantedBy = [ "sleep.target" ];
    before = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "suspend-pre-fan" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        # thinkfan varsa durdur
        ${pkgs.systemd}/bin/systemctl stop thinkfan.service 2>/dev/null || true
        # Fanı otomatik moda al (ThinkPad ACPI)
        if [[ -w /proc/acpi/ibm/fan ]]; then
          echo "level auto" > /proc/acpi/ibm/fan 2>/dev/null || true
        fi
      '';
    };
  };

  systemd.services."resume-post-fan" = {
    description = "Start thinkfan after resume";
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "resume-post-fan" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        # Kısa gecikme: sensörler/topoloji otursun
        sleep 0.8
        if ${pkgs.systemd}/bin/systemctl is-enabled thinkfan.service >/dev/null 2>&1; then
          ${pkgs.systemd}/bin/systemctl start thinkfan.service 2>/dev/null || true
        else
          # thinkfan kullanılmıyorsa fanı yine otomatikte bırak
          if [[ -w /proc/acpi/ibm/fan ]]; then
            echo "level auto" > /proc/acpi/ibm/fan 2>/dev/null || true
          fi
        fi
      '';
    };
  };

  # ======================== KABY LAKE-R RAPL POWER LIMITS ====================
  # X1 Carbon 6th (i7-8650U) için güvenli limitler: PL1=18W, PL2=28W.
  # Bootta, AC/DC değişiminde ve uykudan dönünce yeniden uygular.
  systemd.services."rapl-power-limits" = {
    description = "Apply RAPL PL1/PL2 limits (Kaby Lake-R safe profile)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "set-rapl-limits" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail

        CPU_MODEL="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'Model name' | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.coreutils}/bin/tr -d '\n')"
        if ! echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE '8650U|8550U|8350U|8250U|Kaby *Lake'; then
          echo "Non-KabyLakeR CPU detected; skipping RAPL limits"; exit 0;
        fi

        # Hedefler (Watt)
        PL1_W=18
        PL2_W=28
        TW1_US=28000000   # 28s
        TW2_US=10000      # 10ms

        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          [[ -w "$R/constraint_0_power_limit_uw" ]] || continue
          echo $(( PL1_W * 1000000 )) > "$R/constraint_0_power_limit_uw" 2>/dev/null || true
          echo $TW1_US > "$R/constraint_0_time_window_us" 2>/dev/null || true
          if [[ -w "$R/constraint_1_power_limit_uw" ]]; then
            echo $(( PL2_W * 1000000 )) > "$R/constraint_1_power_limit_uw" 2>/dev/null || true
            echo $TW2_US > "$R/constraint_1_time_window_us" 2>/dev/null || true
          fi
        done

        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          PL1=$(cat "$R/constraint_0_power_limit_uw" 2>/dev/null || echo 0)
          PL2=$(cat "$R/constraint_1_power_limit_uw" 2>/dev/null || echo 0)
          echo "$(basename $R): PL1=$((PL1/1000000))W PL2=$((PL2/1000000))W" | ${pkgs.systemd}/bin/systemd-cat -t rapl-power
        done
      '';
    };
  };

  # AC/DC değişiminde yeniden uygula
  services.udev.extraRules = lib.mkAfter ''
    SUBSYSTEM=="power_supply", KERNEL=="AC*", ACTION=="change", \
      RUN+="${pkgs.systemd}/bin/systemctl start rapl-power-limits.service"
  '';

  # Uykudan dönünce yeniden uygula
  systemd.services."rapl-power-limits-resume" = {
    description = "Re-apply RAPL limits after resume";
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl start rapl-power-limits.service";
    };
  };
}
