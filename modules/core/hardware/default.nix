# ============================================================================
# modules/core/hardware/default.nix
# ----------------------------------------------------------------------------
# Advanced Hardware & Power Management (ThinkPad-optimized) — v7.0 STABLE
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
  # Tek yönetici: auto-cpufreq (çakışmayı önlemek için tlp ve ppd kapalı)
  services.tlp.enable = false;
  services.power-profiles-daemon.enable = false;

  services.auto-cpufreq = {
    enable = true;
    settings = {
      # ---------------------------- AC MODU ----------------------------
      charger = {
        governor = "performance";
        turbo = "auto";
        scaling_min_freq = 1600000;   # 1.6 GHz taban (AC): 400 MHz'e kilitlenme riskini engeller
        scaling_max_freq = 4800000;   # 4.8 GHz tavan (modeline göre güvenli)
        energy_performance_preference = "performance";  # EPP → güçlü tepki
      };

      # -------------------------- BATARYA MODU ------------------------
      battery = {
        governor = "powersave";
        turbo = "auto";
        scaling_min_freq = 800000;    # 0.8 GHz taban (bataryada sessizlik/ömrü iyileştirir)
        scaling_max_freq = 3500000;   # 3.5 GHz tavan (ısıl/pil kazancı)
        energy_performance_preference = "balance_power"; # EPP → tasarruf odaklı
      };
    };
  };

  # ================== CPU TİPİNE ÖZEL (ÇAKIŞMASIZ) AYAR ==================
  # Not: intel_pstate min/max yüzdeleri sadece "güvenli taban" için dokunuluyor.
  # EPP yazımı bazı çekirdek/BIOS kombinasyonlarında governor yüzünden başarısız olabildiği
  # için, geçici 'powersave' flip ile fallback içerir.
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

        # ----- EPP sağlam yazımı (governor kilitliyse powersave → yaz → geri) -----
        for policy in /sys/devices/system/cpu/cpufreq/policy*; do
          PREF="$policy/energy_performance_preference"
          GOV="$policy/scaling_governor"
          if [[ -w "$PREF" ]]; then
            if ! echo "$EPP" > "$PREF" 2>/dev/null; then
              if [[ -w "$GOV" ]]; then
                CURGOV="$(cat "$GOV" 2>/dev/null || echo unknown)"
                echo powersave > "$GOV" 2>/dev/null || true
                echo "$EPP" > "$PREF" 2>/dev/null || true
                [[ "$ON_AC" == "1" ]] && echo performance > "$GOV" 2>/dev/null || true
              fi
            fi
          fi
        done

        # ----- intel_pstate güvenli taban -----
        if [[ -w /sys/devices/system/cpu/intel_pstate/min_perf_pct ]]; then
          echo "$MIN_PCT" > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || true
          echo "$MAX_PCT" > /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null || true
        fi

        # ----- Ek emniyet: policy bazında min freq (floor) -----
        for policy in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$policy/scaling_min_freq" ]] && echo "$FLOOR" > "$policy/scaling_min_freq" 2>/dev/null || true
        done

        # Turbo + HWP Dynamic Boost
        echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
        echo 1 > /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost 2>/dev/null || true

        # Tanılama (journald)
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

  # ======================== UDEV — TEK BLOK (ÇAKIŞMASIZ) ========================
  # Burada iki farklı ihtiyacı TEK extraRules içinde birleştiriyoruz:
  # 1) AC/DC değişiminde EPP/floor yeniden uygula (cpu-type-optimizer)
  # 2) RAPL PL1/PL2 limitlerini AC değişiminde yeniden uygula
  # Böylece dosya içinde aynı anahtarı ikinci kez tanımlayıp "attribute ... already defined"
  # hatasına düşmüyoruz.
  services.udev.extraRules = ''
    # AC/DC değişimi → optimizer tetikle
    SUBSYSTEM=="power_supply", KERNEL=="AC*", ACTION=="change", \
      RUN+="${pkgs.systemd}/bin/systemctl start cpu-type-optimizer.service"
    SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ACTION=="change", \
      RUN+="${pkgs.systemd}/bin/systemctl start cpu-type-optimizer.service"
    SUBSYSTEM=="power_supply", ATTR{status}=="Charging", ACTION=="change", \
      RUN+="${pkgs.systemd}/bin/systemctl start cpu-type-optimizer.service"

    # AC değişimi → RAPL limitlerini yeniden uygula (Kaby Lake-R güvenli profili)
    SUBSYSTEM=="power_supply", KERNEL=="AC*", ACTION=="change", \
      RUN+="${pkgs.systemd}/bin/systemctl start rapl-power-limits.service"
  '';

  # ======================== DONANIM YÖNETİMİ ========================
  hardware = {
    # TrackPoint
    trackpoint = { enable = true; speed = 200; sensitivity = 200; emulateWheel = true; };

    # Intel Graphics (Wayland çoklu monitör için kararlı seçenekler yukarıda kernelParams’ta)
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
    thermald.enable = true;  # Intel termal sürüş: throttle davranışını iyileştirir
    upower.enable = true;

    # ThinkFan: basit fan eğrisi (yükte hızlan, boşta sessiz)
    thinkfan = {
      enable = true;
      levels = [
        ["level auto" 0 55]
        [1 55 65]
        [3 65 75]
        [7 75 85]
      ];
    };

    # logind davranışları (dizüstü odaklı)
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

    # Çakışmasız kernel parametreleri (minimal ama etkili)
    kernelParams = [
      "intel_pstate=active"
      "intel_pstate.hwp_dynamic_boost=1"

      # P-State min/max burada YAZMA → 400 MHz kilitlenme riskini önler

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

    # Sade sysctl (gereksiz scheduler hack yok)
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

  # Derin uyku zorlaması (destek varsa): s2idle yerine deep kullanmayı dener
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
  # Bootta ve uykudan dönünce micmute/mute LED'lerini kapat (takılı kalma bug'ı için).
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
  # Suspend öncesi thinkfan'ı durdurup fanı otomatiğe al; resume sonrası thinkfan'ı geri başlat.
  # Neden: Uykuda fan açık kalma/manuel modda takılı kalma sorunlarını engeller.
  systemd.services."suspend-pre-fan" = {
    description = "Stop thinkfan before suspend & set auto";
    wantedBy = [ "sleep.target" ];
    before = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "suspend-pre-fan" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        ${pkgs.systemd}/bin/systemctl stop thinkfan.service 2>/dev/null || true
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
        sleep 0.8  # sensörler otursun
        if ${pkgs.systemd}/bin/systemctl is-enabled thinkfan.service >/dev/null 2>&1; then
          ${pkgs.systemd}/bin/systemctl start thinkfan.service 2>/dev/null || true
        else
          if [[ -w /proc/acpi/ibm/fan ]]; then
            echo "level auto" > /proc/acpi/ibm/fan 2>/dev/null || true
          fi
        fi
      '';
    };
  };

  # ======================== KABY LAKE-R RAPL POWER LIMITS ====================
  # X1 Carbon 6th (i7-8650U) için güvenli limitler: PL1=18W, PL2=28W.
  # Neden: Yük altında ısı ve fan gürültüsünü makul seviyede tutarken performansı dengeler.
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
        TW2_US=10000      # 10ms (PL2 kısa patlama)

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

        # Tanılama: uygulanan değerleri log’a yaz
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          PL1=$(cat "$R/constraint_0_power_limit_uw" 2>/dev/null || echo 0)
          PL2=$(cat "$R/constraint_1_power_limit_uw" 2>/dev/null || echo 0)
          echo "$(basename $R): PL1=$((PL1/1000000))W PL2=$((PL2/1000000))W" | ${pkgs.systemd}/bin/systemd-cat -t rapl-power
        done
      '';
    };
  };

  # Uykudan dönünce RAPL’i tazele (separate unit, tetik: suspend/hibernate)
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
