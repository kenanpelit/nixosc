# modules/core/system/default.nix
# ==============================================================================
# Base System + Boot + Hardware (Merged) — TLP Edition
# ==============================================================================
# Bu modül; temel sistem + önyükleme + donanım/güç/termal optimizasyonlarını
# **tek dosyada** toplar. Güç yönetimi artık TLP ile yapılır.
#
# Kapsam:
# - Zaman dilimi, yerel ayarlar, klavye düzeni (base system)
# - GRUB + EFI/BIOS seçimi, tema ve kernel paketleri (boot)
# - CPU/EPP/Turbo + platform_profile + cihaz güç tasarrufu (TLP)
# - Kaby Lake-R için RAPL PL1/PL2 limitleri (X1 Carbon 6th güvenli profil)
# - ThinkPad fan (thinkfan), batarya eşikleri, LED düzeltmeleri
# - i915 için stabil çoklu monitör/Wayland parametreleri
# - UDEV: AC/DC değişiminde RAPL tazeleme
#
# Notlar:
# - Önceki auto-cpufreq/power-profiles-daemon devre dışı bırakıldı.
# - TLP; intel_pstate (active) + EPP + turbo + platform_profile’ı yönetir.
# - Ayarlar Meteor Lake (E14 Gen 6) ve Kaby Lake-R (X1C6) ile uyumludur.
#
# Author: Kenan Pelit
# ==============================================================================

{ pkgs, config, lib, inputs, system, ... }:

let
  hostname = config.networking.hostName or "";
  isPhysicalMachine = true; # İki cihaz da fiziksel; istersen hostname == "hay" yaparsın.
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

  services.xserver.xkb = {
    layout = "tr";
    variant = "f";
    options = "ctrl:nocaps";
  };
  console.keyMap = "trf";

  system.stateVersion = "25.11";

  # =============================================================================
  # BOOT (GRUB + Kernel)
  # =============================================================================
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

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

    # i915 için Wayland/çoklu monitör stabilite odaklı parametreler
    kernelParams = [
      "intel_pstate=active"
      "intel_pstate.hwp_dynamic_boost=1"
      # Güç yönetimi: TLP yönetsin diye default
      "pcie_aspm=default"
      # i915: bazı agresif özellikleri kapat (stabilite için)
      "i915.enable_guc=3"
      "i915.enable_fbc=0"
      "i915.enable_psr=0"
      "i915.enable_sagv=0"
      # Uyku & NVMe
      "nvme_core.default_ps_max_latency_us=5500"
      "mem_sleep_default=deep"
    ];

    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
    };

    loader = {
      grub = {
        enable = true;
        device = lib.mkForce (if isPhysicalMachine then "nodev" else "/dev/vda");
        efiSupport = isPhysicalMachine;
        useOSProber = true;
        configurationLimit = 10;
        gfxmodeEfi  = "1920x1200";
        gfxmodeBios = "1920x1200";
        theme = inputs.distro-grub-themes.packages.${system}.nixos-grub-theme;
      };

      efi = lib.mkIf isPhysicalMachine {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
  };

  # =============================================================================
  # HARDWARE & POWER (ThinkPad-optimized, TLP kontrollü)
  # =============================================================================

  services.auto-cpufreq.enable = false;
  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = true;

    settings = {
      # CPU sürücü modu: intel_pstate (active)
      CPU_DRIVER_OPMODE = "active";

      # Governor + EPP
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

      # Min/Max performans yüzdeleri
      CPU_MIN_PERF_ON_AC = 50;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 15;
      CPU_MAX_PERF_ON_BAT = 80;

      # Intel HWP Dynamic Boost (ek turbo; AC=on, Batarya=off)
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;

      # Turbo/Boost
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = "auto";

      # Platform profile
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "balanced";

      # PCIe ASPM: TLP yönetiyor
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersave";

      # Runtime PM
      RUNTIME_PM_ON_AC = "auto";
      RUNTIME_PM_ON_BAT = "auto";
      RUNTIME_PM_DRIVER_BLACKLIST = "nouveau radeon";

      # USB autosuspend (girdi cihazları hariç)
      USB_AUTOSUSPEND = 1;
      USB_BLACKLIST = "usbhid";

      # Ses güç tasarrufu
      SOUND_POWER_SAVE_ON_AC = 1;
      SOUND_POWER_SAVE_ON_BAT = 1;
      SOUND_POWER_SAVE_CONTROLLER = "Y";

      # iwlwifi güç politikası
      WIFI_PWR_ON_AC = "on";
      WIFI_PWR_ON_BAT = "on";

      # ThinkPad batarya eşikleri
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0  = 80;
      START_CHARGE_THRESH_BAT1 = 40;
      STOP_CHARGE_THRESH_BAT1  = 80;

      # Disk/APM (SATA)
      DISK_APM_LEVEL_ON_AC = "254 254";
      DISK_APM_LEVEL_ON_BAT = "128 128";
    };

    extraConfig = "";
  };

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

  services = {
    thermald.enable = true;
    upower.enable = true;

    thinkfan = {
      enable = true;
      levels = [
        [ "level auto" 0 55 ]
        [ 1 55 65 ]
        [ 3 65 75 ]
        [ 7 75 85 ]
      ];
    };

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

  # =============================================================================
  # RAPL (Kaby Lake-R güvenli profil) + tazeleme tetikleyicisi
  # =============================================================================
  systemd.services."rapl-power-limits" = {
    description = "Apply RAPL PL1/PL2 limits (Kaby Lake-R safe profile)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "set-rapl-limits" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail

        CPU_MODEL="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'Model name' | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.coreutils}/bin/tr -d '\n')"
        if ! echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE '8650U|8550U|8350U|8250U|Kaby *Lake|Whiskey *Lake|Coffee *Lake'; then
          echo "Non-KabyLakeR family; skipping RAPL limits"; exit 0;
        fi

        # Güç kaynağı tespiti (AC/ADP yollarını dene)
        ON_AC=0
        for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && [[ "$ON_AC" == "1" ]] && break
        done

        if [[ "$ON_AC" == "1" ]]; then
          PL1_W=25   # AC: daha yüksek sürekli güç
          PL2_W=35   # AC: daha yüksek kısa patlama
        else
          PL1_W=15   # Batarya: serin ve dengeli
          PL2_W=25
        fi

        TW1_US=28000000   # 28s (sustained)
        TW2_US=2440000    # ~2.44s (short turbo)

        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          if [[ -w "$R/constraint_0_power_limit_uw" ]]; then
            echo $(( PL1_W * 1000000 )) > "$R/constraint_0_power_limit_uw" 2>/dev/null || true
            echo $TW1_US > "$R/constraint_0_time_window_us" 2>/dev/null || true
          fi
          if [[ -w "$R/constraint_1_power_limit_uw" ]]; then
            echo $(( PL2_W * 1000000 )) > "$R/constraint_1_power_limit_uw" 2>/dev/null || true
            echo $TW2_US > "$R/constraint_1_time_window_us" 2>/dev/null || true
          fi
        done

        # Tanılama
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          PL1=$(cat "$R/constraint_0_power_limit_uw" 2>/dev/null || echo 0)
          PL2=$(cat "$R/constraint_1_power_limit_uw" 2>/dev/null || echo 0)
          echo "$(basename $R): PL1=$((PL1/1000000))W PL2=$((PL2/1000000))W (AC=$ON_AC)" | ${pkgs.systemd}/bin/systemd-cat -t rapl-power
        done
      '';
    };
  };

  systemd.services."rapl-power-limits-resume" = {
    description = "Re-apply RAPL limits after resume";
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl start rapl-power-limits.service";
    };
  };

  # =============================================================================
  # THINKPAD LED/FAN YARDIMCILARI
  # =============================================================================

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
        sleep 0.8
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

  systemd.services."thinkfan-sleep" = {
    enable   = lib.mkForce false;
    wantedBy = lib.mkForce [ ];
  };
  systemd.services."thinkfan-wakeup" = {
    enable   = lib.mkForce false;
    wantedBy = lib.mkForce [ ];
  };

  # =============================================================================
  # UDEV — AC/DC değişiminde sadece RAPL’i tazele (TLP kendi işini yapar)
  # =============================================================================
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", KERNEL=="AC*",  ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl restart rapl-power-limits.service"
    SUBSYSTEM=="power_supply", KERNEL=="ADP*", ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl restart rapl-power-limits.service"
  '';
}

