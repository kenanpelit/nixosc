# modules/home/hyprland/settings.nix
# ==============================================================================
# Hyprland Core Settings & Startup
#
# Configures monitors, workspaces, input devices, gestures, and general
# compositor aesthetics (decoration, animations, master/dwindle layouts).
# Imported by default.nix
# ==============================================================================
{ lib, bins, mkColor, colors, activeBorder, inactiveBorder, inactiveGroupBorder, cursorName, ... }:

let
  primaryMonitor = "DELL UP2716D KRXTR88N909L";
  secondaryMonitor = "Chimei Innolux Corporation 0x143F";
  primaryMonitorDesc = "desc:Dell Inc. ${primaryMonitor}";
  secondaryMonitorDesc = "desc:${secondaryMonitor}";
  
  mkWorkspaceEntry = { monitor, index, isDefault ? false }:
    "${toString index}, monitor:${monitor}${lib.optionalString isDefault ", default:true"}";

  startupServices = [
    "${bins.hyprSet} env-sync"
    "systemctl --user start hyprland-session.target"
    "hyprctl setcursor ${cursorName} 24"
    "${bins.hyprSet} clipse"
  ];

  monitorConfig = [
    "${primaryMonitorDesc},2560x1440@59,0x0,1"
    "${secondaryMonitorDesc},1920x1200@60,320x1440,1"
    ",preferred,auto,1"
  ];

  workspaceConfig =
    (map (n: mkWorkspaceEntry { monitor = primaryMonitorDesc; index = n; isDefault = n == 1; }) (lib.range 1 6))
    ++ (map (n: mkWorkspaceEntry { monitor = secondaryMonitorDesc; index = n; isDefault = n == 7; }) (lib.range 7 9))
    ++ [
      # Smart Gaps & Borders - No gaps/borders/rounding when only one window is present
      "w[tv1], gapsout:0, gapsin:0, bordersize:0, rounding:0"
      "f[1], gapsout:0, gapsin:0, bordersize:0, rounding:0"

      # Smart borders - Disabled to show borders always
      # "w[v1]s[false], bordersize:0, rounding:false"
      # "f[1]s[false], bordersize:0, rounding:false"
      "w[v2-99]s[false], bordersize:3, rounding:true"
      # Special workspaces
      "special:dropdown, gapsout:0, gapsin:0"
      "special:scratchpad, gapsout:0, gapsin:0"
    ];

