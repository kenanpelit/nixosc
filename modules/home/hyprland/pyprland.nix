# modules/home/hyprland/pyprland.nix
# ==============================================================================
# Pyprland Configuration (Python Plugins for Hyprland) - Enhanced
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  # =============================================================================
  # Configuration File
  # =============================================================================
  home.file.".config/hypr/pyprland.toml".text = ''
    # ---------------------------------------------------------------------------
    # Plugin Configuration - Enhanced
    # ---------------------------------------------------------------------------
    [pyprland]
    plugins = [
      "scratchpads",
      "lost_windows",
      "shift_monitors",
      "toggle_dpms",
      "expose",
      "workspaces_follow_focus",
      "magnify",              # Yeni: Pencere büyütme
      "layout_center",        # Yeni: Merkez layout
    ]
    
    # ---------------------------------------------------------------------------
    # Global Settings
    # ---------------------------------------------------------------------------
    [settings]
    check_interval = 100        # ms - Daha hızlı response
    debug = false              # Debug kapalı (production için)
    
    # ---------------------------------------------------------------------------
    # Workspace Settings - Enhanced
    # ---------------------------------------------------------------------------
    [workspaces_follow_focus]
    max_workspaces = 9
    follow_mouse = true        # Fare workspace'i takip etsin
    
    # ---------------------------------------------------------------------------
    # Monitor Management - Enhanced  
    # ---------------------------------------------------------------------------
    
    [shift_monitors]
    raise_monitor = true
    focus_follows_mouse = true # Fare odağı takip etsin
    
    # ---------------------------------------------------------------------------
    # Feature Configurations - Enhanced
    # ---------------------------------------------------------------------------
    [expose]
    include_special = false
    include_floating = true    # Floating pencereler dahil
    show_titles = true         # Pencere başlıklarını göster
    
    [lost_windows]
    include_special = false
    auto_recover = true        # Otomatik kayıp pencere kurtarma
    
    [toggle_dpms]
    dpms_timeout = 600
    multi_monitor = true       # Multi-monitor DPMS desteği
    
    # ---------------------------------------------------------------------------
    # New: Magnify Plugin
    # ---------------------------------------------------------------------------
    [magnify]
    factor = 1.5              # Büyütme faktörü
    duration = 200            # Animasyon süresi (ms)
    
    # ---------------------------------------------------------------------------
    # New: Layout Center Plugin  
    # ---------------------------------------------------------------------------
    [layout_center]
    margin = 60               # Kenar boşluğu
    reserve_workspaces = 1    # Rezerve workspace sayısı
    
    # ---------------------------------------------------------------------------
    # Volume Control Scratchpad - Enhanced
    # ---------------------------------------------------------------------------
    [scratchpads.volume]
    animation = "fromRight"
    command = "pavucontrol"
    class = "org.pulseaudio.pavucontrol"
    size = "45% 85%"          # Biraz daha büyük
    margin = 20               # Kenar boşluğu
    unfocus = "hide"
    lazy = true
    excludes = "*"            # Tüm workspace'lerde kullanılabilir
    
    # ---------------------------------------------------------------------------
    # File Manager Scratchpad - Enhanced
    # ---------------------------------------------------------------------------
    [scratchpads.yazi]
    animation = "fromTop"
    command = "kitty --class yazi yazi"
    class = "yazi"            # Düzeltme: yazi class'ı
    size = "80% 70%"          # Daha büyük
    margin = 50
    unfocus = "hide"
    lazy = true
    excludes = "*"
    
    # ---------------------------------------------------------------------------
    # Music Player Scratchpad - Enhanced
    # ---------------------------------------------------------------------------
    [scratchpads.music]
    animation = "fromTop"
    command = "spotify"
    class = "Spotify"
    size = "85% 80%"          # Daha büyük
    margin = 40
    unfocus = "hide"
    lazy = true
    excludes = "*"
    preserve_aspect = true    # Aspect ratio koru
    
    # ---------------------------------------------------------------------------
    # Terminal Scratchpad - Enhanced
    # ---------------------------------------------------------------------------
    [scratchpads.terminal]
    animation = "fromTop"
    command = "kitty --class kitty-scratch"
    class = "kitty-scratch"
    size = "80% 65%"          # Daha büyük
    margin = 30
    unfocus = "hide"
    lazy = true
    excludes = "*"
    
    # ---------------------------------------------------------------------------
    # Music Player (NCMPCPP) Scratchpad - Enhanced
    # ---------------------------------------------------------------------------
    [scratchpads.ncmpcpp]
    animation = "fromRight"
    command = "__kitty-ncmpcpp.sh"
    class = "ncmpcpp"
    size = "75% 75%"          # Daha büyük
    margin = 30
    unfocus = "hide"
    lazy = true
    excludes = "*"
    
    # ---------------------------------------------------------------------------
    # Notes Scratchpad - Enhanced
    # ---------------------------------------------------------------------------
    [scratchpads.notes]
    animation = "fromBottom"
    command = "kitty --class notes nvim"
    class = "notes"
    size = "75% 55%"          # Daha büyük
    margin = 40
    unfocus = "hide"
    lazy = true
    excludes = "*"
    
    # ---------------------------------------------------------------------------
    # New: System Monitor Scratchpad
    # ---------------------------------------------------------------------------
    [scratchpads.htop]
    animation = "fromLeft"
    command = "kitty --class htop htop"
    class = "htop"
    size = "70% 70%"
    margin = 50
    unfocus = "hide"
    lazy = true
    excludes = "*"
    
    # ---------------------------------------------------------------------------
    # New: Calculator Scratchpad
    # ---------------------------------------------------------------------------
    [scratchpads.calc]
    animation = "fromBottom"
    command = "gnome-calculator"
    class = "gnome-calculator"
    size = "30% 50%"
    margin = 20
    unfocus = "hide"
    lazy = true
    excludes = "*"
    
    # ---------------------------------------------------------------------------
    # New: Quick Terminal Scratchpad
    # ---------------------------------------------------------------------------
    [scratchpads.quickterm]
    animation = "fromTop"
    command = "kitty --class quickterm"
    class = "quickterm"
    size = "100% 40%"         # Full width, kısa yükseklik
    margin = 0
    unfocus = "hide"
    lazy = true
    excludes = "*"
  '';
  
  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = with pkgs; [
    pyprland
  ];
  
  # =============================================================================
  # Systemd Service (Optional)
  # =============================================================================
  systemd.user.services.pyprland = {
    Unit = {
      Description = "Pyprland - Python plugins for Hyprland";
      After = ["hyprland-session.target"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.pyprland}/bin/pypr";
      Restart = "on-failure";
      RestartSec = "3";
    };
    Install = {
      WantedBy = ["hyprland-session.target"];
    };
  };
}
