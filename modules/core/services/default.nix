# modules/core/services/default.nix
{ pkgs, ... }:
{
  # =============================================================================
  # Base System Services
  # =============================================================================
  services = {
    gvfs.enable = true;       # Virtual filesystem support
    fstrim.enable = true;     # SSD optimization service
    
    # D-Bus Configuration
    dbus = {
      enable = true;
      packages = [ pkgs.gcr ];  # GPG and encryption infrastructure
    };
    # Input Device Services
    touchegg.enable = false;    # Touchscreen gesture service
    
    # Power Management
    logind.extraConfig = ''
      HandlePowerKey=ignore    # Ignore power button events
    '';

    hblock = {
      enable = true;
      updateInterval = "weekly";  # Haftalık
      # veya
      # updateInterval = "*-*-* 03:00:00";  # Her gün saat 3'te
      # updateInterval = "Mon *-*-* 00:00:00";  # Her Pazartesi
      # updateInterval = "*-*-1 00:00:00";  # Her ayın 1'inde
    };
  };

  # =============================================================================
  # Security Configuration
  # =============================================================================
  security.polkit.enable = true;  # PolicyKit authorization manager
  
  # =============================================================================
  # Firewall Configuration
  # =============================================================================
  networking.firewall = {
    # Transmission Service Ports
    allowedTCPPorts = [ 9091 ];         # Web interface
    allowedTCPPortRanges = [{ 
      from = 51413; 
      to = 51413; 
    }];
    allowedUDPPortRanges = [{ 
      from = 51413; 
      to = 51413; 
    }];
  };
}