in
{
  exec-once = startupServices;
  monitor = monitorConfig;
  workspace = workspaceConfig;

  general = {
    "$mainMod" = "SUPER";
    gaps_in = 5;
    gaps_out = 10;
    border_size = 2;
    "col.active_border" = "${mkColor colors.teal.hex 1.0} ${mkColor colors.sky.hex 1.0} 45deg";
    "col.inactive_border" = inactiveBorder;
    layout = "master";
    allow_tearing = false;
    resize_on_border = true;
    extend_border_grab_area = 15;
    hover_icon_on_border = true;
  };

  group = {
    "col.border_active" = activeBorder;
    "col.border_inactive" = inactiveGroupBorder;
    "col.border_locked_active" = activeBorder;
    "col.border_locked_inactive" = inactiveGroupBorder;
    groupbar = {
      render_titles = false;
      gradients = false;
      font_size = 10;
      "col.active" = mkColor colors.blue.hex 0.93;
      "col.inactive" = mkColor colors.overlay0.hex 0.66;
      "col.locked_active" = mkColor colors.mauve.hex 0.93;
      "col.locked_inactive" = mkColor colors.surface1.hex 0.66;
    };
  };

  decoration = {
    rounding = 10;
    active_opacity = 1.0;
    inactive_opacity = 0.85;
    fullscreen_opacity = 1.0;
    dim_inactive = true;
    dim_strength = 0.15;
    blur = {
      enabled = true;
      size = 10;
      passes = 3;
      ignore_opacity = true;
      new_optimizations = true;
      xray = true;
      vibrancy = 0.1696;
      vibrancy_darkness = 0.0;
      special = false;
      popups = true;
      popups_ignorealpha = 0.2;
    };
    shadow = {
      enabled = true;
      ignore_window = true;
      offset = "0 4";
      range = 30;
      render_power = 4;
      color = "0x66000000";
      scale = 0.97;
    };
  };

  animations = {
    enabled = true;
    bezier = [
      "linear, 0.0, 0.0, 1.0, 1.0"
      "quart, 0.25, 1, 0.5, 1"        # Smooth deceleration (Professional)
      "fluid, 0.05, 0.9, 0.1, 1.02"   # Micro-bounce (Magnetic, Premium feel)
    ];
    animation = [
      "windowsIn, 1, 4, quart, popin 95%"  # Elegant entry (Scale up)
      "windowsOut, 1, 4, quart, popin 95%" # Elegant exit (Scale down)
      "windowsMove, 1, 4, fluid"           # Snappy movement with tiny bounce
      "fade, 1, 3, quart"                  # Smooth fading
      "workspaces, 1, 5, quart, slidevert" # Vertical workspace flow
      "specialWorkspace, 1, 4, quart, slidevert"
      "border, 1, 3, linear"
    ];
  };

  input = {
    kb_layout = "tr";
    kb_variant = "f";
    kb_options = "ctrl:nocaps";
    repeat_rate = 35;
    repeat_delay = 250;
    numlock_by_default = false;
    sensitivity = 0.0;
    accel-profile = "adaptive";
    force_no_accel = true;
    follow_mouse = 1;
    float_switch_override_focus = 2;
    left_handed = false;
    touchpad = {
      natural_scroll = false;
      disable_while_typing = true;
      tap-to-click = true;
      drag_lock = true;
      scroll_factor = 1.0;
      clickfinger_behavior = true;
      middle_button_emulation = true;
      tap-and-drag = true;
    };
  };

  misc = {
    disable_hyprland_logo = true;
    disable_splash_rendering = true;
    force_default_wallpaper = 0;
    background_color = mkColor colors.base.hex 1.0;
    mouse_move_enables_dpms = true;
    key_press_enables_dpms = true;
    vrr = 1;
    vfr = true;
    disable_autoreload = false;
    disable_hyprland_guiutils_check = true;
    focus_on_activate = true;
    always_follow_on_dnd = true;
    layers_hog_keyboard_focus = true;
    animate_manual_resizes = true;
    animate_mouse_windowdragging = true;
    enable_swallow = true;
    swallow_regex = "^(kitty|alacritty|wezterm)$";
    swallow_exception_regex = "^(wev|Wayland-desktop|wl-clipboard)$";
    mouse_move_focuses_monitor = true;
    initial_workspace_tracking = 1;
    close_special_on_empty = true;
    allow_session_lock_restore = true;
  };

  gestures = {
    workspace_swipe_distance = 300;
    workspace_swipe_touch = false;
    workspace_swipe_touch_invert = false;
    workspace_swipe_invert = true;
    workspace_swipe_min_speed_to_force = 20;
    workspace_swipe_cancel_ratio = 0.3;
    workspace_swipe_create_new = true;
    workspace_swipe_direction_lock = true;
    workspace_swipe_direction_lock_threshold = 15;
    workspace_swipe_forever = true;
  };

  dwindle = {
    pseudotile = true;
    preserve_split = true;
    special_scale_factor = 0.8;
    force_split = 2;
    split_width_multiplier = 1.0;
    use_active_for_splits = true;
    default_split_ratio = 1.0;
  };

  master = {
    new_on_top = false;
    new_status = "slave";
    mfact = 0.60;
    orientation = "left";
    smart_resizing = true;
    drop_at_cursor = false;
    allow_small_split = false;
    special_scale_factor = 0.8;
    new_on_active = "after";
  };

  binds = {
    pass_mouse_when_bound = true;
    workspace_back_and_forth = true;
    allow_workspace_cycles = true;
    workspace_center_on = 1;
    focus_preferred_method = 0;
    ignore_group_lock = true;
  };
}
