# modules/core/hardware/default.nix
# ==============================================================================
# Advanced Hardware and Power Management Configuration
# ==============================================================================
# Comprehensive hardware optimization for ThinkPad systems with intelligent
# runtime detection and adaptive power management strategies.
#
# Supported Systems:
# - ThinkPad X1 Carbon 6th (Intel Core i7-8650U, 16GB RAM)
# - ThinkPad E14 Gen 6 (Intel Core Ultra 7 155H, 64GB RAM)
#
# Version: 4.0.0
# Author:  Kenan Pelit
# Date:    2025-08-28
#
# Özet:
# - Fan kontrol: thinkfan (ultra sessiz profil)
# - CPU RAPL limitleri: model + güç kaynağına göre
# - Governor/EPP: AC'de agresif, bataryada dengeli
# - Sleep hook'ları: suspend/resume optimizasyonu
# - Timer bazlı gecikme: boot sonrası düzgün RAPL uygulaması
# ==============================================================================

{ config, lib, pkgs, ... }:

let
  # ----------------------------------------------------------------------------
  # CPU ALGILAMA (genişletilmiş, güvenli)
  # Dönüş: "meteorlake" | "kabylaker" | "raptorlake" | "amdzen3" | "amdzen4"
  # ----------------------------------------------------------------------------
  detectCpuScript = pkgs.writeShellScript "detect-cpu" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    MODEL="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'Model name' | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.coreutils}/bin/tr -s ' ' | ${pkgs.coreutils}/bin/tr -d '\n')"
    
    # Intel CPU ailesi algılama
    if echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Core *Ultra|155H|Meteor *Lake'; then
      echo "meteorlake"
    elif echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE '13th *Gen|Raptor *Lake|1370P|1360P|1355U'; then
      echo "raptorlake"  
    elif echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE '8650U|8550U|8350U|8250U|Kaby *Lake'; then
      echo "kabylaker"
    # AMD CPU ailesi algılama  
    elif echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Ryzen.*7040|Ryzen.*7840|Phoenix'; then
      echo "amdzen4"
    elif echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Ryzen.*6000|Ryzen.*5000|Rembrandt|Cezanne'; then
      echo "amdzen3"
    else
      echo "kabylaker"  # güvenli varsayılan
    fi
  '';

  # ----------------------------------------------------------------------------
  # CPU PROFİLLERİ (Watt cinsinden PL1/PL2 + termal eşikler + pil yönetimi)
  # 
  # PL1: Sürekli güç limiti (Sustained Power Limit)
  # PL2: Kısa süreli boost limiti (Turbo Power Limit) 
  # trip: Fan devreye girme sıcaklığı (°C)
  # tripAc: AC'de daha agresif termal limit (performans odaklı)
  # warning: Kullanıcı uyarı seviyesi
  # critical: Donanım koruması (emergency shutdown)
  # ----------------------------------------------------------------------------
  
  meteorLake = {
    # Güç limitleri - Intel Core Ultra 7 155H profili
    battery = { 
      pl1 = 28;  # Bataryada dengeli performans (28W sürekli)
      pl2 = 42;  # Boost durumunda 42W'a kadar
    };
    ac = { 
      pl1 = 42;  # AC'de daha agresif
      pl2 = 58;  # Maximum turbo boost
    };
    
    # Termal yönetim - Modern CPU için optimize
    thermal = { 
      trip = 82;     # Erken müdahale - TVB koruması
      tripAc = 88;   # AC'de biraz daha toleranslı
      warning = 92;  # Kullanıcı uyarısı
      critical = 100; # Emergency shutdown
    };
    
    # Pil ömrü optimizasyonu - Modern Li-ion için
    battery_threshold = { 
      start = 65;  # Şarj başlangıcı - daha iyi döngü ömrü
      stop = 85;   # Şarj durması - günlük kullanım dengesi
    };
  };

  kabyLakeR = {
    # Güç limitleri - Intel Core i7-8650U profili  
    battery = { 
      pl1 = 15;  # Düşük güç tüketimi (verimlilik odaklı)
      pl2 = 25;  # Kısa boost'lar için yeterli
    };
    ac = { 
      pl1 = 25;  # AC'de daha yüksek sürekli performans
      pl2 = 35;  # Maximum turbo capacity
    };
    
    # Termal yönetim - Eski nesil CPU için konservatif
    thermal = { 
      trip = 78;     # Erken koruma (düşük TDP için uygun)
      tripAc = 82;   # AC'de biraz daha toleranslı
      warning = 85;  # Erkenci uyarı  
      critical = 95; # Güvenli shutdown
    };
    
    # Pil eşikleri - Eski ThinkPad'ler için konservatif
    battery_threshold = { 
      start = 75;  # Yüksek başlangıç (pil yaşlanması daha az)
      stop = 80;   # Düşük üst limit (maksimum ömür)
    };
  };

  systemctl = "${pkgs.systemd}/bin/systemctl";
