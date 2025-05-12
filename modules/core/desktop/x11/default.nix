# modules/core/desktop/x11/default.nix
# ==============================================================================
# X Server Configuration
# ==============================================================================
# This configuration manages X11 settings including:
# - X Server setup
# - Display manager configuration
# - Input device settings
#
# Author: Kenan Pelit
# ==============================================================================
{ username, ... }:
{
  services = {
    # X Server Settings
    xserver = {
      enable = true;
      # Keyboard Configuration
      xkb = {
        layout = "tr";
        variant = "f";
        options = "ctrl:nocaps";  # Caps Lock as Ctrl
      };
    };
    
    # COSMIC Masaüstü Ortamı
    desktopManager.cosmic.enable = true;
    
    # COSMIC Greeter etkinleştir
    displayManager.cosmic-greeter.enable = true;
    
    # Otomatik giriş ayarlarını devre dışı bırak veya COSMIC'e uyarla
    displayManager.autoLogin = {
      enable = false;  # COSMIC Greeter'ı denemek için şimdilik kapatın
      # Daha sonra COSMIC ile otomatik giriş yapmak isterseniz:
      # enable = true;
      # user = "${username}";
    };
    
    # Varsayılan oturum ayarı (gerekirse)
    displayManager.defaultSession = "cosmic";
    
    # Input Device Settings
    libinput.enable = true;  # Enable libinput for input devices
  };
  
  # COSMIC için gerekli clipboard manager ayarı
  environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;
}
