# modules/core/system/default.nix
# ==============================================================================
# NixOS Sistem Yapılandırması - Temel Sistem, Boot, Donanım ve Güç Yönetimi
# ==============================================================================
#
# Bu modül, geleneksel olarak ayrı dosyalarda tutulan sistem bileşenlerini tek
# bir bütünleşik yapıda toplar. Temel sistem servisleri, önyükleme süreci,
# donanım desteği ve gelişmiş güç yönetimini kapsamlı şekilde yönetir.
#
# DESTEKLENEN DONANIM:
# - ThinkPad X1 Carbon 6th Gen (Intel Core i7-8650U, Kaby Lake-R, 15W TDP)
#   → Ultra-taşınabilir; RAPL limitleri faydalı.
# - ThinkPad E14 Gen 6 (Intel Core Ultra 7 155H, Meteor Lake, 28W TDP)
#   → Modern mimari; native güç yönetimi iyi, RAPL’e gerek yok (bypass).
# - Sanal Makineler (hostname “vhay” ile tespit)
#
# Öne Çıkanlar:
# 1) Akıllı güç yönetimi (TLP + HWP/EPP + platform profilleri)
# 2) X1C6 için RAPL limitleri; Meteor Lake’te otomatik “skip”
# 3) ThinkFan tabanlı termal yönetim + suspend/resume yardımcıları
# 4) i915 için stabil kernel parametreleri (PSR/FBC/SAGV kapalı)
# 5) GRUB teması, mikrocode ve donanım hızlandırma paketleri
#
# Notlar:
# - TLP; auto-cpufreq ve power-profiles-daemon ile çakıştığı için ikisi devre dışı.
# - RAPL, modern Intel (Core Ultra/Meteor Lake ve sonrası) için anlamlı değil → skip.
# - SPICE guest agent yalnızca VM’de açık (host’ta gereksiz log kirliliğini keser).
#
# Author: Kenan Pelit
# Version: 2.1
# Last Updated: 2025-09-04
# ==============================================================================

{ pkgs, config, lib, inputs, system, ... }:

let
  hostname = config.networking.hostName or "";
  # hay = fiziksel ThinkPad, vhay = sanal makine
  isPhysicalMachine = hostname == "hay";
  isVirtualMachine  = hostname == "vhay";
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

  # Türkçe F klavye düzeni + Caps Lock → Ctrl
  services.xserver.xkb = {
    layout  = "tr";
    variant = "f";
    options = "ctrl:nocaps";
  };
  console.keyMap = "trf";

  # Sistem sürüm kilidi (yükseltmelerde uyum için)
  system.stateVersion = "25.11";

  # =============================================================================
  # BOOT (GRUB + Kernel)
  # =============================================================================
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    # Yükletilecek modüller:
    # - intel_rapl’ı BİLEREK eklemiyoruz → bazı kernel’lerde yok/gömülü; uyarıyı kes.
    kernelModules =
      [ "coretemp" "i915" ]
      ++ lib.optionals isPhysicalMachine [ "thinkpad_acpi" ];

    # Modprobe seçenekleri: HWP boost, NVMe latency sınırı, vb.
    extraModprobeConfig = ''
      # Intel P-State: HWP dynamic boost
      options intel_pstate hwp_dynamic_boost=1

      # Ses güç tasarrufu
      options snd_hda_intel power_save=10 power_save_controller=Y

      # Wi-Fi güç optimizasyonu
      options iwlwifi power_save=1 power_level=3

      # USB autosuspend (saniye)
      options usbcore autosuspend=5

      # NVMe güç yönetimi (maks. latency)
      options nvme_core default_ps_max_latency_us=5500

      ${lib.optionalString isPhysicalMachine ''
        # ThinkPad ACPI: fan kontrolü/batarya
        options thinkpad_acpi fan_control=1 experimental=1
      ''}
    '';

    # Kernel parametreleri: i915 stabilite ve güç ayarları
    kernelParams = [
      "intel_pstate=active"
      "intel_pstate.hwp_dynamic_boost=1"
      "pcie_aspm=default"
      "i915.enable_guc=3"
      "i915.enable_fbc=0"
      "i915.enable_psr=0"
      "i915.enable_sagv=0"
      "mem_sleep_default=deep"
      "nvme_core.default_ps_max_latency_us=5500"
    ];

    # Hafif kernel sysctl’leri
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_writeback_centisecs" = 1500;
      "kernel.nmi_watchdog" = 0;
    };

    # GRUB: host/VM cihaz farkı + tema
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

    # Donanım hızlandırma paketleri (Intel iGPU + medya + compute)
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
  # POWER MANAGEMENT (TLP)
  # =============================================================================
  services.auto-cpufreq.enable           = false; # TLP ile çakışır
  services.power-profiles-daemon.enable  = false; # TLP ile çakışır

  services.tlp = lib.mkIf isPhysicalMachine {
    enable = true;
    settings = {
      # Varsayılan mod: AC; kalıcı değil (AC/BAT olayıyla otomatik geçsin)
      TLP_DEFAULT_MODE        = "AC";
      TLP_PERSISTENT_DEFAULT  = 0;

      # CPU: HWP aktif. AC’de performans, BAT’ta powersave.
      CPU_DRIVER_OPMODE               = "active";
      CPU_SCALING_GOVERNOR_ON_AC      = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT     = "powersave";

      # “Taban konfor”: AC’de 1.2 GHz. (1.6 fazla sıcak; 1.0 bazı işlerde cırt)
      CPU_SCALING_MIN_FREQ_ON_AC      = 1200000;
      CPU_SCALING_MAX_FREQ_ON_AC      = 4800000;

      # BAT’ta taban frekansı ZORLAMIYORUZ → HWP/EPP özgürce düşürsün.
      # CPU_SCALING_MIN_FREQ_ON_BAT   = 800000;   # ← bilinçli olarak kapalı
      CPU_SCALING_MAX_FREQ_ON_BAT     = 3500000;

      # HWP min perf yüzdeleri: AC’de 25–100; BAT’ta 10–80
      CPU_MIN_PERF_ON_AC              = 25;
      CPU_MAX_PERF_ON_AC              = 100;
      CPU_MIN_PERF_ON_BAT             = 10;
      CPU_MAX_PERF_ON_BAT             = 80;

      # EPP: AC = performance, BAT = balance_power
      CPU_ENERGY_PERF_POLICY_ON_AC    = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT   = "balance_power";

      # HWP dyn boost: AC’de açık, BAT’ta kapalı
      CPU_HWP_DYN_BOOST_ON_AC         = 1;
      CPU_HWP_DYN_BOOST_ON_BAT        = 0;

      # Turbo: AC’de açık, BAT’ta cihaz karar versin
      CPU_BOOST_ON_AC                 = 1;
      CPU_BOOST_ON_BAT                = "auto";

      # Platform profile (FW destekliyorsa)
      PLATFORM_PROFILE_ON_AC          = "performance";
      PLATFORM_PROFILE_ON_BAT         = "balanced";

      # --- ÖNEMLİ: iGPU frekanslarını TLP ile zorlamıyoruz. ---
      # TLP 1.8 + modern i915’de bu anahtarlar hata/uygunsuzluk üretebiliyor.
      # INTEL_GPU_* satırları bilerek kaldırıldı.

      # PCIe ASPM
      PCIE_ASPM_ON_AC                 = "default";
      PCIE_ASPM_ON_BAT                = "powersupersave";

      # Runtime PM
      RUNTIME_PM_ON_AC                = "on";
      RUNTIME_PM_ON_BAT               = "auto";
      RUNTIME_PM_DRIVER_DENYLIST      = "nouveau radeon";

      # USB autosuspend istisnaları
      USB_AUTOSUSPEND                 = 1;
      USB_DENYLIST                    = "17ef:6047";  # Özel cihaz (örnek)
      USB_EXCLUDE_AUDIO               = 1;
      USB_EXCLUDE_BTUSB               = 0;
      USB_EXCLUDE_PHONE               = 1;
      USB_EXCLUDE_PRINTER             = 1;
      USB_EXCLUDE_WWAN                = 0;

      # ThinkPad batarya eşikleri
      START_CHARGE_THRESH_BAT0        = 75;
      STOP_CHARGE_THRESH_BAT0         = 80;
      START_CHARGE_THRESH_BAT1        = 75;
      STOP_CHARGE_THRESH_BAT1         = 80;
      RESTORE_THRESHOLDS_ON_BAT       = 1;

      # Disk güç yönetimi
      DISK_IDLE_SECS_ON_AC            = 0;
      DISK_IDLE_SECS_ON_BAT           = 2;
      MAX_LOST_WORK_SECS_ON_AC        = 15;
      MAX_LOST_WORK_SECS_ON_BAT       = 60;
      DISK_APM_LEVEL_ON_AC            = "255";
      DISK_APM_LEVEL_ON_BAT           = "128";
      DISK_APM_CLASS_DENYLIST         = "usb ieee1394";
      DISK_IOSCHED                     = "mq-deadline";

      # SATA link güç yönetimi
      SATA_LINKPWR_ON_AC              = "max_performance";
      SATA_LINKPWR_ON_BAT             = "med_power_with_dipm";

      # Wi-Fi & WOL
      WIFI_PWR_ON_AC                  = "off";
      WIFI_PWR_ON_BAT                 = "on";
      WOL_DISABLE                     = "Y";

      # Ses güç tasarrufu
      SOUND_POWER_SAVE_ON_AC          = 0;
      SOUND_POWER_SAVE_ON_BAT         = 10;
      SOUND_POWER_SAVE_CONTROLLER     = "Y";

      # Radyo cihazları
      DEVICES_TO_DISABLE_ON_STARTUP   = "";
      DEVICES_TO_ENABLE_ON_STARTUP    = "bluetooth wifi";
      DEVICES_TO_DISABLE_ON_SHUTDOWN  = "";
      DEVICES_TO_ENABLE_ON_AC         = "bluetooth wifi wwan";
      DEVICES_TO_DISABLE_ON_BAT       = "";
      DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "wwan";
    };
  };

  # =============================================================================
  # SYSTEM SERVICES
  # =============================================================================
  services = {
    thermald.enable = true; # Intel termal sürücüleriyle uyumlu
    upower.enable   = true; # Kullanışlı raporlama/uygulama entegrasyonu

    # ThinkFan: 5 kademeli sade eğri
    thinkfan = lib.mkIf isPhysicalMachine {
      enable = true;
      levels = [
        [ "level auto"      0  55 ]
        [ 1                55  65 ]
        [ 3                65  75 ]
        [ 7                75  85 ]
        [ "level full-speed" 85 32767 ]
      ];
    };

    # Laptop lid switch (yeni format)
    logind.settings.Login = {
      HandleLidSwitch               = "suspend";
      HandleLidSwitchDocked         = "suspend";
      HandleLidSwitchExternalPower  = "suspend";
      HandlePowerKey                = "ignore";
      HandlePowerKeyLongPress       = "poweroff";
      HandleSuspendKey              = "suspend";
      HandleHibernateKey            = "hibernate";
    };

    # SPICE agent: sadece VM’de gerekli (host’ta hata/uyarı üretebiliyor)
    spice-vdagentd.enable = lib.mkIf isVirtualMachine true;
  };

  # =============================================================================
  # RAPL POWER LIMITS (X1C6’da aktif; Meteor Lake’te otomatik “skip”)
  # =============================================================================

  # Not: Boot ordering döngüsünü kırmak için servis yerine TIMER ile tetikliyoruz.
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
          | ${pkgs.coreutils}/bin/tr -d '\n')"

        # Modern: Core Ultra / Meteor/Arrow/Lunar → native PM var, RAPL atla
        if echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Core Ultra|Meteor Lake|Arrow Lake|Lunar Lake'; then
          echo "RAPL: modern Intel CPU detected; skipping."
          exit 0
        fi

        # RAPL arayüzü yoksa sessizce çık
        shopt -s nullglob
        have_rapl=0
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] && have_rapl=1 && break
        done
        if [[ "$have_rapl" -eq 0 ]]; then
          echo "RAPL: no powercap interface; skipping."
          exit 0
        fi

        # X1C6 ve benzerleri için hafif PL1/PL2
        ON_AC=0
        for PS in /sys/class/power_supply/A{C,DP}*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && [[ "$ON_AC" == "1" ]] && break
        done

        if [[ "$ON_AC" == "1" ]]; then
          PL1_W=25; PL2_W=35
        else
          PL1_W=15; PL2_W=25
        fi

        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          [[ -w "$R/constraint_0_power_limit_uw" ]] && echo $(( PL1_W * 1000000 )) > "$R/constraint_0_power_limit_uw" 2>/dev/null || true
          [[ -w "$R/constraint_0_time_window_us" ]] && echo 28000000 > "$R/constraint_0_time_window_us" 2>/dev/null || true
          [[ -w "$R/constraint_1_power_limit_uw" ]] && echo $(( PL2_W * 1000000 )) > "$R/constraint_1_power_limit_uw" 2>/dev/null || true
          [[ -w "$R/constraint_1_time_window_us" ]] && echo 2440000  > "$R/constraint_1_time_window_us" 2>/dev/null || true
        done

        echo "RAPL applied (PL1=${PL1_W}W PL2=${PL2_W}W; AC=${ON_AC})."
      '';
    };
  };

  systemd.timers.rapl-power-limits = lib.mkIf isPhysicalMachine {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec  = "45s";   # TLP/diğer servisler otursun, sonra uygula
      Persistent = true;
    };
  };

  # Resume sonrası yeniden uygulatmak için timer tetiklenmesi yeterli;
  # istersen aşağıdaki basit helper’la da garantiye alabilirsin.
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
  # THINKPAD HELPERS (LED/fan; suspend/resume düzeltmeleri)
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

  # Eski ad-hoc sleep/wakeup servislerini kapat
  systemd.services.thinkfan-sleep  = lib.mkIf isPhysicalMachine { enable = lib.mkForce false; wantedBy = lib.mkForce [ ]; };
  systemd.services.thinkfan-wakeup = lib.mkIf isPhysicalMachine { enable = lib.mkForce false; wantedBy = lib.mkForce [ ]; };

  # =============================================================================
  # UDEV RULES
  # =============================================================================
  # AC/DC değişiminde RAPL’i nazikçe yeniden uygula (timer/servis tetiklenir)
  services.udev.extraRules = lib.mkIf isPhysicalMachine ''
    SUBSYSTEM=="power_supply", KERNEL=="A{C,DP}*", ACTION=="change", \
      RUN+="${pkgs.systemd}/bin/systemctl start rapl-power-limits.service"
  '';

  # =============================================================================
  # USER-FACING YARDIMCI KOMUTLAR
  # =============================================================================
  environment.systemPackages = with pkgs;
    lib.optionals isPhysicalMachine [
      tlp

      (writeScriptBin "performance-mode" ''
        #!${bash}/bin/bash
        echo "🚀 Performance mode..."
        sudo ${tlp}/bin/tlp ac
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do
          echo performance | sudo tee "$cpu/scaling_governor" >/dev/null 2>&1
        done
        echo "✅ Done!"
      '')

      (writeScriptBin "balanced-mode" ''
        #!${bash}/bin/bash
        echo "⚖️ Balanced mode..."
        sudo ${tlp}/bin/tlp start
        echo "✅ Done!"
      '')

      (writeScriptBin "eco-mode" ''
        #!${bash}/bin/bash
        echo "🍃 Eco mode..."
        sudo ${tlp}/bin/tlp bat
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do
          echo powersave | sudo tee "$cpu/scaling_governor" >/dev/null 2>&1
        done
        echo "✅ Done!"
      '')

      (writeScriptBin "power-status" ''
        #!${bash}/bin/bash
        echo "==== Power Status ===="
        sudo ${tlp}/bin/tlp-stat -s -c -p | head -20
      '')
    ];
}
