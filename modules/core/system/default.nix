# modules/core/system/default.nix
# ==============================================================================
# NixOS Sistem Yapılandırması - Temel Sistem, Boot, Donanım ve Güç Yönetimi
# ==============================================================================
#
# Bu modül tek bir dosyada:
#  - Temel sistem ve boot ayarları,
#  - Donanım hızlandırma,
#  - Akıllı güç yönetimi (TLP + HWP/EPP),
#  - RAPL (eski Intel'de nazikçe PL1/PL2; Meteor Lake ve üstünde otomatik bypass),
#  - ThinkPad termal/fan/batarya eşikleri,
#  - AC/DC ve suspend/resume tetikleyicileri,
#  - "Aynı hostname ile iki farklı donanım" durumunda **runtime** CPU algılayıp
#    EPP/min_perf'i doğru sete çekecek servis,
#  - VM için gereksiz ajanları (host'ta) kapatmayı
# bir araya getirir.
#
# DESTEK:
# - ThinkPad X1 Carbon 6th (i7-8650U, Kaby Lake-R, 15W TDP)  → RAPL faydalı
# - ThinkPad E14 Gen 6 (Core Ultra 7 155H, Meteor Lake, 28W) → native PM yeterli; RAPL'i atla
# - Sanal makine (hostname: "vhay")
#
# Tasarım Notları:
# - TLP, auto-cpufreq ve power-profiles-daemon ile çakışır → ikincisi devre dışı.
# - i915'de PSR/FBC/SAGV sorun çıkardığı için kapalı (stabilite/tearing).
# - iGPU frekanslarını TLP ile **zorlamıyoruz** (modern kernel'de bu knob'lar ya yok ya da
#   anlamsız; log kirliliği yaratıyor).
# - RAPL servisinde **timer** kullanarak boot ordering döngülerini kırdık.
# - İki fiziksel makine **aynı hostname** kullandığı için ayrımı **boot zamanı** CPU model
#   algısıyla yapıyoruz (EPP & min_perf otomasyonu).
#
# Author: Kenan Pelit
# Version: 2.3
# Last Updated: 2025-01-04
# ==============================================================================

{ pkgs, config, lib, inputs, system, ... }:

let
  hostname          = config.networking.hostName or "";
  isPhysicalMachine = hostname == "hay";   # her iki gerçek ThinkPad de "hay"
  isVirtualMachine  = hostname == "vhay";  # sanal makine ise "vhay"
