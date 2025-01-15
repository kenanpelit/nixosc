# modules/core/power.nix
{ config, lib, pkgs, ... }:

{
 # UPower servisi ve yapılandırması
 services.upower = {
   enable = true;
   criticalPowerAction = "Hibernate"; # Kritik pil seviyesinde yapılacak eylem
 };

 # systemd-logind güç yönetimi ayarları
 services.logind = {
   lidSwitch = "suspend";          # Laptop kapağı kapatıldığında
   lidSwitchDocked = "ignore";     # Harici ekran bağlıyken kapak kapatıldığında
   lidSwitchExternalPower = "suspend"; # Şarjdayken kapak kapatıldığında
   extraConfig = ''
     HandlePowerKey=suspend        # Güç düğmesine basıldığında
     HandleSuspendKey=suspend      # Uyku tuşuna basıldığında
     HandleHibernateKey=hibernate  # Hazırda beklet tuşuna basıldığında
     IdleAction=suspend           # Boşta kalma eyleminde
     IdleActionSec=30min          # Boşta kalma süresi
   '';
 };

 # TLP güç yönetimi (laptop için optimize edilmiş)
 services.tlp = {
   enable = true;
   settings = {
     CPU_SCALING_GOVERNOR_ON_AC = "performance";
     CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
     CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
     CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
     CPU_MIN_PERF_ON_AC = 0;
     CPU_MAX_PERF_ON_AC = 100;
     CPU_MIN_PERF_ON_BAT = 0;
     CPU_MAX_PERF_ON_BAT = 80;
   };
 };

 # thermald - Intel CPU termal yönetimi
 services.thermald.enable = true;
}