in
{
  # =============================================================================
  # DONANIM
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
  # SERVİSLER (Güç & Termal)
  # =============================================================================
  services = {
    # ----------------------------------------------------------------------------
    # TERMAL YÖNETİM
    # thermald: Intel CPU termal yönetimi (turbo boost kontrolü, sıcaklık bazlı throttling)
    # thinkfan: Fan hız kontrolü (thermald ile uyumlu çalışır, farklı görevler)
    # ----------------------------------------------------------------------------
    thermald.enable = true;
    
    # ----------------------------------------------------------------------------
    # ÇAKIŞAN SERVİSLER (kapalı tutulması gerekir)
    # power-profiles-daemon: GNOME güç profilleri - TLP/manual yönetimle çakışır
    # tlp: Otomatik güç yönetimi - manual RAPL/governor kontrolümüzle çakışır
    # ----------------------------------------------------------------------------
    power-profiles-daemon.enable = false;
    tlp.enable = false;
    
    # ----------------------------------------------------------------------------
    # THINKFAN - Akıllı Fan Kontrolü (Ultra Sessiz Profil)
    # Histerezis mantığı: Her seviye örtüşür, fan titremesini önler
    # Örnek: 59°C'de Level 1'e çıkar, 48°C'ye düşene kadar Level 1'de kalır
    # ----------------------------------------------------------------------------
    thinkfan = {
      enable = true;
      smartSupport = true;  # NVMe/SATA sıcaklık sensörlerini kullan
      
      # Fan seviyeleri - Maksimum sessizlik için optimize edilmiş
      # [fan_level  min_temp  max_temp]
      # min_temp: Bu seviyeye GERİ DÖNÜŞ sıcaklığı (aşağı inerken)
      # max_temp: Bir sonraki seviyeye ÇIKIŞ sıcaklığı (yukarı çıkarken)
      levels = [
        [0  0   52]    # Level 0: Tamamen sessiz, 52°C'ye kadar
        [1  48  59]    # Level 1: 59°C'de Level 2'ye çık, 48°C'de Level 0'a dön (4°C histerezis)
        [2  55  65]    # Level 2: 65°C'de Level 3'e çık, 55°C'de Level 1'e dön (4°C histerezis)
        [3  61  71]    # Level 3: 71°C'de Level 4'e çık, 61°C'de Level 2'ye dön (4°C histerezis)
        [4  67  77]    # Level 4: 77°C'de Level 5'e çık, 67°C'de Level 3'e dön (4°C histerezis)
        [5  73  83]    # Level 5: 83°C'de Level 6'ya çık, 73°C'de Level 4'e dön (4°C histerezis)
        [6  79  89]    # Level 6: 89°C'de Level 7'ye çık, 79°C'de Level 5'e dön (4°C histerezis)
        [7  85  32767] # Level 7: Maksimum hız, sadece 85°C üstünde
      ];
    };
   
    # ----------------------------------------------------------------------------
    # UPOWER - Pil Yönetimi
    # Kritik seviyeler ve eylemler
    # ----------------------------------------------------------------------------
    upower = {
     enable = true;
      criticalPowerAction = "Hibernate";     # %3'te hibernate (veri kaybını önle)
      percentageLow = 20;                     # Düşük pil uyarısı
      percentageCritical = 5;                 # Kritik pil uyarısı
      percentageAction = 3;                   # Hibernate tetikleme seviyesi
      usePercentageForPolicy = true;          # Yüzde bazlı politika kullan
    };
    
    # ----------------------------------------------------------------------------
    # LOGIND - Sistem Davranışları
    # Güç tuşları, kapak ve idle yönetimi
    # ----------------------------------------------------------------------------
    logind.settings.Login = {
      # Güç tuşu davranışları
      HandlePowerKey = "ignore";              # Kısa basma: yoksay (yanlışlıkla kapanma önlenir)
      HandlePowerKeyLongPress = "poweroff";   # Uzun basma: kapat
      HandleSuspendKey = "suspend";           # Suspend tuşu
      HandleHibernateKey = "hibernate";       # Hibernate tuşu
     
      # Kapak davranışları (her durumda suspend - tutarlılık için)
      HandleLidSwitch = "suspend";            # Kapak kapanınca
      HandleLidSwitchDocked = "suspend";      # Dock'tayken kapak kapanınca
      HandleLidSwitchExternalPower = "suspend"; # Şarjdayken kapak kapanınca
      
      # Idle (boşta) yönetimi
      IdleAction = "ignore";                  # 30 dakika sonra eylem (ignore: hiçbir şey yapma)
      IdleActionSec = "30min";                # Idle süresi
      
      # Sistem limitleri ve optimizasyonlar
      InhibitDelayMaxSec = "5";               # Maksimum inhibit gecikmesi (hızlı suspend/shutdown)
      InhibitorsMax = "8192";                 # Maksimum inhibitor sayısı
      UserTasksMax = "33%";                   # Kullanıcı başına maksimum task (sistem kaynaklarının %33'ü)
      RuntimeDirectorySize = "50%";           # /run/user boyutu (RAM'in %50'si)
      RemoveIPC = "yes";                      # Logout'ta IPC objelerini temizle (bellek sızıntısı önleme)
    };
    
    # ----------------------------------------------------------------------------
    # JOURNALD - Sistem Günlükleri
    # SSD ömrünü korumak için optimize edilmiş
    # ----------------------------------------------------------------------------
    journald.extraConfig = ''
      SystemMaxUse=2G                         # Maksimum disk kullanımı
      SystemMaxFileSize=100M                  # Tek dosya maksimum boyutu
      MaxRetentionSec=1week                   # Maksimum saklama süresi
      MaxFileSec=1day                         # Dosya rotasyon süresi
      SyncIntervalSec=30                      # Disk'e yazma aralığı (SSD koruması)
      RateLimitIntervalSec=30                 # Rate limit penceresi
      RateLimitBurst=1000                     # Rate limit burst sayısı
      Compress=yes                            # Sıkıştırma (disk tasarrufu)
      ForwardToSyslog=no                      # Syslog'a iletme (gereksiz)
    '';
    
    # ----------------------------------------------------------------------------
    # DBUS - Sistem Mesajlaşma
    # dbus-broker: Klasik dbus'tan daha hızlı ve verimli
    # ----------------------------------------------------------------------------
    dbus = { 
      implementation = "broker";              # Modern D-Bus implementasyonu
      packages = [ pkgs.dconf ];              # GNOME/GTK uygulamaları için gerekli
    };
  };
 
  # =============================================================================
  # BOOT & KERNEL
  # =============================================================================
  boot = {
    kernelModules = [ "thinkpad_acpi" "coretemp" "intel_rapl" "msr" "kvm-intel" "i915" ];

    extraModprobeConfig = ''
      # ThinkPad ACPI – kullanıcı alanı fan kontrolü
      options thinkpad_acpi fan_control=1 brightness_mode=1 volume_mode=1 experimental=1

      # Intel P-state - HWP dynamic boost devre dışı (manuel kontrol için)
      options intel_pstate hwp_dynamic_boost=0

      # Ses güç tasarrufu - 10 saniye sonra devreye girer
      options snd_hda_intel power_save=10 power_save_controller=Y

      # Wi-Fi güç tasarrufu - maksimum verimlilik
      options iwlwifi power_save=1 power_level=3
      options iwlmvm power_scheme=3

      # USB autosuspend - 5 saniye sonra uyku moduna geçer
      options usbcore autosuspend=5

      # NVMe güç yönetimi - APST etkin
      options nvme_core default_ps_max_latency_us=5500
    '';

    kernelParams = [
      # IOMMU - virtualization ve güvenlik için
      "intel_iommu=on" "iommu=pt"

      # intel_pstate = active → governor/EPP çalışır
      #"intel_pstate=active"
      "intel_pstate=passive"

      # NVMe güç optimizasyonu
      "nvme_core.default_ps_max_latency_us=5500"  # APST için maksimum gecikme
      "nvme_core.io_timeout=30"                    # I/O timeout (varsayılan: 30)

      # i915 GPU güç optimizasyonu
      "i915.enable_guc=3"      # GuC ve HuC firmware'i etkin
      "i915.enable_fbc=1"      # Frame buffer compression
      "i915.enable_psr=1"      # Panel self refresh
      "i915.fastboot=1"        # Hızlı boot
      "i915.enable_sagv=1"     # Self-refresh aware SAGV

      # PCIe güç yönetimi
      "pcie_aspm=default"      # ASPM L0s/L1 etkin

      # Wi-Fi debug kapalı
      "iwlwifi.debug=0x0"

      # Deep suspend modu
      "mem_sleep_default=deep"
    ];

    kernel.sysctl = {
      # Bellek yönetimi - SSD ve performans dengesi
      "vm.swappiness" = 10;                   # Swap kullanımını minimize et
      "vm.vfs_cache_pressure" = 50;           # Önbellek basıncı dengeli
      "vm.dirty_writeback_centisecs" = 1500;  # Yazma gecikmesi (15 saniye)
      "vm.dirty_background_ratio" = 5;        # Arka plan yazma eşiği
      "vm.dirty_ratio" = 10;                  # Maksimum kirli sayfa oranı
      "vm.laptop_mode" = 5;                   # Laptop modu (güç tasarrufu)
      "vm.page-cluster" = 0;                  # Swap okuma önceden getirme kapalı
      "vm.compact_unevictable_allowed" = 1;   # Bellek sıkıştırma izni

      # Planlayıcı ve genel optimizasyonlar
      "kernel.nmi_watchdog" = 0;              # NMI watchdog kapalı (güç tasarrufu)
      "kernel.sched_autogroup_enabled" = 1;   # Otomatik görev gruplama
      "kernel.sched_cfs_bandwidth_slice_us" = 3000; # CFS bant genişliği dilimi
    };
  };

  # =============================================================================
  # systemd SERVİSLER – RAPL + Governor/EPP + LED + Pil eşikleri + Sleep
  # =============================================================================
  systemd.services = {
    # --------------------------------------------------------------------------
    # RAPL LIMIT + GOVERNOR/EPP AYARI
    # Timer ile gecikmeli başlatma için wantedBy kaldırıldı
    # --------------------------------------------------------------------------
    cpu-power-limit = {
      description = "Apply Intel RAPL power limits per CPU profile & power source";
      # wantedBy satırı timer tarafından kontrol edileceği için kaldırıldı
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "cpu-power-limit" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          
          # RAPL sysfs hazır olana kadar bekle
          RETRY=0
          while [[ ! -d /sys/class/powercap/intel-rapl:0 ]] && [[ $RETRY -lt 10 ]]; do
            sleep 1
            RETRY=$((RETRY + 1))
          done

          CPU_TYPE="$(${detectCpuScript})"
          RAPL="/sys/class/powercap/intel-rapl:0"
          [[ -d "$RAPL" ]] || { echo "RAPL not available after waiting"; exit 0; }

          # Güç kaynağı (AC=1 / Batarya=0)
          ON_AC=0
          for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/AC/online /sys/class/power_supply/AC0/online; do
            [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
          done

          # RAPL yazıcı
          apply_limits () {
            local PL1_W="$1" PL2_W="$2" TW1_US="$3" TW2_US="$4"
            echo $(( PL1_W * 1000000 )) > "$RAPL/constraint_0_power_limit_uw" || true
            echo $(( PL2_W * 1000000 )) > "$RAPL/constraint_1_power_limit_uw" || true
            echo "$TW1_US" > "$RAPL/constraint_0_time_window_us" || true
            echo "$TW2_US" > "$RAPL/constraint_1_time_window_us" || true
            
            # Verify
            ACTUAL_PL1=$(cat "$RAPL/constraint_0_power_limit_uw")
            ACTUAL_PL2=$(cat "$RAPL/constraint_1_power_limit_uw")
            echo "RAPL set: PL1=''${PL1_W}W PL2=''${PL2_W}W (AC=$ON_AC)"
            echo "RAPL verify: PL1=$((ACTUAL_PL1/1000000))W PL2=$((ACTUAL_PL2/1000000))W"
          }

          # Governor & EPP (intel_pstate=active)
          set_governor_epp () {
            local GOV="$1" EPP="$2" MIN="$3"
            for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
              echo "$GOV" > "$g" 2>/dev/null || true
            done
            for p in /sys/devices/system/cpu/cpufreq/policy*; do
              echo "$EPP" > "$p/energy_performance_preference" 2>/dev/null || true
              if [[ -n "$MIN" ]]; then
                echo "$MIN" > "$p/scaling_min_freq" 2>/dev/null || true
              fi
              if [[ -f "$p/cpuinfo_max_freq" ]]; then
                cat "$p/cpuinfo_max_freq" > "$p/scaling_max_freq" 2>/dev/null || true
              fi
            done
            # Turbo açık (0 = turbo enabled)
            echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
          }

          # Model + güç kaynağına göre uygula
          if [[ "$CPU_TYPE" == "meteorlake" ]]; then
            if [[ "$ON_AC" == "1" ]]; then
              apply_limits ${toString meteorLake.ac.pl1} ${toString meteorLake.ac.pl2} 28000000 10000
              set_governor_epp performance balance_performance 1600000
            else
              apply_limits ${toString meteorLake.battery.pl1} ${toString meteorLake.battery.pl2} 28000000 10000
              set_governor_epp performance balance_power 800000
            fi
          else
            if [[ "$ON_AC" == "1" ]]; then
              apply_limits ${toString kabyLakeR.ac.pl1} ${toString kabyLakeR.ac.pl2} 28000000 10000
              set_governor_epp performance balance_performance 1400000
            else
              apply_limits ${toString kabyLakeR.battery.pl1} ${toString kabyLakeR.battery.pl2} 28000000 10000
              set_governor_epp powersave power 800000
            fi
          fi

          echo "Governor/EPP applied (AC=$ON_AC, CPU=$CPU_TYPE)"
        '';
      };
    };

    # --------------------------------------------------------------------------
    # LED DURUMLARI - ThinkPad LED konfigürasyonu
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
          
          # Mikrofon mute LED'i
          if [[ -d /sys/class/leds/platform::micmute ]]; then
            echo "audio-micmute" > /sys/class/leds/platform::micmute/trigger 2>/dev/null || true
            echo 0 > /sys/class/leds/platform::micmute/brightness 2>/dev/null || true
          fi
          
          # Ses mute LED'i
          if [[ -d /sys/class/leds/platform::mute ]]; then
            echo "audio-mute" > /sys/class/leds/platform::mute/trigger 2>/dev/null || true
            echo 0 > /sys/class/leds/platform::mute/brightness 2>/dev/null || true
          fi
          
          # Kapak logosu LED'i (varsa)
          if [[ -d /sys/class/leds/tpacpi::lid_logo_dot ]]; then
            echo 0 > /sys/class/leds/tpacpi::lid_logo_dot/brightness 2>/dev/null || true
          fi
        '';
      };
    };

    # --------------------------------------------------------------------------
    # PİL ŞARJ EŞİKLERİ - Model bazlı akıllı yönetim
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
          if [[ "$CPU_TYPE" == "meteorlake" ]]; then
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
    # SLEEP HOOK'LARI: Suspend/Resume optimizasyonu
    # PRE: thinkfan'ı durdur, fanı BIOS/ACPI otomatik moda al
    # POST: thinkfan'ı geri başlat, RAPL + governor/EPP'yi yeniden uygula
    # --------------------------------------------------------------------------
    thinkfan-sleep-pre = {
      description = "Prepare fans before suspend/hibernate (stop thinkfan, set auto)";
      wantedBy = [ "sleep.target" ];
      before   = [ "sleep.target" ];
      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "thinkfan-sleep-pre" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          
          # thinkfan'ı durdur (varsa)
          ${pkgs.systemd}/bin/systemctl stop thinkfan.service 2>/dev/null || true
          
          # fanı ACPI otomatik moda al
          if [[ -w /proc/acpi/ibm/fan ]]; then
            echo "level auto" > /proc/acpi/ibm/fan 2>/dev/null || true
            echo "Fan set to auto mode for suspend"
          fi
          
          # Intel P-state: turbo kapat (s2idle'da gereksiz boost'ları önler)
          echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
        '';
      };
    };

    thinkfan-sleep-post = {
      description = "Restore fans after resume (start thinkfan, reapply RAPL/governor)";
      wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
      after    = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "thinkfan-sleep-post" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          
          # Turbo geri aç
          echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
          
          # RAPL + governor/EPP ayarlarını tekrar uygula
          ${pkgs.systemd}/bin/systemctl restart cpu-power-limit.service 2>/dev/null || true
          
          # thinkfan'ı geri başlat
          if ${pkgs.systemd}/bin/systemctl is-enabled thinkfan.service >/dev/null 2>&1; then
            ${pkgs.systemd}/bin/systemctl restart thinkfan.service || true
            echo "Thinkfan service restarted after resume"
          fi
        '';
      };
    };
  };

  # =============================================================================
  # systemd TIMERS – Boot sonrası gecikmeli RAPL uygulaması
  # =============================================================================
  systemd.timers.cpu-power-limit = {
    description = "Timer for CPU power limit application";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "5min";  # Her 5 dakikada bir tekrarla
      Persistent = true;
    };
  };

  # =============================================================================
  # UDEV KURALLARI – AC değişiminde RAPL/governor'i uygula
  # =============================================================================
  services.udev.extraRules = lib.mkAfter ''
    # LED erişim izinleri
    SUBSYSTEM=="leds", KERNEL=="platform::micmute", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 664 /sys/class/leds/%k/brightness"
    SUBSYSTEM=="leds", KERNEL=="platform::mute",    ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 664 /sys/class/leds/%k/brightness"

    # USB güç yönetimi - varsayılan auto, HID cihazlar hariç
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usbhid", ATTR{power/control}="on"

    # AC adaptör online/offline → cpu-power-limit koşsun
    SUBSYSTEM=="power_supply", KERNEL=="AC*", ACTION=="change", RUN+="${systemctl} restart cpu-power-limit.service"
  '';

  # =============================================================================
  # ORTAM & ARAÇLAR
  # =============================================================================
  environment = {
    systemPackages = with pkgs; [ 
      lm_sensors 
      powertop 
      intel-gpu-tools 
      bc  # Hesaplamalar için
    ];

    shellAliases = {
      # Pil durumu ve bilgileri
      battery-status = "upower -i /org/freedesktop/UPower/devices/battery_BAT0";
      battery-info = ''
        echo "=== Battery Status ===" && \
        upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "state|percentage|time to|capacity" && \
        echo -e "\n=== Charge Thresholds ===" && \
        echo "Start: $(cat /sys/class/power_supply/BAT0/charge_control_start_threshold 2>/dev/null || echo 'N/A')%" && \
        echo "Stop:  $(cat /sys/class/power_supply/BAT0/charge_control_end_threshold   2>/dev/null || echo 'N/A')%"
      '';

      # Güç yönetimi
      power-report = "sudo powertop --html=power-report-$(date +%Y%m%d-%H%M).html --time=10 && echo 'Power report saved'";
      power-usage  = "sudo powertop";
      fix-power = "sudo systemctl restart cpu-power-limit && echo 'Power limits reapplied'";

      # Termal durum
      thermal-status = ''
        echo "=== Thermal Status ===" && \
        sensors 2>/dev/null || echo "lm-sensors not available" && \
        echo && \
        echo "=== ACPI Thermal ===" && \
        cat /proc/acpi/ibm/thermal 2>/dev/null || echo "ThinkPad ACPI thermal not available" && \
        echo && \
        echo "=== Thermal Zones ===" && \
        for z in /sys/class/thermal/thermal_zone*/temp; do \
          [[ -r "$z" ]] || continue; \
          t=$(cat "$z"); \
          printf "%s: %s°C\n" "$(basename "$(dirname "$z")")" "$((t/1000))"; \
        done
      '';

      # CPU durum
      cpu-freq = ''
        echo "=== CPU Frequency ===" && \
        grep "cpu MHz" /proc/cpuinfo | awk '{print "Core " NR-1 ": " $4 " MHz"}' && \
        echo && \
        echo "=== Governor ===" && \
        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true && \
        echo && \
        echo "=== EPP ===" && \
        cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null || true
      '';

      cpu-type = "${detectCpuScript}";

      # Performans özeti
      perf-summary = ''
        echo "=== System Performance ===" && \
        echo "CPU: $(${detectCpuScript})" && \
        echo "Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)" && \
        echo "EPP: $(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null || echo 'N/A')" && \
        echo "Memory: $(free -h | awk "/^Mem:/ {print \$3 \" / \" \$2}")" && \
        echo "Load: $(uptime | awk -F'load average:' '{print $2}')" && \
        echo && \
        echo "=== Power Limits ===" && \
        PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0) && \
        PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0) && \
        echo "PL1: $((PL1/1000000))W" && \
        echo "PL2: $((PL2/1000000))W"
      '';
    };

    variables = {
      VDPAU_DRIVER = "va_gl";
      LIBVA_DRIVER_NAME = "iHD";
    };

    # fancontrol kullanılmıyor (thinkfan kullanıyoruz)
    etc.fancontrol.enable = false;
  };

  # =============================================================================
  # ZRAM - Dinamik bellek sıkıştırma
  # =============================================================================
  zramSwap = {
    enable = true;
    priority = 5000;
    algorithm = "zstd";
    memoryPercent = lib.mkDefault 30;
  };
}

