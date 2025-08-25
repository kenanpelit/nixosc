# modules/core/hardware/default.nix
# ==============================================================================
# ThinkPad E14 Gen 6 için Kapsamlı Donanım Konfigürasyonu
# ==============================================================================
# Bu konfigürasyon şu özellikleri yönetir:
# - ThinkPad'e özel ACPI ve gelişmiş termal yönetim
# - Intel Arc Graphics sürücüleri ve donanım hızlandırması
# - Çift NVMe kurulumu için depolama optimizasyonları
# - Intel Core Ultra 7 155H CPU termal ve güç yönetimi
# - LED kontrolü ve fonksiyon tuşu yönetimi
# - TrackPoint ve touchpad konfigürasyonu
# - Kararlı çalışma için optimize edilmiş termal throttling
# - Gelişmiş güç tasarrufu özellikleri
# - Dinamik performans ölçeklendirmesi
#
# Hedef Donanım:
# - ThinkPad E14 Gen 6 (21M7006LTX)
# - Intel Core Ultra 7 155H (16 çekirdek hibrit mimari)
# - Intel Arc Graphics (Meteor Lake-P)
# - 64GB DDR5 RAM
# - Çift NVMe kurulumu: Transcend TS2TMTE400S + Timetec 35TT2280GEN4E-2TB
#
# Performans Hedefleri:
# - CPU Sıcaklığı: Yük altında 75-83°C
# - Fan Gürültüsü: Dengeli (aşamalı eğri)
# - Güç Tüketimi: AC'de 30W sürekli/40W burst, Pilde 18W sürekli/28W burst
# - Pil Ömrü: %25-30 iyileşme hedefi
#
# Yazar: Kenan Pelit
# Değiştirilme: 2025-08-25 (E14 Gen 6 için final optimize versiyon)
# ==============================================================================
{ pkgs, ... }:
{
  # ==============================================================================
  # Temel Donanım Konfigürasyonu
  # ==============================================================================
  hardware = {
    # ThinkPad'lerin klasik TrackPoint özelliğini etkinleştir
    # Kırmızı nokta ile hassas cursor kontrolü sağlar
    trackpoint.enable = true;
    
    # Intel Arc Graphics (Meteor Lake-P) için kapsamlı sürücü desteği
    graphics = {
      enable = true;  # Grafik sürücülerini etkinleştir
      extraPackages = with pkgs; [
        intel-media-driver      # VA-API implementasyonu - video decode/encode için
        vaapiVdpau             # VDPAU backend - eski uygulamalar için VA-API köprüsü
        libvdpau-va-gl         # OpenGL/VAAPI ile VDPAU sürücüsü
        mesa                   # Ana OpenGL implementasyonu - 3D rendering
        intel-compute-runtime  # Intel GPU'lar için OpenCL runtime
        intel-ocl             # Intel OpenCL implementasyonu - GPU hesaplama
      ];
    };
    
    # Firmware ve mikrocode güncellemeleri
    enableRedistributableFirmware = true;  # Üçüncü parti firmware'leri etkinleştir
    enableAllFirmware = true;              # Tüm firmware'leri yükle (WiFi, Bluetooth vb.)
    cpu.intel.updateMicrocode = true;      # Intel CPU mikrocode güncellemelerini etkinleştir
  };
  
  # ==============================================================================
  # Gelişmiş Güç Yönetimi Servisleri
  # ==============================================================================
  services = {
    # Lenovo throttling düzeltmesi - optimize edilmiş termal yönetim
    throttled = {
      enable = true;  # Lenovo BIOS throttling sorunlarını düzelt
      extraConfig = ''
        [GENERAL]
        # Throttling düzeltmesini etkinleştir
        Enabled: True
        # AC güç durumunu kontrol etmek için sistem yolu
        Sysfs_Power_Path: /sys/class/power_supply/AC*/online
        # Konfigürasyon değişikliklerinde otomatik yeniden yükleme
        Autoreload: True

        [BATTERY]
        # Pil modunda güncelleme hızı (saniye) - daha hızlı response
        Update_Rate_s: 15
        # Uzun vadeli güç limiti (Watt) - pil ömrü için optimize
        PL1_Tdp_W: 18
        # PL1 süre penceresi (saniye)
        PL1_Duration_s: 30
        # Kısa vadeli güç limiti (Watt) - burst performansı için
        PL2_Tdp_W: 28
        # PL2 süre penceresi (saniye) - daha uzun burst süresi
        PL2_Duration_S: 0.004
        # Throttling başlangıç sıcaklığı (Celsius) - daha düşük threshold
        Trip_Temp_C: 78

        [AC]
        # AC modunda güncelleme hızı (saniye) - çok hızlı response
        Update_Rate_s: 3
        # Uzun vadeli güç limiti (Watt) - sürdürülebilir performans
        PL1_Tdp_W: 30
        # PL1 süre penceresi (saniye)
        PL1_Duration_s: 25
        # Kısa vadeli güç limiti (Watt) - burst performansı
        PL2_Tdp_W: 40
        # PL2 süre penceresi (saniye)
        PL2_Duration_S: 0.005
        # Throttling başlangıç sıcaklığı (Celsius) - optimum sıcaklık
        Trip_Temp_C: 83

        [UNDERVOLT.BATTERY]
        # Meteor Lake undervolting desteklemiyor - tüm değerler 0
        CORE: 0
        GPU: 0
        CACHE: 0
        UNCORE: 0
        ANALOGIO: 0

        [UNDERVOLT.AC]
        # Meteor Lake undervolting desteklemiyor - tüm değerler 0
        CORE: 0
        GPU: 0
        CACHE: 0
        UNCORE: 0
        ANALOGIO: 0
      '';
    };

    # TLP'yi devre dışı bırak - auto-cpufreq ile çakışma önlemek için
    tlp.enable = false;
    
    # Modern CPU frekans yönetimi - akıllı güç ve performans dengesi
    auto-cpufreq = {
      enable = true;  # Otomatik CPU frekans scaling etkinleştir
      settings = {
        battery = {
          # Pil modunda maksimum güç tasarrufu
          governor = "powersave";           # En düşük güç tüketimi için powersave governor
          scaling_min_freq = 400000;        # 400 MHz minimum frekans
          scaling_max_freq = 2200000;       # 2.2 GHz maksimum - agresif pil tasarrufu
          turbo = "never";                  # Turbo boost'u tamamen kapat
          energy_perf_bias = "power";       # Güç tasarrufu odaklı bias
          balance_performance = 30;         # Düşük performans hedefi (0-100 arası)
        };
        charger = {
          # AC modunda dengeli performans
          governor = "powersave";           # schedutil yerine powersave - daha kararlı
          scaling_min_freq = 400000;        # 400 MHz minimum frekans
          scaling_max_freq = 3400000;       # 3.4 GHz maksimum - termal için konservatif
          turbo = "auto";                   # Akıllı turbo boost - gerektiğinde devreye gir
          energy_perf_bias = "balance_performance"; # Dengeli performans bias
          balance_performance = 70;         # Orta-yüksek performans hedefi
        };
      };
    };

    # PowerTOP otomatik optimizasyonları - sistem çapında güç tasarrufu
    powertop.enable = true;

    # Intel termal daemon - Meteor Lake için yeniden etkinleştirildi
    thermald = {
      enable = true;      # Termal yönetim daemon'unu etkinleştir
      adaptive = true;    # Adaptif termal yönetim - iş yüküne göre ayarlama
    };

    # Power-profiles-daemon'u devre dışı bırak - çakışma önlemek için
    power-profiles-daemon.enable = false;
    
    # Sistem güç yönetimi ayarları
    logind = {
      # Kapak kapatıldığında suspend
      lidSwitch = "suspend";
      # Docked iken kapak kapatma eylemini yok say
      lidSwitchDocked = "ignore";
      # Harici güçte de kapak kapatınca suspend
      lidSwitchExternalPower = "suspend";
      # Güç tuşuna kısa basışta suspend
      powerKey = "suspend";
      # Güç tuşuna uzun basışta kapat
      powerKeyLongPress = "poweroff";
      # Suspend tuşu davranışı
      handleSuspendKey = "suspend";
      # 20 dakika idle sonrası otomatik suspend
      idleAction = "suspend";
      idleActionSec = "20min";
    };
  };
  
  # ==============================================================================
  # Gelişmiş Boot Konfigürasyonu
  # ==============================================================================
  boot = {
    # Donanım izleme ve kontrol için gerekli kernel modülleri
    kernelModules = [ 
      "thinkpad_acpi"      # ThinkPad ACPI ekstreleri (fan kontrolü, LED'ler vb.)
      "coretemp"           # CPU sıcaklık sensörleri
      "intel_rapl"         # Intel RAPL güç sınırlama arayüzü
      "msr"                # Model-specific register erişimi
      "acpi_call"          # ACPI call desteği - gelişmiş ACPI fonksiyonları
    ];
    
    # Modül seçenekleri - ThinkPad ve Intel CPU optimizasyonları
    extraModprobeConfig = ''
      # ThinkPad ACPI konfigürasyonu
      options thinkpad_acpi fan_control=1      # Manuel fan kontrolünü etkinleştir
      options thinkpad_acpi brightness_mode=1   # Gelişmiş parlaklık kontrolü
      options thinkpad_acpi volume_mode=1       # Daha iyi ses tuşu kontrolü
      options thinkpad_acpi experimental=1      # Deneysel özellikleri etkinleştir
      
      # Intel P-state sürücü optimizasyonları
      options intel_pstate hwp_dynamic_boost=0  # Kararlılık için dinamik boost'u kapat
      options intel_pstate disable_acpi_ppc=1   # ACPI PPC'yi devre dışı bırak
      
      # Ses güç yönetimi
      options snd_hda_intel power_save=1        # Ses kartı güç tasarrufu
      options snd_ac97_codec power_save=1       # AC97 codec güç tasarrufu
    '';
    
    # Kernel parametreleri - sistem çapında optimizasyonlar
    kernelParams = [
      # NVMe optimizasyonu - daha iyi performans için ACPI'yi kapat
      "nvme.noacpi=1"
      
      # IOMMU - cihaz izolasyonu ve güvenlik
      "intel_iommu=on"          # Intel IOMMU'yu etkinleştir
      "iommu=pt"                # Pass-through modu - daha iyi performans
      
      # CPU güç yönetimi optimizasyonları
      "intel_pstate=active"     # Aktif P-state sürücüsü - daha iyi kontrol
      "processor.max_cstate=7"  # Derin C-state'leri etkinleştir - güç tasarrufu
      "intel_idle.max_cstate=7" # Intel idle sürücüsü için C-state limiti
      
      # Intel Arc Graphics optimizasyonları
      "i915.enable_guc=3"       # GuC ve HuC firmware'leri etkinleştir
      "i915.enable_fbc=1"       # Frame buffer sıkıştırması - güç tasarrufu
      "i915.enable_psr=2"       # Panel self refresh v2 - ekran güç tasarrufu
      "i915.enable_dc=4"        # Display C-states (maksimum güç tasarrufu)
      "i915.fastboot=1"         # Hızlı grafik başlatması
      "i915.panel_use_ssc=0"    # SSC'yi kapat - güç tasarrufu
      "i915.modeset=1"          # KMS'yi etkinleştir
      "i915.enable_dpcd_backlight=1" # eDP arkaplan ışığı kontrolü
      
      # Termal yönetim ayarları
      "thermal.off=0"           # Termal yönetimini etkinleştir
      "thermal.act=-1"          # ACPI termal kontrolü (otomatik)
      "thermal.nocrt=0"         # Kritik sıcaklık eylemlerini etkinleştir
      "thermal.psv=-1"          # Otomatik pasif soğutma
      
      # Güç yönetimi eklemeleri
      "acpi_osi=Linux"          # ACPI uyumluluğunu artır
      "pcie_aspm=force"         # PCIe Active State Power Management zorla
      "ahci.mobile_lpm_policy=3" # SATA güç yönetimi (en agresif)
      "snd_hda_intel.power_save=1" # Ses kartı güç tasarrufu
      "usbcore.autosuspend=2"   # USB cihazları 2 saniye sonra suspend
      "iwlwifi.power_save=1"    # WiFi güç tasarrufu etkinleştir
      "iwlwifi.uapsd_disable=0" # WiFi uAPSD etkin (güç tasarrufu)
      
      # Bellek ve performans optimizasyonları
      "transparent_hugepage=madvise" # Büyük sayfa optimizasyonu
      "mitigations=auto"        # Güvenlik önlemlerini otomatik uygula
    ];
  };
  
  # ==============================================================================
  # Gelişmiş Sistem Servisleri
  # ==============================================================================
  systemd.services = {
    # Dinamik CPU güç sınırı servisi - RAPL arayüzü üzerinden
    cpu-power-limit = {
      description = "Dinamik Intel RAPL güç sınırları";
      wantedBy = [ "multi-user.target" ];    # Sistem başlangıcında otomatik başlat
      after = [ "sysinit.target" ];          # Sistem başlatma sonrası çalıştır
      serviceConfig = {
        Type = "oneshot";                     # Bir kez çalışıp bitecek servis
        RemainAfterExit = true;               # Çıktıktan sonra aktif olarak işaretle
        ExecStart = pkgs.writeShellScript "cpu-power-limit" ''
          #!/usr/bin/env sh
          # RAPL arayüzünün hazır olmasını bekle
          sleep 3
          
          # RAPL arayüzü mevcut mu kontrol et
          if [ -d /sys/class/powercap/intel-rapl:0 ]; then
            # Güç kaynağını tespit et (AC veya pil)
            ON_AC=0
            # Hem AC hem de DP (DisplayPort) güç kaynaklarını kontrol et
            for ac in /sys/class/power_supply/A{C,DP}*; do
              [ -f "$ac/online" ] && [ "$(cat "$ac/online")" = "1" ] && ON_AC=1 && break
            done
            
            if [ "$ON_AC" = "1" ]; then
              # AC Güç: Dengeli performans profili
              echo 30000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw  # PL1: 30W
              echo 40000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw  # PL2: 40W
              echo 25000000 > /sys/class/powercap/intel-rapl:0/constraint_0_time_window_us  # PL1 süre: 25s
              echo 5000 > /sys/class/powercap/intel-rapl:0/constraint_1_time_window_us      # PL2 süre: 5ms
              echo "RAPL: AC Modu - PL1=30W, PL2=40W"
            else
              # Pil: Maksimum verimlilik profili
              echo 18000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw  # PL1: 18W
              echo 28000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw  # PL2: 28W
              echo 30000000 > /sys/class/powercap/intel-rapl:0/constraint_0_time_window_us  # PL1 süre: 30s
              echo 4000 > /sys/class/powercap/intel-rapl:0/constraint_1_time_window_us      # PL2 süre: 4ms
              echo "RAPL: Pil Modu - PL1=18W, PL2=28W"
            fi
          else
            echo "Intel RAPL arayüzü bulunamadı - güç sınırı konfigürasyonu atlanıyor"
          fi
        '';
      };
    };
    
    # ThinkPad LED durumlarını düzeltme servisi
    fix-led-state = {
      description = "ThinkPad LED durumlarını boot'ta düzelt";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];  # udev kuralları yüklendikten sonra
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "fix-leds" ''
          #!/usr/bin/env sh
          # Ses ile ilgili LED'leri yapılandır
          for led in /sys/class/leds/platform::*mute; do
            if [ -d "$led" ]; then
              # LED'in trigger'ını ses durumuna bağla
              echo "audio-$(basename "$led" | sed 's/.*:://')" > "$led/trigger" 2>/dev/null || true
              # Başlangıçta LED'i kapat
              echo 0 > "$led/brightness" 2>/dev/null || true
            fi
          done
        '';
      };
    };
    
    # Gelişmiş termal izleme servisi - performans ölçeklendirmeli
    thermal-monitor = {
      description = "Performans ölçeklendirmeli gelişmiş termal izleme";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";                      # Sürekli çalışan servis
        ExecStart = pkgs.writeShellScript "thermal-monitor" ''
          #!/usr/bin/env sh
          # Log dosyası yolu
          TEMP_LOG="/var/log/thermal-monitor.log"
          touch "$TEMP_LOG"
          
          while true; do
            # Sistemdeki en yüksek sıcaklığı al
            MAX_TEMP=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1)
            
            if [ -n "$MAX_TEMP" ]; then
              TEMP_C=$((MAX_TEMP / 1000))
              TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
              
              # Sıcaklık bazlı eylem matrisi
              if [ "$TEMP_C" -gt 90 ]; then
                # KRITIK: Acil müdahale gerekli
                echo "$TIMESTAMP CRITICAL: $TEMP_C°C - Acil throttling başlatılıyor" | tee -a "$TEMP_LOG"
                logger -p user.crit -t thermal-monitor "Acil durum: $TEMP_C°C"
                # Tüm CPU çekirdeklerini powersave moduna geçir
                echo powersave > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
              elif [ "$TEMP_C" -gt 85 ]; then
                # UYARI: Yüksek sıcaklık
                echo "$TIMESTAMP WARNING: $TEMP_C°C - Yüksek sıcaklık tespit edildi" | tee -a "$TEMP_LOG"
                logger -p user.warning -t thermal-monitor "Yüksek sıcaklık: $TEMP_C°C"
              elif [ "$TEMP_C" -lt 70 ]; then
                # Normal sıcaklığa dönüş - performans modunu geri yükle
                systemctl is-active auto-cpufreq >/dev/null && systemctl restart auto-cpufreq 2>/dev/null || true
              fi
            fi
            
            # Her 15 saniyede bir kontrol et (hızlı response için)
            sleep 15
          done
        '';
        Restart = "always";                   # Servis durduğunda otomatik yeniden başlat
        RestartSec = 5;                       # 5 saniye bekleyip yeniden başlat
      };
    };
    
    # Otomatik WiFi güç yönetimi servisi
    wifi-powersave = {
      description = "WiFi güç yönetimini etkinleştir";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];            # Ağ servisleri başladıktan sonra
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "wifi-powersave" ''
          #!/usr/bin/env sh
          # Tüm wireless arayüzlerini bul ve güç tasarrufunu etkinleştir
          for iface in $(ls /sys/class/net/ | grep -E '^wl'); do
            if [ -d "/sys/class/net/$iface/wireless" ]; then
              # iw komutu ile power save modunu etkinleştir
              ${pkgs.iw}/bin/iw dev "$iface" set power_save on 2>/dev/null || true
              echo "$iface için WiFi güç tasarrufu etkinleştirildi"
            fi
          done
        '';
      };
    };
  };
  
  # ==============================================================================
  # Gelişmiş Udev Kuralları - Otomatik Donanım Yönetimi
  # ==============================================================================
  services.udev.extraRules = ''
    # LED izinleri - kullanıcı erişimi için
    SUBSYSTEM=="leds", KERNEL=="platform::*mute", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 %S%p/brightness"
    
    # Güç kaynağı değişikliklerinde otomatik servis yeniden başlatma
    # Pil/AC geçişlerinde güç profilleri otomatik güncellenir
    SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_ONLINE}=="0", RUN+="${pkgs.systemd}/bin/systemctl restart cpu-power-limit.service auto-cpufreq.service"
    SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_ONLINE}=="1", RUN+="${pkgs.systemd}/bin/systemctl restart cpu-power-limit.service auto-cpufreq.service"
    
    # USB cihazları için otomatik güç yönetimi
    # Takılır takılmaz otomatik suspend moduna geç
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/autosuspend" ATTR{power/autosuspend}="2"
    
    # SATA bağlantı güç yönetimi - SSD'ler için optimize
    # Orta güç tasarrufu modu - performans/güç dengesi
    ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="med_power_with_dipm"
  '';
  
  # ==============================================================================
  # Sistem Çapında Optimizasyonlar
  # ==============================================================================
  
  ## Zram konfigürasyonu - RAM'i daha verimli kullanma
  #zramSwap = {
  #  enable = true;                            # Zram swap'ı etkinleştir
  #  algorithm = "lz4";                        # Hızlı sıkıştırma algoritması
  #  memoryPercent = 30;                       # RAM'in %30'u kadar zram kullan
  #};
  
  # Kernel sysctl optimizasyonları - donanıma özgü sistem parametreleri
  boot.kernel.sysctl = {
    # VM (Sanal Bellek) optimizasyonları - SSD ve güç tasarrufu için
    "vm.dirty_ratio" = 5;                     # Kirli sayfalar için %5 sınır (SSD için düşük)
    "vm.dirty_background_ratio" = 2;          # Arkaplan temizleme %2'de başlasın
    "vm.dirty_expire_centisecs" = 1500;       # Kirli sayfalar 15 saniye sonra yazılsın
    "vm.dirty_writeback_centisecs" = 500;     # Her 5 saniyede bir temizlik yap
    "vm.swappiness" = 10;                     # Düşük swap kullanımı (RAM öncelikli)
    
    # Güç ve donanım ile ilgili optimizasyonlar
    "kernel.nmi_watchdog" = 0;                # NMI watchdog'u kapat - güç tasarrufu
    
    # Memory management optimizations for 64GB RAM
    "vm.vfs_cache_pressure" = 50;             # VFS cache'ini daha az temizle (64GB RAM avantajı)
    "vm.min_free_kbytes" = 131072;            # 128MB free memory reserve (64GB için optimum)
    
    # Scheduler optimizations for hybrid CPU (P+E cores)
    "kernel.sched_energy_aware" = 1;          # Energy Aware Scheduling etkinleştir
    "kernel.sched_autogroup_enabled" = 1;     # Otomatik process gruplandırma
    
    # I/O scheduler optimizations for NVMe SSDs
    "vm.page_lock_unfairness" = 1;            # SSD'ler için sayfa kilidi optimizasyonu
  };
}