in
{
  # =============================================================================
  # BASE SYSTEM
  # =============================================================================

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
    };
  };

  # Türkçe F klavye + CapsLock -> Ctrl
  services.xserver.xkb = {
    layout  = "tr";
    variant = "f";
    options = "ctrl:nocaps";
  };
  console.keyMap = "trf";

  # Yükseltmelerde uyumluluk için sistem sürüm kilidi
  system.stateVersion = "25.11";

  # =============================================================================
  # BOOT (GRUB + Kernel)
  # =============================================================================
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    # Not: "intel_rapl" modülünü özellikle eklemiyoruz (bazı çekirdeklerde
    # ayrı modül değil; yoksa "Failed to find module 'intel_rapl'" uyarısı olur).
    kernelModules =
      [ "coretemp" "i915" ]
      ++ lib.optionals isPhysicalMachine [ "thinkpad_acpi" ];

    extraModprobeConfig = ''
      # Intel P-State: HWP dynamic boost
      options intel_pstate hwp_dynamic_boost=1

      # Ses güç tasarrufu
      options snd_hda_intel power_save=10 power_save_controller=Y

      # Wi-Fi güç ayarı (bataryada tasarruf)
      options iwlwifi power_save=1 power_level=3

      # USB autosuspend (saniye)
      options usbcore autosuspend=5

      # NVMe güç yönetimi: maksimum kabul edilebilir latency
      options nvme_core default_ps_max_latency_us=5500

      ${lib.optionalString isPhysicalMachine ''
        # ThinkPad ACPI: fan kontrolü/batarya
        options thinkpad_acpi fan_control=1 experimental=1
      ''}
    '';

    # i915 stabilite/tearing için PSR/FBC/SAGV kapalı; HWP boost açık
    kernelParams = [
      "intel_pstate=active"
      "intel_pstate.hwp_dynamic_boost=1"
      "pcie_aspm=default"
      "i915.enable_guc=3"
      "i915.enable_fbc=0"
      "i915.enable_psr=0"
      "i915.enable_sagv=1"
      "mem_sleep_default=deep"            # FW destekliyorsa deep; değilse s2idle kalır
      "nvme_core.default_ps_max_latency_us=5500"
    ];

    # Hafif sysctl'ler (VM/sunucu değil, dizüstü optimizasyonları)
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_writeback_centisecs" = 1500;
      "kernel.nmi_watchdog" = 0;
    };

    loader = {
      grub = {
        enable = true;
        # VM'de gerçek disk cihazına yaz; fizikselde NixOS varsayılanı (nodev/EFI)
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

  # =============================================================================
  # HARDWARE
  # =============================================================================
  hardware = {
    trackpoint = lib.mkIf isPhysicalMachine {
      enable = true;
      speed = 200;
      sensitivity = 200;
      emulateWheel = true;
    };

    # Intel iGPU + medya + compute
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
    enableAllFirmware             = true;
    cpu.intel.updateMicrocode     = true;
    bluetooth.enable              = true;
  };

  # =============================================================================
  # POWER MANAGEMENT (TLP + HWP/EPP)
  # =============================================================================
  services.auto-cpufreq.enable          = false; # TLP ile çakışır
  services.power-profiles-daemon.enable = false; # TLP ile çakışır

  services.tlp = lib.mkIf isPhysicalMachine {
    enable = true;
    settings = {
      # Varsayılan mod: AC (kalıcı değil; AC/BAT olaylarıyla otomatik geçsin)
      TLP_DEFAULT_MODE       = "AC";
      TLP_PERSISTENT_DEFAULT = 0;

      # HWP aktif: AC'de performance, BAT'ta powersave governoru
      CPU_DRIVER_OPMODE           = "active";
      CPU_SCALING_GOVERNOR_ON_AC  = "performance";
      #CPU_SCALING_GOVERNOR_ON_AC  = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # "Taban konfor": AC'de minimum 1.0 GHz. (1.2GHz daha sıcak, 0.8 bazı işte gecikme yaratır)
      CPU_SCALING_MIN_FREQ_ON_AC  = 1000000;
      CPU_SCALING_MAX_FREQ_ON_AC  = 4500000;

      # BAT'ta min freq ZORLAMIYORUZ → HWP/EPP serbestçe düşürsün.
      # CPU_SCALING_MIN_FREQ_ON_BAT = 800000;   # ← bilinçli olarak kapalı
      CPU_SCALING_MAX_FREQ_ON_BAT  = 3500000;

      # HWP min perf yüzdeleri (intel_pstate/min_perf_pct):
      # AC: 20–100 → akıcı & ısı kontrollü; BAT: 10–80 → tasarruf
      CPU_MIN_PERF_ON_AC = 35;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 10;
      CPU_MAX_PERF_ON_BAT = 80;

      # EPP (Energy Performance Preference):
      # AC'de "balance_performance" → MTL'de serin, X1C6'da da akıcı.
      # X1C6 için daha atak istiyorsan runtime servis bunu "performance" yapacak (aşağıda).
      #CPU_ENERGY_PERF_POLICY_ON_AC  = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_AC  = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

      # HWP dinamik boost: AC'de açık; BAT'ta kapalı
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;

      # Turbo: AC'de açık; BAT'ta cihaz karar versin
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = "auto";

      # Platform profili (FW destekliyorsa)
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "balanced";

      # ÖNEMLİ: iGPU frekanslarını TLP ile ZORLAMIYORUZ → modern i915'de gereksiz/hatalı.
      # INTEL_GPU_* anahtarları kasıtlı olarak yok.

      # PCIe ASPM
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";

      # Runtime PM
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";
      RUNTIME_PM_DRIVER_DENYLIST = "nouveau radeon";

      # USB autosuspend istisnaları (örnek vid:pid eklendi)
      USB_AUTOSUSPEND     = 1;
      USB_DENYLIST        = "17ef:6047";
      USB_EXCLUDE_AUDIO   = 1;
      USB_EXCLUDE_BTUSB   = 0;
      USB_EXCLUDE_PHONE   = 1;
      USB_EXCLUDE_PRINTER = 1;
      USB_EXCLUDE_WWAN    = 0;

      # ThinkPad batarya eşikleri (ömür için %75–80 bandı)
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0  = 80;
      START_CHARGE_THRESH_BAT1 = 75;
      STOP_CHARGE_THRESH_BAT1  = 80;
      RESTORE_THRESHOLDS_ON_BAT = 1;

      # Disk güç yönetimi
      DISK_IDLE_SECS_ON_AC = 0;
      DISK_IDLE_SECS_ON_BAT = 2;
      MAX_LOST_WORK_SECS_ON_AC = 15;
      MAX_LOST_WORK_SECS_ON_BAT = 60;
      DISK_APM_LEVEL_ON_AC = "255";
      DISK_APM_LEVEL_ON_BAT = "128";
      DISK_APM_CLASS_DENYLIST = "usb ieee1394";
      DISK_IOSCHED = "mq-deadline";

      # SATA link pwr
      SATA_LINKPWR_ON_AC = "max_performance";
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm";

      # Wi-Fi & WOL
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
      WOL_DISABLE = "Y";

      # Ses güç tasarrufu
      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 10;
      SOUND_POWER_SAVE_CONTROLLER = "Y";

      # Radyo cihazları
      DEVICES_TO_DISABLE_ON_STARTUP = "";
      DEVICES_TO_ENABLE_ON_STARTUP  = "bluetooth wifi";
      DEVICES_TO_DISABLE_ON_SHUTDOWN = "";
      DEVICES_TO_ENABLE_ON_AC = "bluetooth wifi wwan";
      DEVICES_TO_DISABLE_ON_BAT = "";
      DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "wwan";
    };
  };

  # =============================================================================
  # SYSTEM SERVICES
  # =============================================================================
  services = {
    thermald.enable = true; # Intel termal sürücüleriyle uyumlu; hotspotları yumuşatır
    upower.enable   = true; # GUI/CLI araçları için batarya/enerji raporu

    # ThinkFan: sade 5 kademeli eğri (ThinkPad ACPI fan arayüzü ile)
    thinkfan = lib.mkIf isPhysicalMachine {
      enable = true;
      levels = [
        [ "level auto"        0  58 ]
        [ 1                  58  68 ]
        [ 3                  68  78 ]
        [ 7                  78  88 ]
        [ "level full-speed" 88 32767 ]
      ];
    };

    # Lid/tuş davranışları
    logind.settings.Login = {
      HandleLidSwitch              = "suspend";
      HandleLidSwitchDocked        = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandlePowerKey               = "ignore";
      HandlePowerKeyLongPress      = "poweroff";
      HandleSuspendKey             = "suspend";
      HandleHibernateKey           = "hibernate";
    };

    # SPICE guest agent yalnızca VM'de (host'ta gereksiz/hata üretir)
    spice-vdagentd.enable = lib.mkIf isVirtualMachine true;
    #spice-vdagentd.enable = lib.mkForce false;
  };

  ## =============================================================================
  ## Lid/tuş davranışları → systemd settings arayüzü (TOP-LEVEL!)
  ## =============================================================================

  ## Lid/tuş davranışları → systemd settings arayüzü
  #systemd.settings.logind = {
  #  Login = {
  #    HandleLidSwitch              = "suspend";
  #    HandleLidSwitchDocked        = "suspend";
  #    HandleLidSwitchExternalPower = "suspend";
  #    HandlePowerKey               = "ignore";
  #    HandlePowerKeyLongPress      = "poweroff";
  #    HandleSuspendKey             = "suspend";
  #    HandleHibernateKey           = "hibernate";
  #  };
  #};

  # =============================================================================
  # RAPL POWER LIMITS (X1C6'da anlamlı; Meteor Lake'te BYPASS)
  # =============================================================================
  # Notlar:
  # - Servis TIMER ile tetiklenir → boot ordering döngüsü yok.
  # - Meteor/Arrow/Lunar Lake ve "Core Ultra" algılanırsa RAPL "skip". # ignore
  # - X1C6 gibi U-serisi CPU'da AC: PL1=25W/PL2=35W, BAT: PL1=15W/PL2=25W.
  systemd.services.rapl-power-limits = lib.mkIf isPhysicalMachine {
    description = "Apply RAPL power limits for Intel CPUs";
    after = [ "tlp.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "set-rapl-limits" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail

        CPU_MODEL="$(${pkgs.util-linux}/bin/lscpu \
          | ${pkgs.gnugrep}/bin/grep -F 'Model name' \
          | ${pkgs.coreutils}/bin/cut -d: -f2- \
          | ${pkgs.coreutils}/bin/tr -d '\n' \
          | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

        # Modern Intel için makul limitler (Meteor Lake vb.)
        if echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Core\(TM\) Ultra|Meteor Lake|Arrow Lake|Lunar Lake'; then
          echo "RAPL: Meteor Lake detected, applying conservative limits for '$CPU_MODEL'"
          
          # AC mi kontrol et
          ON_AC=0
          for PS in /sys/class/power_supply/A{C,DP}*/online; do
            [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && [[ "$ON_AC" == "1" ]] && break
          done
          
          if [[ "$ON_AC" == "1" ]]; then
            PL1_W=28; PL2_W=35  # E14 TDP'sine uygun
          else
            PL1_W=20; PL2_W=28  # Bataryada konservatif
          fi
          
          # RAPL uygula ve çık
          for R in /sys/class/powercap/intel-rapl:*; do
            [[ -d "$R" ]] || continue
            [[ -w "$R/constraint_0_power_limit_uw" ]] && echo $(( PL1_W * 1000000 )) > "$R/constraint_0_power_limit_uw" 2>/dev/null || true
            [[ -w "$R/constraint_1_power_limit_uw" ]] && echo $(( PL2_W * 1000000 )) > "$R/constraint_1_power_limit_uw" 2>/dev/null || true
          done
          
          echo "RAPL applied for Meteor Lake (PL1=''${PL1_W}W PL2=''${PL2_W}W; AC=''${ON_AC})."
          exit 0
        fi

        # powercap/rapl var mı?
        shopt -s nullglob
        have_rapl=0
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] && have_rapl=1 && break
        done
        if [[ "$have_rapl" -eq 0 ]]; then
          echo "RAPL: no powercap interface; skipping."
          exit 0
        fi

        # AC mi? (eski CPU'lar için)
        ON_AC=0
        for PS in /sys/class/power_supply/A{C,DP}*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && [[ "$ON_AC" == "1" ]] && break
        done

        if [[ "$ON_AC" == "1" ]]; then
          PL1_W=25; PL2_W=35  # X1C6 gibi eski CPU'lar için AC değerleri
        else
          PL1_W=15; PL2_W=25  # X1C6 gibi eski CPU'lar için BAT değerleri
        fi

        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          [[ -w "$R/constraint_0_power_limit_uw"  ]] && echo $(( PL1_W * 1000000 )) > "$R/constraint_0_power_limit_uw"  2>/dev/null || true
          [[ -w "$R/constraint_0_time_window_us"  ]] && echo 28000000 > "$R/constraint_0_time_window_us" 2>/dev/null || true
          [[ -w "$R/constraint_1_power_limit_uw"  ]] && echo $(( PL2_W * 1000000 )) > "$R/constraint_1_power_limit_uw"  2>/dev/null || true
          [[ -w "$R/constraint_1_time_window_us"  ]] && echo 2440000  > "$R/constraint_1_time_window_us" 2>/dev/null || true
        done

        echo "RAPL applied (PL1=''${PL1_W}W PL2=''${PL2_W}W; AC=''${ON_AC})."
      '';
    };
  };

  systemd.timers.rapl-power-limits = lib.mkIf isPhysicalMachine {
    description = "Timer: apply RAPL power limits shortly after boot";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec  = "45s";   # TLP/thermald otursun, sonra uygula
      Persistent = true;
    };
  };

  systemd.services.rapl-power-limits-resume = lib.mkIf isPhysicalMachine {
    description = "Re-apply RAPL limits after resume";
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    after    = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl start rapl-power-limits.service";
    };
  };

  # =============================================================================
  # CPU-EPP/MIN_PERF OTOMATİĞİ (aynı hostname ile iki farklı donanım için)
  # =============================================================================
  # - Meteor Lake (Core Ultra 7 155H) → EPP=balance_performance, min_perf=20
  # - X1C6 (i7-8650U ve benzeri U-serisi) → EPP=performance, min_perf=25
  systemd.services.cpu-epp-autotune = lib.mkIf isPhysicalMachine {
    description = "CPU modeline gore EPP ve min_perf ayarla";
    after = [ "tlp.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "cpu-epp-autotune" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail

        CPU_MODEL="$(${pkgs.util-linux}/bin/lscpu \
          | ${pkgs.gnugrep}/bin/grep -F 'Model name' \
          | ${pkgs.coreutils}/bin/cut -d: -f2- \
          | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

        # Varsayilan (modern CPU'lar icin)
        EPP_ON_AC="balance_performance"
        MIN_PERF=25

        # Güç kaynağı
        ON_AC=0
        for PS in /sys/class/power_supply/A{C,DP}*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && [[ "$ON_AC" == "1" ]] && break
        done
  
        if [[ "$ON_AC" == "1" ]]; then
          MIN_PERF=30
        else
          MIN_PERF=10
        fi

        # X1C6 / Kaby/Whiskey/Coffee U serisi ise AC'de daha atak
        if echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE '8650U|8550U|8350U|8250U|Kaby|Whiskey|Coffee'; then
          EPP_ON_AC="performance"
        fi

        # *** MTL / Core Ultra ailesi icin: AC'de tam performans + %35 taban ***
        if echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Core\(TM\) Ultra|Meteor Lake|Lunar Lake|Arrow Lake'; then
          if [[ "$ON_AC" == "1" ]]; then
            EPP_ON_AC="performance"
            MIN_PERF=35
          fi
        fi

        # EPP'yi tüm policy*'lere uygula
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$pol/energy_performance_preference" ]] && \
            echo "$EPP_ON_AC" > "$pol/energy_performance_preference" 2>/dev/null || true
        done

        # intel_pstate HWP min perf
        if [[ -w /sys/devices/system/cpu/intel_pstate/min_perf_pct ]]; then
          echo "$MIN_PERF" > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || true
        fi

        echo "cpu-epp-autotune: CPU='$CPU_MODEL' (AC=$ON_AC) -> EPP='$EPP_ON_AC', min_perf_pct='$MIN_PERF'"
      '';
    };
  };

  systemd.timers.cpu-epp-autotune = lib.mkIf isPhysicalMachine {
    description = "Timer: EPP/min_perf uygula (TLP sonrasi)";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      Persistent = true;
      Unit = "cpu-epp-autotune.service";
    };
  };

  systemd.services.cpu-epp-autotune-resume = lib.mkIf isPhysicalMachine {
    description = "Resume sonrasi EPP/min_perf yeniden uygula";
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    after    = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl start cpu-epp-autotune.service";
    };
  };

  # =============================================================================
  # UDEV RULES (AC/DC degisimi tetikleyicileri)
  # =============================================================================
  services.udev.extraRules = lib.mkIf isPhysicalMachine ''
    # AC/DC değişince RAPL ve CPU-EPP otomatik yeniden uygulansın
    SUBSYSTEM=="power_supply", KERNEL=="A{C,DP}*", ACTION=="change", \
      RUN+="${pkgs.systemd}/bin/systemctl start rapl-power-limits.service"
    SUBSYSTEM=="power_supply", KERNEL=="A{C,DP}*", ACTION=="change", \
      RUN+="${pkgs.systemd}/bin/systemctl start cpu-epp-autotune.service"
  '';

  # =============================================================================
  # THINKPAD YARDIMCILARI (LED/fan, suspend düzeltmeleri)
  # =============================================================================
  systemd.services.thinkpad-led-fix = lib.mkIf isPhysicalMachine {
    description = "Turn off ThinkPad mute LEDs";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "disable-mute-leds" ''
        #!${pkgs.bash}/bin/bash
        for led in /sys/class/leds/platform::{mute,micmute}/brightness; do
          [[ -w "$led" ]] && echo 0 > "$led" 2>/dev/null || true
        done
      '';
    };
  };

  systemd.services.thinkpad-led-fix-resume = lib.mkIf isPhysicalMachine {
    description = "Turn off ThinkPad mute LEDs after resume";
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    after    = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "disable-mute-leds-resume" ''
        #!${pkgs.bash}/bin/bash
        for led in /sys/class/leds/platform::{mute,micmute}/brightness; do
          [[ -w "$led" ]] && echo 0 > "$led" 2>/dev/null || true
        done
      '';
    };
  };

  systemd.services.suspend-pre-fan = lib.mkIf isPhysicalMachine {
    description = "Stop thinkfan before suspend";
    wantedBy = [ "sleep.target" ];
    before   = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "suspend-pre-fan" ''
        #!${pkgs.bash}/bin/bash
        ${pkgs.systemd}/bin/systemctl stop thinkfan.service 2>/dev/null || true
        [[ -w /proc/acpi/ibm/fan ]] && echo "level auto" > /proc/acpi/ibm/fan 2>/dev/null || true
      '';
    };
  };

  systemd.services.resume-post-fan = lib.mkIf isPhysicalMachine {
    description = "Restart thinkfan after resume";
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    after    = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "resume-post-fan" ''
        #!${pkgs.bash}/bin/bash
        sleep 1
        if ${pkgs.systemd}/bin/systemctl is-enabled thinkfan.service >/dev/null 2>&1; then
          ${pkgs.systemd}/bin/systemctl restart thinkfan.service 2>/dev/null || true
        else
          [[ -w /proc/acpi/ibm/fan ]] && echo "level auto" > /proc/acpi/ibm/fan 2>/dev/null || true
        fi
      '';
    };
  };

  # Eski ad-hoc sleep/wakeup servislerini kapat (temizlik)
  systemd.services.thinkfan-sleep  = lib.mkIf isPhysicalMachine { enable = lib.mkForce false; wantedBy = lib.mkForce [ ]; };
  systemd.services.thinkfan-wakeup = lib.mkIf isPhysicalMachine { enable = lib.mkForce false; wantedBy = lib.mkForce [ ]; };

  # =============================================================================
  # USER-FACING YARDIMCI KOMUTLAR
  # =============================================================================
  environment.systemPackages = with pkgs;
    lib.optionals isPhysicalMachine [
      tlp

      # Hızlı profil geçişleri (TLP + HWP/EPP odaklı)
      (writeScriptBin "performance-mode" ''
        #!${bash}/bin/bash
        set -e
        echo "🚀 Performance mode (HWP)…"
        sudo ${tlp}/bin/tlp ac

        # EPP=performance, min_perf_pct=30 → daha atak
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$pol/energy_performance_preference" ]] && \
            echo performance | sudo tee "$pol/energy_performance_preference" >/dev/null || true
        done
        [[ -w /sys/devices/system/cpu/intel_pstate/min_perf_pct ]] && \
          echo 30 | sudo tee /sys/devices/system/cpu/intel_pstate/min_perf_pct >/dev/null || true

        # Turbo açık kalsın (intel_pstate/no_turbo=0)
        [[ -w /sys/devices/system/cpu/intel_pstate/no_turbo ]] && \
          echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null || true

        sudo ${pkgs.systemd}/bin/systemctl start cpu-epp-autotune.service || true
        echo "✅ Done!"
      '')

      (writeScriptBin "balanced-mode" ''
        #!${bash}/bin/bash
        set -e
        echo "⚖️ Balanced mode (HWP)…"
        sudo ${tlp}/bin/tlp start

        # EPP=balance_performance, min_perf_pct=25 → “sessiz ama anında tepki”
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$pol/energy_performance_preference" ]] && \
            echo balance_performance | sudo tee "$pol/energy_performance_preference" >/dev/null || true
        done
        [[ -w /sys/devices/system/cpu/intel_pstate/min_perf_pct ]] && \
          echo 25 | sudo tee /sys/devices/system/cpu/intel_pstate/min_perf_pct >/dev/null || true

        sudo ${pkgs.systemd}/bin/systemctl start cpu-epp-autotune.service || true
        echo "✅ Done!"
      '')

      (writeScriptBin "eco-mode" ''
        #!${bash}/bin/bash
        set -e
        echo "🍃 Eco mode (HWP)…"
        sudo ${tlp}/bin/tlp bat

        # EPP=balance_power, min_perf_pct=10 → pil odağı
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$pol/energy_performance_preference" ]] && \
            echo balance_power | sudo tee "$pol/energy_performance_preference" >/dev/null || true
        done
        [[ -w /sys/devices/system/cpu/intel_pstate/min_perf_pct ]] && \
          echo 10 | sudo tee /sys/devices/system/cpu/intel_pstate/min_perf_pct >/dev/null || true

        echo "✅ Done!"
      '')

      (writeScriptBin "power-status" ''
        #!${bash}/bin/bash
        echo "==== Power Status ===="
        sudo ${tlp}/bin/tlp-stat -s -c -p | head -40
      '')

      # Küçük durum aracı: osc-perf-mode (status|perf|bal|eco)
      (writeScriptBin "osc-perf-mode" ''
        #!${bash}/bin/bash
        set -euo pipefail
        if [ $# -ge 1 ]; then
          cmd="$1"
        else
          cmd="status"
        fi

        show_status() {
          CPU_TYPE="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'Model name' | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
          GOV="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo n/a)"
          EPP="$(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null || echo n/a)"
          TURBO="$(cat /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null | ${pkgs.coreutils}/bin/tr '01' 'OffOn' || echo n/a)"
          MEMS="$(cat /sys/power/mem_sleep 2>/dev/null || echo n/a)"
          PWR="BAT"; for PS in /sys/class/power_supply/A{C,DP}*/online; do [ -f "$PS" ] && [ "$(cat "$PS")" = "1" ] && PWR="AC" && break; done
          TEMP="$( ${pkgs.lm_sensors}/bin/sensors 2>/dev/null | ${pkgs.gnugrep}/bin/grep -m1 -E 'Package id 0|Tctl' | ${pkgs.gawk}/bin/awk '{print $3}' || echo n/a)"

          echo "=== Current System Status ==="
          echo "CPU: $CPU_TYPE"
          echo "Power Source: $PWR"
          echo "Governor: $GOV"
          echo "EPP: $EPP"
          echo "Turbo: $TURBO"
          echo "mem_sleep: $MEMS"
          echo
          echo "CPU Frequencies:"
          for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
            [ -f "$f" ] || continue
            cpu="$(basename "$(dirname "$f")")"
            mhz="$(( $(cat "$f") / 1000 ))"
            printf "  %-5s: %s MHz\n" "$cpu" "$mhz"
          done | head -n 16
          echo
          if [ -d /sys/class/powercap/intel-rapl:0 ]; then
            pl1="$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0)"
            pl2="$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0)"
            [ "$pl1" != "0" ] && echo "PL1: $((pl1/1000000))W"
            [ "$pl2" != "0" ] && echo "PL2: $((pl2/1000000))W"
          fi
          echo
          echo "CPU Temp: $TEMP"
          if [ -r /sys/class/power_supply/BAT0/charge_control_start_threshold ]; then
            s=$(cat /sys/class/power_supply/BAT0/charge_control_start_threshold)
            e=$(cat /sys/class/power_supply/BAT0/charge_control_end_threshold)
            echo "Battery Thresholds: Start: ''${s}% | Stop: ''${e}%"
          fi
        }

        case "$cmd" in
          status) show_status ;;
          perf)   performance-mode ;;
          bal)    balanced-mode ;;
          eco)    eco-mode ;;
          *) echo "usage: osc-perf-mode {status|perf|bal|eco}" ; exit 2 ;;
        esac
      '')
    ];
}
