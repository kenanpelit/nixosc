# ============================================================================
# modules/core/hardware/default.nix
# ----------------------------------------------------------------------------
# Advanced Hardware & Power Management (ThinkPad‑optimized) — v4.4.0 (commented)
# ----------------------------------------------------------------------------
# Bu modül; ThinkPad odaklı, Intel/AMD mobil işlemciler için güç yönetimi,
# termal kontrol, uyku/uyanma (suspend/resume) toparlanma düzeltmeleri ve
# pille/AC’de farklı davranışlar sağlayan bir dizi systemd servisi içerir.
#
# NEDEN BU MODÜL?
# - Bazı modern dizüstülerde suspend sonrası frekansların en düşükte takılı
#   kalması ("stuck at min freq") ve EPP’nin (Energy Performance Preference)
#   uygulanmaması görülebiliyor. Burada; governor→EPP→min_perf sıralaması,
#   turbo’yu dalgalandırma ve kısa süreli yük üretme gibi pratik çözümler var.
# - Intel RAPL (PL1/PL2) ile sürdürülebilir gücü limitleyip, fan/ısıl profilleri
#   daha öngörülebilir kılmak.
# - AC adaptör tak/çıkar ve resume olaylarına otomatik tepki vermek.
# - ThinkPad’e özgü LED/fan/batarya eşiği (charge threshold) ayarlarını
#   deklaratif hale getirmek.
# ----------------------------------------------------------------------------
# NOTLAR
# - Nix içinde oluşturulan betiklerde "#!/usr/bin/env bash" yerine Nix store’daki
#   ${pkgs.bash} yolu kullanılır; bu, bağımlılıkların deterministik olması içindir.
# - Her sysfs yazımı (echo > /sys/...) "|| true" ile sarıldı; bazı donanımlarda
#   ilgili düğümler olmayabilir, hatayı fail’e çevirmemek için.
# - Intel/AMD ayrımı; RAPL ve pstate düğümlerinin farklılığından ötürü gerekli.
# ============================================================================

{ config, lib, pkgs, ... }:

let
  # ---------------------------------------------------------------------------
  # CPU TESPİTİ (güvenli & genişletilmiş)
  # ---------------------------------------------------------------------------
  # Amaç: lscpu çıktısından model adını okuyup kabaca aileyi belirlemek.
  # Neden? AC/Batarya güç limitleri ve EPP hedefleri, işlemci ailesine göre
  # farklı rahatlık/güvenlik payları istiyor.
  detectCpuScript = pkgs.writeShellScript "detect-cpu" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    MODEL="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'Model name' | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.coreutils}/bin/tr -s ' ' | ${pkgs.coreutils}/bin/tr -d '\n')"

    # Intel aileleri
    if echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Core *Ultra|155H|Meteor *Lake'; then
      echo "meteorlake"
    elif echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE '13th *Gen|Raptor *Lake|1370P|1360P|1355U'; then
      echo "raptorlake"
    elif echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE '8650U|8550U|8350U|8250U|Kaby *Lake'; then
      echo "kabylaker"
    # AMD aileleri
    elif echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Ryzen.*7040|Ryzen.*7840|Phoenix'; then
      echo "amdzen4"
    elif echo "$MODEL" | ${pkks.gnugrep:-${pkgs.gnugrep}}/bin/grep -qiE 'Ryzen.*6000|Ryzen.*5000|Rembrandt|Cezanne' <<<"$MODEL"; then
      echo "amdzen3"
    else
      # Güvenli varsayılan: düşük TDP’li Kaby Lake‑R sınıfı gibi davran.
      echo "kabylaker"
    fi
  '';

  # ---------------------------------------------------------------------------
  # CPU PROFİLLERİ
  # ---------------------------------------------------------------------------
  # Bu profiller, RAPL PL1/PL2 (W) ve termal uyarı eşikleri için temel değerler.
  # Neden farklı? Meteor Lake gibi yeni nesil CPU’lar, kısa süreli daha yüksek
  # PL2’yi tolere ederken; eski nesillerde (Kaby Lake‑R) daha muhafazakâr olmak iyi.
  meteorLake = {
    battery = { pl1 = 28; pl2 = 42; };
    ac      = { pl1 = 42; pl2 = 60; };  # PL2 58 → 60: kısa burst’te daha çevik
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
  # ============================================================================
  # DONANIM (hardware.*)
  # ----------------------------------------------------------------------------
  # TrackPoint hızı/doyu, Intel iGPU VAAPI stack’i, firmware ve µcode güncelleme.
  # Amaç: Kutudan çıktığı gibi video decode (intel-media-driver, vaapi‑vdpau) ve
  # OpenCL/Level Zero (intel-compute-runtime, IGC) hazır olsun.
  # ============================================================================
  hardware = {
    trackpoint = { enable = true; speed = 200; sensitivity = 200; emulateWheel = true; };

    graphics = {
      enable = true;
      enable32Bit = true; # 32‑bit steam/wine vs. uyumluluk
      extraPackages = with pkgs; [
        intel-media-driver     # VAAPI/iHD
        mesa                   # OpenGL/Vulkan kullanıcı uzayı
        vaapiVdpau             # VAAPI→VDPAU köprüsü
        libvdpau-va-gl         # VAAPI→VDPAU GL üzerinden
        intel-compute-runtime  # OpenCL/NEO
        intel-graphics-compiler# IGC (SPIR-V→Gen ISA)
        level-zero             # oneAPI L0 runtime
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [ intel-media-driver ];
    };

    enableRedistributableFirmware = true; # Bazı Wi‑Fi/BT firmware’leri için şart
    enableAllFirmware = true;             # Geniş uyumluluk
    cpu.intel.updateMicrocode = true;     # Spekülasyon düzeltmeleri vb.

    bluetooth = {
      enable = true;
      powerOnBoot = true;                 # Boot’ta aç; uyandırma senaryoları
      settings.General = {
        FastConnectable = false;          # Düşük güçte daha az tarama
        ReconnectAttempts = 7;            # BT çevre birimine yeniden bağlanma
        ReconnectIntervals = "1,2,4,8,16,32,64"; # Exponential backoff
      };
    };
  };

  # ============================================================================
  # SERVİSLER (Güç & Termal)
  # ----------------------------------------------------------------------------
  # thermald: Intel’in termal kestirimlerine göre P‑state/PL ayarı yapar.
  # power-profiles-daemon/TLP devre dışı: Çakışmasın, tek otorite bu modül olsun.
  # thinkfan: Fan seviyelerini sıcaklığa göre kademeli yönetir.
  # upower: Düşük pil davranışları (hibernation vb.).
  # logind: Güç tuşları ve kapak davranışları.
  # journald: Log hacmini sınırlı tut.
  # dbus-broker: Daha performanslı D‑Bus uygulaması.
  # ============================================================================
  services = {
    thermald.enable = true;
    power-profiles-daemon.enable = false;
    tlp.enable = false;

    thinkfan = {
      enable = true;
      smartSupport = true; # HDD SMART tabanlı ek kaynak yoklamaları
      # [seviye, alt_sıcaklık, üst_sıcaklık]
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

    upower = {
      enable = true;
      criticalPowerAction = "Hibernate"; # Ani kapanma yerine güvenli hibernate
      percentageLow = 20;
      percentageCritical = 5;
      percentageAction = 3;
      usePercentageForPolicy = true;
    };

    logind.settings.Login = {
      # Güç tuşlarını yanlışlıkla kapatma/suspend tetiklememek için özelleştirme
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

    dbus = {
      implementation = "broker"; # dbus-daemon yerine broker → daha az GC yükü
      packages = [ pkgs.dconf ];
    };
  };

  # ============================================================================
  # BOOT & KERNEL
  # ----------------------------------------------------------------------------
  # - Modül seçenekleri: i915 güç özellikleri (FBC/PSR/SAGV), ASPM, iwlwifi tasarruf.
  # - kernelParams: i915 iGPU optimizasyonları; Intel IOMMU passthrough;
  #   derin uyku varsayılanı (mem_sleep_default=deep).
  # - sysctl: Dizüstü dostu VM ayarları (kirli sayfa eşikleri, swappiness düşürme).
  # ============================================================================
  boot = {
    kernelModules = [ "thinkpad_acpi" "coretemp" "intel_rapl" "msr" "kvm-intel" "i915" ];

    extraModprobeConfig = ''
      options thinkpad_acpi fan_control=1 brightness_mode=1 volume_mode=1 experimental=1
      options intel_pstate hwp_dynamic_boost=1
      options snd_hda_intel power_save=10 power_save_controller=Y
      options iwlwifi power_save=1 power_level=3
      options iwlmvm power_scheme=3
      options usbcore autosuspend=5
      options nvme_core default_ps_max_latency_us=5500
    '';

    kernelParams = [
      "intel_iommu=on" "iommu=pt"
      "intel_pstate=active"
      "intel_pstate.hwp_dynamic_boost=1"
      "nvme_core.default_ps_max_latency_us=5500"
      "nvme_core.io_timeout=30"
      "i915.enable_guc=3"      # GuC/HuC: medya/scheduling offload
      "i915.enable_fbc=1"      # Framebuffer Compression → güç tasarrufu
      "i915.enable_psr=1"      # Panel Self‑Refresh
      "i915.fastboot=1"        # Hızlı boot (display yeniden eğrileme azaltır)
      "i915.enable_sagv=1"     # System Agent Geyik… (bant/genişlik optim.)
      "pcie_aspm=default"      # ASPM’yi BIOS’a bırak, genelde iyi sonuç
      "iwlwifi.debug=0x0"
      "mem_sleep_default=deep" # s2idle yerine deep → daha düşük bekleme akımı
    ];

    kernel.sysctl = {
      "vm.swappiness" = 10;                    # SSD’li sistemde swap’i az kullan
      "vm.vfs_cache_pressure" = 50;            # inode/dentry cache’i çok agresif silme
      "vm.dirty_writeback_centisecs" = 1500;   # Kirli sayfaları ~15sn’de flush
      "vm.dirty_background_ratio" = 5;         # Arka plan flush eşiği
      "vm.dirty_ratio" = 10;                   # Maks kirli sayfa oranı
      "vm.laptop_mode" = 5;                    # Disk uykularını destekle
      "vm.page-cluster" = 0;                   # Swap okuma kümelerini küçült
      "vm.compact_unevictable_allowed" = 1;    # Compaction izinleri
      "kernel.nmi_watchdog" = 0;               # Az da olsa güç tasarrufu
      "kernel.sched_autogroup_enabled" = 1;    # Etkileşimli hissi iyileştir
      "kernel.sched_cfs_bandwidth_slice_us" = 3000; # CFS dilimi → jitter azalt
    };
  };

  # ============================================================================
  # systemd SERVİSLERİ — Suspend toparlanması için geliştirilmiş akış
  # ----------------------------------------------------------------------------
  # Akış:
  # 1) cpu-power-limit: Governor→EPP→min_perf sırası, RAPL (Intel), turbo toggling
  # 2) system-suspend-pre: Suspend öncesi fan/boost temizliği & durum kaydı
  # 3) system-resume-post: Resume sonrası politikaları sıfırla→boost→yeniden uygula
  # 4) cpu-frequency-unstick: Manuel/otomatik itici – frekanslar takılırsa düzelt
  # ============================================================================
  systemd.services = {
    # -------------------------------------------------------------------------
    # ANA CPU GÜÇ SERVİSİ
    # - Governor → EPP → min_perf sıralaması kritik: Bazı çekirdeklerde EPP,
    #   governor değişmeden uygulanmıyor. Ardından min_perf_pct ile taban tavanı
    #   koyuyoruz. Son olarak kısa yük/turbo toggle ile frekansları "uyandırıyoruz".
    # -------------------------------------------------------------------------
    cpu-power-limit = {
      description = "Apply CPU power limits and performance settings";
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "cpu-power-limit" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail

          CPU_TYPE="$(${detectCpuScript})"

          # AC/Batarya tespiti: Birden fazla adlandırma olabildiği için sırayla dene
          ON_AC=0
          for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/AC/online /sys/class/power_supply/AC0/online; do
            [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
          done

          # --- Yardımcılar ---
          apply_limits() {
            local PL1_W="$1" PL2_W="$2" TW1_US="$3" TW2_US="$4"
            local RAPL="/sys/class/powercap/intel-rapl:0"
            [[ -d "$RAPL" ]] || { echo "RAPL not available"; return 0; }

            echo $(( PL1_W * 1000000 )) > "$RAPL/constraint_0_power_limit_uw" || true
            echo $(( PL2_W * 1000000 )) > "$RAPL/constraint_1_power_limit_uw" || true
            echo "$TW1_US" > "$RAPL/constraint_0_time_window_us" || true
            echo "$TW2_US" > "$RAPL/constraint_1_time_window_us" || true

            ACTUAL_PL1=$(cat "$RAPL/constraint_0_power_limit_uw" 2>/dev/null || echo 0)
            ACTUAL_PL2=$(cat "$RAPL/constraint_1_power_limit_uw" 2>/dev/null || echo 0)
            printf 'RAPL: PL1=%sW PL2=%sW (AC=%s)\n' "$(($ACTUAL_PL1/1000000))" "$(($ACTUAL_PL2/1000000))" "$ON_AC"
          }

          set_governor_epp() {
            local GOV="$1" EPP="$2" MIN_PCT="$3"
            echo "Setting: Governor=$GOV EPP=$EPP MinPerf=$MIN_PCT%"

            # 1) Tüm politikaları donanım sınırlarına sıfırla (temiz başlangıç)
            for p in /sys/devices/system/cpu/cpufreq/policy*; do
              if [[ -f "$p/cpuinfo_min_freq" && -f "$p/cpuinfo_max_freq" ]]; then
                cat "$p/cpuinfo_min_freq" > "$p/scaling_min_freq" 2>/dev/null || true
                cat "$p/cpuinfo_max_freq" > "$p/scaling_max_freq" 2>/dev/null || true
              fi
            done

            # 2) Governor uygula (EPP bundan sonra daha tutarlı yazılır)
            for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
              echo "$GOV" > "$g" 2>/dev/null || true
            done
            sleep 0.1

            # 3) EPP uygula; başarısızsa bir kez daha dene
            for p in /sys/devices/system/cpu/cpufreq/policy*; do
              if [[ -f "$p/energy_performance_preference" ]]; then
                echo "$EPP" > "$p/energy_performance_preference" || {
                  echo "Warning: Failed to set EPP for $p, retrying..."
                  sleep 0.5
                  echo "$EPP" > "$p/energy_performance_preference" 2>/dev/null || true
                }
              fi
              # 4) Min/Max frekansları MIN_PCT’e göre ayarla
              if [[ -f "$p/cpuinfo_max_freq" ]] && [[ "$MIN_PCT" =~ ^[0-9]+$ ]]; then
                MAX=$(cat "$p/cpuinfo_max_freq")
                MIN=$(( MAX * MIN_PCT / 100 ))
                echo "$MIN" > "$p/scaling_min_freq" 2>/dev/null || true
                echo "$MAX" > "$p/scaling_max_freq" 2>/dev/null || true
              fi
            done

            # 5) Intel/AMD pstate min_perf_pct (global ayarlar)
            if [[ -w /sys/devices/system/cpu/intel_pstate/min_perf_pct ]]; then
              echo "$MIN_PCT" > /sys/devices/system/cpu/intel_pstate/min_perf_pct || true
              echo "$MIN_PCT set to intel_pstate/min_perf_pct"
            fi
            if [[ -w /sys/devices/system/cpu/amd_pstate/min_perf_pct ]]; then
              echo "$MIN_PCT" > /sys/devices/system/cpu/amd_pstate/min_perf_pct || true
            fi

            # 6) Turbo açık olsun; HWP dynamic boost’u etkin tut
            echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
            echo 1 > /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost 2>/dev/null || true

            sleep 0.2
            ACTUAL_EPP=$(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null || echo "unknown")
            echo "EPP verification: requested=$EPP, actual=$ACTUAL_EPP"
          }

          force_cpu_boost() {
            # Amaç: Suspend sonrası tembelleşmiş P‑state’leri kısa süreli boost ile uyandırmak
            echo "Forcing CPU frequency boost..."

            # 1) Tüm çekirdekleri donanım max’a dayandır
            for p in /sys/devices/system/cpu/cpufreq/policy*; do
              if [[ -f "$p/scaling_max_freq" ]]; then
                MAX=$(cat "$p/cpuinfo_max_freq")
                echo "$MAX" > "$p/scaling_min_freq" 2>/dev/null || true
                echo "$MAX" > "$p/scaling_max_freq" 2>/dev/null || true
              fi
            done

            # 2) Kısa yük üret
            timeout 0.5 dd if=/dev/zero of=/dev/null bs=1M count=100 2>/dev/null || true

            # 3) Turbo’yu kapat‑aç dalgala (bazı BIOS/µcode sürümlerinde işe yarıyor)
            echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
            sleep 0.1
            echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true

            echo "CPU boost triggered"
          }

          case "$CPU_TYPE" in
            meteorlake|raptorlake)
              if [[ "$ON_AC" == "1" ]]; then
                apply_limits ${toString meteorLake.ac.pl1} ${toString meteorLake.ac.pl2} 28000000 10000
                set_governor_epp performance performance 75
                force_cpu_boost
              else
                apply_limits ${toString meteorLake.battery.pl1} ${toString meteorLake.battery.pl2} 28000000 10000
                set_governor_epp powersave balance_performance 40
              fi
              ;;
            kabylaker)
              if [[ "$ON_AC" == "1" ]]; then
                apply_limits ${toString kabyLakeR.ac.pl1} ${toString kabyLakeR.ac.pl2} 28000000 10000
                set_governor_epp performance performance 60
                force_cpu_boost
              else
                apply_limits ${toString kabyLakeR.battery.pl1} ${toString kabyLakeR.battery.pl2} 28000000 10000
                set_governor_epp powersave balance_power 35
              fi
              ;;
            amdzen4|amdzen3)
              # AMD’de RAPL yerine pstate/CPPC kullanılacağı için yalnızca governor/EPP
              if [[ "$ON_AC" == "1" ]]; then
                set_governor_epp performance performance 60
                force_cpu_boost
              else
                set_governor_epp powersave balance_power 35
              fi
              ;;
            *)
              # Bilinmeyen aile: Kaby Lake‑R temelli güvenli değerler
              if [[ "$ON_AC" == "1" ]]; then
                apply_limits ${toString kabyLakeR.ac.pl1} ${toString kabyLakeR.ac.pl2} 28000000 10000
                set_governor_epp performance performance 60
                force_cpu_boost
              else
                apply_limits ${toString kabyLakeR.battery.pl1} ${toString kabyLakeR.battery.pl2} 28000000 10000
                set_governor_epp powersave balance_power 35
              fi
              ;;
          esac

          echo "CPU power configuration complete (AC=$ON_AC, CPU=$CPU_TYPE)"
        '';
      };
    };

    # -------------------------------------------------------------------------
    # LED DURUMLARI — ThinkPad mikrofon/sessize al LED’leri + logo noktası
    # -------------------------------------------------------------------------
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

    # -------------------------------------------------------------------------
    # BATARYA EŞİKLERİ — Uzun ömür için şarj aralığını sınırlama
    # -------------------------------------------------------------------------
    battery-charge-threshold = {
      description = "Configure battery charge thresholds";
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

          echo "$START" > "$BAT/charge_control_start_threshold" 2>/dev/null || true
          echo "$STOP"  > "$BAT/charge_control_end_threshold"   2>/dev/null || true
          echo "Battery thresholds: Start=$START% Stop=$STOP%"
        '';
      };
    };

    # -------------------------------------------------------------------------
    # SUSPEND ÖNCESİ — Fanı otomatiğe al, turbo’yu kapat, AC durumunu kaydet
    # -------------------------------------------------------------------------
    system-suspend-pre = {
      description = "Prepare system for suspend";
      wantedBy = [ "sleep.target" ];
      before = [ "sleep.target" ];
      unitConfig = {
        DefaultDependencies = false;
        StopWhenUnneeded = false;
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "suspend-pre" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          echo "Preparing for suspend..."

          # thinkfan’i durdur; BIOS/EC uyku sırasında fanı kendi yönetsin
          ${systemctl} stop thinkfan.service 2>/dev/null || true

          # Fanı otomatik moda al (ThinkPad ACPI)
          if [[ -w /proc/acpi/ibm/fan ]]; then
            echo "level auto" > /proc/acpi/ibm/fan 2>/dev/null || true
          fi

          # AC durumunu /run’a yaz (resume sonrası aynı politika için ipucu)
          ON_AC=0
          for PS in /sys/class/power_supply/AC*/online; do
            [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
          done
          echo "$ON_AC" > /run/power_state 2>/dev/null || true

          # Turbo’yu kapat (bazı firmware’ler uykuya geçişte bunu seviyor)
          echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true

          echo "Suspend preparation complete"
        '';
      };
    };

    # -------------------------------------------------------------------------
    # RESUME SONRASI — Politikalara reset→boost→yeniden uygula
    # -------------------------------------------------------------------------
    system-resume-post = {
      description = "Restore system after resume";
      wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
      after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
      unitConfig = {
        DefaultDependencies = false;
        StopWhenUnneeded = false;
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "resume-post" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          echo "Starting resume recovery..."
          sleep 2  # Aygıtlar tam gelsin

          echo "Resetting CPU frequency states..."
          # 1) Tüm politikaları donanım varsayılanına sıfırla
          for p in /sys/devices/system/cpu/cpufreq/policy*; do
            if [[ -f "$p/cpuinfo_min_freq" && -f "$p/cpuinfo_max_freq" ]]; then
              cat "$p/cpuinfo_min_freq" > "$p/scaling_min_freq" 2>/dev/null || true
              cat "$p/cpuinfo_max_freq" > "$p/scaling_max_freq" 2>/dev/null || true
            fi
            echo "default" > "$p/energy_performance_preference" 2>/dev/null || true
          done

          # 2) Turbo toggle ile P‑state’leri dürt
          echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
          sleep 0.5
          echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true

          # 3) Kısa süre tüm çekirdekleri max’a zorla + yük üret
          echo "Triggering CPU frequency boost..."
          for p in /sys/devices/system/cpu/cpufreq/policy*; do
            if [[ -f "$p/cpuinfo_max_freq" ]]; then
              MAX=$(cat "$p/cpuinfo_max_freq")
              echo "$MAX" > "$p/scaling_min_freq" 2>/dev/null || true
            fi
          done
          timeout 1 dd if=/dev/zero of=/dev/null bs=1M count=200 2>/dev/null || true
          sleep 1

          # 4) Asıl güç politikasını yeniden uygula (servisi baştan çalıştır)
          echo "Reapplying power configuration..."
          ${systemctl} restart cpu-power-limit.service || {
            echo "Failed to restart cpu-power-limit, applying direct minimal policy..."
            ON_AC=0
            for PS in /sys/class/power_supply/AC*/online; do
              [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
            done
            if [[ "$ON_AC" == "1" ]]; then
              for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                echo "performance" > "$g" 2>/dev/null || true
              done
              for p in /sys/devices/system/cpu/cpufreq/policy*; do
                echo "performance" > "$p/energy_performance_preference" 2>/dev/null || true
              done
              echo 75 > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || true
            fi
          }

          # 5) thinkfan’i geri başlat
          if ${systemctl} is-enabled thinkfan.service >/dev/null 2>&1; then
            ${systemctl} restart thinkfan.service || true
          fi

          sleep 1
          GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
          EPP=$(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null || echo "unknown")
          echo "Resume complete: Governor=$GOV, EPP=$EPP"
        '';
      };
    };

    # -------------------------------------------------------------------------
    # FREKANS UNSTICK — Manuel tetiklenebilir: stuck frekansları agresif düzelt
    # -------------------------------------------------------------------------
    cpu-frequency-unstick = {
      description = "Force CPU frequencies to unstick";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "frequency-unstick" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          echo "=== Forcing CPU frequency unstick ==="

          # 1) Her şeyi varsayılan donanım limitlerine sıfırla
          for p in /sys/devices/system/cpu/cpufreq/policy*; do
            if [[ -f "$p/cpuinfo_min_freq" && -f "$p/cpuinfo_max_freq" ]]; then
              MIN_HW=$(cat "$p/cpuinfo_min_freq")
              MAX_HW=$(cat "$p/cpuinfo_max_freq")
              echo "$MIN_HW" > "$p/scaling_min_freq" 2>/dev/null || true
              echo "$MAX_HW" > "$p/scaling_max_freq" 2>/dev/null || true
            fi
          done

          # 2) Geçici olarak performance governor
          for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            echo "performance" > "$g" 2>/dev/null || true
          done

          # 3) Maks frekansa bastır
          for p in /sys/devices/system/cpu/cpufreq/policy*; do
            if [[ -f "$p/cpuinfo_max_freq" ]]; then
              MAX=$(cat "$p/cpuinfo_max_freq")
              echo "$MAX" > "$p/scaling_min_freq" 2>/dev/null || true
            fi
          done

          # 4) Sürekli kısa yükler üret
          echo "Generating load to trigger frequency scaling..."
          for i in {1..4}; do
            timeout 0.5 dd if=/dev/zero of=/dev/null bs=1M count=500 2>/dev/null &
          done
          wait || true

          # 5) Kalıcı politika ile yerine oturt
          sleep 1
          ${systemctl} restart cpu-power-limit.service
          echo "Frequency unstick complete"
        '';
      };
    };
  };

  # ============================================================================
  # UDEV KURALLARI — AC değişim tetikleyicisi & USB güç yönetimi & LED izinleri
  # ----------------------------------------------------------------------------
  # - AC güç kaynağı değişiminde cpu-power-limit yeniden başlatılır → anında uyum.
  # - Bazı Logitech/USB‑HID cihazlarda autosuspend kapatılır (girdi gecikmesizliği).
  # - USB add (resume göstergesi olarak) geldiğinde, frekans "unstick" yedeği.
  # ============================================================================
  services.udev.extraRules = lib.mkAfter ''
    # LED permissions
    SUBSYSTEM=="leds", KERNEL=="platform::micmute", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 664 /sys/class/leds/%k/brightness"
    SUBSYSTEM=="leds", KERNEL=="platform::mute",    ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 664 /sys/class/leds/%k/brightness"

    # USB autosuspend
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usbhid", ATTR{power/control}="on"

    # AC adapter change → reapply power settings
    SUBSYSTEM=="power_supply", KERNEL=="AC*", ACTION=="change", RUN+="${systemctl} restart cpu-power-limit.service"

    # Resume detection via USB devices (backup trigger)
    ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", RUN+="${pkgs.bash}/bin/bash -c 'sleep 3 && ${systemctl} start cpu-frequency-unstick.service'"
  '';

  # ============================================================================
  # ZAMANLAYICILAR (timers)
  # ----------------------------------------------------------------------------
  # - cpu-power-limit: Boot’tan 30sn sonra ve her 10 dakikada bir ayarları
  #   tekrar gözden geçir (AC→batarya geçişi kaçtıysa yakala).
  # - cpu-frequency-check: Her 5 dakikada bir "stuck" kontrolü yap; eğer çekirdek
  #   frekanslarının çoğu min civarındaysa unstick servis tetiklensin.
  # ============================================================================
  systemd.timers = {
    cpu-power-limit = {
      description = "Timer for CPU power limit application";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "30s";
        OnUnitActiveSec = "10min";  # Daha sık kontrol → daha az sürpriz
        Persistent = true;
      };
    };

    cpu-frequency-check = {
      description = "Periodic CPU frequency stuck check";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "5min";
        Persistent = false;
      };
    };
  };

  systemd.services.cpu-frequency-check = {
    description = "Check and fix stuck CPU frequencies";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "frequency-check" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        # Amaç: Çoğunluk çekirdek min frekans civarında mı? Evetse unstick et.

        STUCK=0
        MIN_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq 2>/dev/null || echo 400000)

        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
          [[ -f "$cpu" ]] || continue
          CUR=$(cat "$cpu")
          if [[ $CUR -le $((MIN_FREQ + 100000)) ]]; then
            STUCK=$((STUCK + 1))
          fi
        done

        TOTAL_CPUS=$(ls /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | wc -l | tr -d ' ')

        if [[ -n "$TOTAL_CPUS" && $TOTAL_CPUS -gt 0 && $STUCK -gt $((TOTAL_CPUS / 2)) ]]; then
          echo "Detected stuck frequencies on $STUCK/$TOTAL_CPUS CPUs, triggering unstick..."
          ${systemctl} start cpu-frequency-unstick.service
        else
          echo "Frequencies look OK ($STUCK/$TOTAL_CPUS near min)."
        fi
      '';
    };
  };
}

