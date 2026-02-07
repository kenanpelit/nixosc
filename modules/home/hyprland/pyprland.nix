# modules/home/hyprland/pyprland.nix
# ==============================================================================
# Pyprland plugin configuration for Hyprland (Python-based plugins).
# Enable/disable plugins and options here to extend Hyprland functionality.
# ==============================================================================
{ config, lib, pkgs, ... }:
let
  cfg = config.my.desktop.hyprland;
  basePlugins = [
    "scratchpads"
    "lost_windows"
    "shift_monitors"
    "toggle_dpms"
    "workspaces_follow_focus"
  ];
  extendedPlugins = [
    "expose"
    "magnify"
    "layout_center"
  ];
  enabledPlugins = basePlugins ++ lib.optionals cfg.enablePyprlandExtendedPlugins extendedPlugins;
  pluginListToml = lib.concatStringsSep ",\n      " (map (name: "\"${name}\"") enabledPlugins);
  extendedPluginSections = lib.optionalString cfg.enablePyprlandExtendedPlugins ''
    # ---------------------------------------------------------------------------
    # Extended Plugin Configurations
    # ---------------------------------------------------------------------------
    [expose]
    include_special = false
    include_floating = true
    show_titles = true

    [magnify]
    factor = 1.5
    duration = 200

    [layout_center]
    margin = 60
    reserve_workspaces = 1
  '';
in
lib.mkIf cfg.enable {
  # =============================================================================
  # Configuration File
  # =============================================================================
  home.file.".config/hypr/pyprland.toml".text = ''
    # ---------------------------------------------------------------------------
    # Plugin Configuration - Enhanced
    # ---------------------------------------------------------------------------
    [pyprland]
    plugins = [
      ${pluginListToml}
    ]
    
    # ---------------------------------------------------------------------------
    # Global Settings
    # ---------------------------------------------------------------------------
    [settings]
    check_interval = 100        # ms - Faster response
    debug = false              # Debug disabled (for production)
    
    # ---------------------------------------------------------------------------
    # Workspace Settings - Enhanced
    # ---------------------------------------------------------------------------
    [workspaces_follow_focus]
    max_workspaces = 9
    follow_mouse = true        # Follow mouse workspace
    
    # ---------------------------------------------------------------------------
    # Monitor Management - Enhanced  
    # ---------------------------------------------------------------------------
    
    [shift_monitors]
    raise_monitor = true
    focus_follows_mouse = true # Follow mouse focus
    
    # ---------------------------------------------------------------------------
    # Core Feature Configurations
    # ---------------------------------------------------------------------------
    [lost_windows]
    include_special = false
    auto_recover = true        # Auto recover lost windows
    
    [toggle_dpms]
    dpms_timeout = 600
    multi_monitor = true       # Multi-monitor DPMS support
    
    ${extendedPluginSections}
    
    # ---------------------------------------------------------------------------
    # Volume Control Scratchpad - Enhanced
    # ---------------------------------------------------------------------------
    [scratchpads.volume]
    animation = "fromRight"
    command = "pavucontrol"
    class = "org.pulseaudio.pavucontrol"
    size = "45% 85%"          # Slightly larger
    margin = 20               # Margin
    unfocus = "hide"
    lazy = true
    excludes = "*"            # Available on all workspaces
    
    # ---------------------------------------------------------------------------
    # File Manager Scratchpad - Enhanced
    # ---------------------------------------------------------------------------
    [scratchpads.yazi]
    animation = "fromTop"
    command = "kitty --class yazi yazi"
    class = "yazi"            # Fix: yazi class
    size = "80% 70%"          # Larger
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
    size = "85% 80%"          # Larger
    margin = 40
    unfocus = "hide"
    lazy = true
    excludes = "*"
    preserve_aspect = true    # Preserve aspect ratio
    
    # ---------------------------------------------------------------------------
    # Terminal Scratchpad - Enhanced
    # ---------------------------------------------------------------------------
    [scratchpads.terminal]
    animation = "fromTop"
    command = "kitty --class kitty-scratch"
    class = "kitty-scratch"
    size = "80% 65%"          # Larger
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
    size = "75% 75%"          # Larger
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
    size = "75% 55%"          # Larger
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
    size = "100% 40%"         # Full width, short height
    margin = 0
    unfocus = "hide"
    lazy = true
    excludes = "*"
  '';
  
  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = [ pkgs.pyprland ];
  
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
