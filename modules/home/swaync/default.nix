# modules/home/swaync/default.nix
{ pkgs, ... }:
let
  # Tokyo Night tema renkleri
  colors = {
    base = "#24283b";
    mantle = "#1f2335";
    crust = "#1a1b26";
    text = "#c0caf5";
    subtext0 = "#9aa5ce";
    subtext1 = "#a9b1d6";
    surface0 = "#292e42";
    surface1 = "#414868";
    surface2 = "#565f89";
    blue = "#7aa2f7";
    green = "#9ece6a";
  };

  # Font ve efekt ayarları
  fonts = {
    notifications = {
      family = "Hack Nerd Font";
    };
  };

  effects = {
    shadow = "rgba(0, 0, 0, 0.25)";
  };

  # SwayNC tema CSS'i - FIXED
  swayncTheme = {
    style = ''
      @define-color shadow ${effects.shadow};
      @define-color base ${colors.base};
      @define-color mantle ${colors.mantle};
      @define-color crust ${colors.crust};
      @define-color text ${colors.text};
      @define-color subtext0 ${colors.subtext0};
      @define-color subtext1 ${colors.subtext1};
      @define-color surface0 ${colors.surface0};
      @define-color surface1 ${colors.surface1};
      @define-color surface2 ${colors.surface2};
      @define-color blue ${colors.blue};
      @define-color green ${colors.green};
      
      * {
        font-family: "${fonts.notifications.family}";
        background-clip: border-box;
      }
      
      /* Floating notifications - no background overlay */
      .floating-notifications {
        background: transparent;
      }
      
      /* FIXED: Remove fullscreen overlay */
      .blank-window {
        background: transparent;  /* Was: alpha(black, 0.2) */
      }
      
      .notification-row {
        outline: none;
        margin: 10px;
        padding: 0;
      }
      
      .notification {
        background: @base;
        border: 2px solid @surface1;
        border-radius: 8px;
        margin: 5px;
        box-shadow: 0 0 8px 0 @shadow;
      }
      
      .notification-content {
        padding: 10px;
        margin: 0;
      }
      
      .close-button {
        background: @surface0;
        color: @text;
        text-shadow: none;
        padding: 0;
        border-radius: 100%;
        margin-top: 10px;
        margin-right: 10px;
        box-shadow: none;
        border: none;
        min-width: 24px;
        min-height: 24px;
      }
      
      .notification-default-action {
        margin: 0;
        padding: 0;
        border-radius: 8px;
      }
      
      .notification-default-action:hover {
        background: @surface0;
      }
      
      .notification-label {
        color: @text;
      }
      
      .notification-background {
        background: @base;
      }
      
      /* Control center with proper positioning */
      .control-center {
        background: @base;
        border: 2px solid @surface1;
        border-radius: 8px;
        margin: 10px;
        box-shadow: 0 0 8px 0 @shadow;
        /* Ensure it doesn't expand beyond intended size */
        max-width: 400px;
        max-height: 650px;
      }
    '';
  };
in
{
  # =============================================================================
  # Configuration Files
  # =============================================================================
  xdg.configFile."swaync/config.json".source = ./config.json;
  
  xdg.configFile."swaync/style.css".text = ''
    ${swayncTheme.style}
    
    label {
        color: @text;
    }

    .notification {
        border: @green;
        box-shadow: none;
        border-radius: 4px;
        background: inherit;
    }

    .notification button {
        background: transparent;
        border-radius: 0px;
        border: none;
        margin: 0px;
        padding: 0px;
    }

    .notification button:hover {
        background: @surface0;
    }

    .notification-content {
        min-height: 64px;
        margin: 10px;
        padding: 0px;
        border-radius: 0px;
    }

    .close-button {
        background: @crust;
        color: @surface2;
    }

    .notification-default-action,
    .notification-action {
        background: transparent;
        border: none;
    }

    .notification-default-action {
        border-radius: 4px;
    }

    .notification-default-action:not(:only-child) {
        border-bottom-left-radius: 0px;
        border-bottom-right-radius: 0px;
    }

    .notification-action {
        border-radius: 0px;
        padding: 2px;
        color: @text;
    }

    .notification-action:first-child {
        border-bottom-left-radius: 4px;
    }

    .notification-action:last-child {
        border-bottom-right-radius: 4px;
    }

    .summary {
        color: @text;
        font-size: 18px;
        padding: 0px;
    }

    .time {
        color: @subtext0;
        font-size: 12px;
        text-shadow: none;
        margin: 0px;
        padding: 2px 0px;
    }

    .body {
        font-size: 16px;
        font-weight: 500;
        color: @subtext1;
        text-shadow: none;
        margin: 0px;
    }

    .body-image {
        border-radius: 4px;
    }

    .top-action-title {
        color: @text;
        text-shadow: none;
    }

    .control-center {
        background: @crust;
        border: 2px solid @surface1;
        border-radius: 0px;
        box-shadow: 0px 0px 2px black;
        /* FIXED: Proper size constraints */
        max-width: 400px;
        max-height: 650px;
        min-width: 300px;
        min-height: 400px;
    }

    /* FIXED: No fullscreen overlay - KEY FIX! */
    .blank-window {
        background: transparent;
    }

    .control-center-list {
        background: @crust;
        min-height: 5px;
        border-radius: 0px 0px 4px 4px;
    }

    .control-center-list-placeholder,
    .notification-group-icon,
    .notification-group {
        color: alpha(@text, 0.5);
    }

    .notification-group {
        all: unset;
        border: none;
        opacity: 0;
        padding: 0px;
        box-shadow: none;
    }

    .notification-group>box {
        all: unset;
        background: @mantle;
        padding: 8px;
        margin: 0px;
        border: none;
        border-radius: 4px;
        box-shadow: none;
    }

    .notification-row {
        outline: none;
        transition: all 1s ease;
        background: @base;
        border: 1px solid @crust;
        margin: 10px 5px 0px 5px;
        border-radius: 4px;
    }

    .notification-row:focus,
    .notification-row:hover {
        box-shadow: none;
    }

    .control-center-list>row,
    .control-center-list>row:focus,
    .control-center-list>row:hover {
        background: transparent;
        border: none;
        margin: 0px;
        padding: 5px 10px 5px 10px;
        box-shadow: none;
    }

    .control-center-list>row:last-child {
        padding: 5px 10px 10px 10px;
    }

    .widget-title {
        margin: 0px;
        background: inherit;
        border-radius: 4px 4px 0px 0px;
        padding-bottom: 20px;
    }

    .widget-title>label {
        margin: 18px 10px;
        font-size: 20px;
        font-weight: 500;
    }

    .widget-title>button {
        font-weight: 700;
        padding: 7px 3px;
        margin-right: 10px;
        background: @mantle;
        color: @text;
        border-radius: 4px;
    }

    .widget-title>button:hover {
        background: @base;
    }

    .widget-label {
        margin: 0px;
        padding: 0px;
        min-height: 5px;
        background: @mantle;
        border-radius: 0px 0px 4px 4px;
    }

    .widget-label>label {
        font-size: 0px;
        font-weight: 400;
    }

    .widget-menubar {
        background: inherit;
    }

    .widget-menubar>box>box {
        margin: 5px 10px 5px 10px;
        min-height: 40px;
        border-radius: 4px;
        background: transparent;
    }

    .widget-menubar>box>box>button {
        background: @mantle;
        min-width: 85px;
        min-height: 50px;
        margin-right: 13px;
        font-size: 17px;
        padding: 0px;
    }

    .widget-menubar>box>box>button:nth-child(4) {
        margin-right: 0px;
    }

    .widget-menubar button:focus {
        box-shadow: none;
    }

    .widget-menubar button:focus:hover {
        background: @base;
        box-shadow: none;
    }

    .widget-menubar>box>revealer>box {
        margin: 5px 10px 5px 10px;
        background: @mantle;
        border-radius: 4px;
    }

    .widget-menubar>box>revealer>box>button {
        background: transparent;
        min-height: 50px;
        padding: 0px;
        margin: 5px;
    }

    .widget-buttons-grid {
        background-color: @mantle;
        font-size: 14px;
        font-weight: 500;
        margin: 0px;
        padding: 5px;
        border-radius: 0px;
    }

    .widget-buttons-grid>flowbox>flowboxchild {
        background: @mantle;
        border-radius: 4px;
        min-height: 50px;
        min-width: 85px;
        margin: 5px;
        padding: 0px;
    }

    .widget-buttons-grid>flowbox>flowboxchild>button {
        background: transparent;
        border-radius: 4px;
        margin: 0px;
        border: none;
        box-shadow: none;
    }

    .widget-buttons-grid>flowbox>flowboxchild>button:hover {
        background: @mantle;
    }

    .widget-mpris {
        padding: 10px 10px 35px;
        margin-bottom: -33px;
    }

    .widget-mpris>box {
        padding: 0px;
        margin: -5px 0px -10px 0px;
        border-radius: 4px;
        background: @mantle;
    }

    .widget-mpris>box>button:nth-child(1),
    .widget-mpris>box>button:nth-child(3) {
        margin: 0px -25px;
        opacity: 0;
    }

    .widget-mpris-player>box>image {
        margin: 0px 0px -48px 0px;
    }

    .widget-mpris-title {
        color: @text;
        font-weight: bold;
        font-size: 1.25rem;
        text-shadow: 0px 0px 5px rgba(0, 0, 0, 0.5);
    }

    .widget-mpris-subtitle {
        color: @subtext1;
        font-size: 1rem;
        text-shadow: 0px 0px 3px rgba(0, 0, 0, 1);
    }

    .widget-mpris>box>carousel>widget>box>box:nth-child(2) {
        margin: 5px 0px -5px 90px;
    }

    .widget-mpris>box>carousel>widget>box>box:nth-child(2)>button {
        border-radius: 4px;
    }

    .widget-mpris>box>carousel>widget>box>box:nth-child(2)>button:hover {
        background: alpha(currentColor, 0.1);
    }

    carouselindicatordots {
        opacity: 0;
    }

    .notification-group>box.vertical {
        margin-top: 3px;
    }

    .widget-backlight,
    .widget-volume {
        background-color: @crust;
        font-size: 13px;
        font-weight: 600;
        border-radius: 0px;
        margin: 0px;
        padding: 0px;
    }

    .widget-volume>box {
        background: @mantle;
        border-radius: 4px;
        margin: 5px 10px;
        min-height: 50px;
    }

    .widget-volume>box>label {
        min-width: 50px;
        padding: 0px;
    }

    .widget-volume>box>button {
        min-width: 50px;
        box-shadow: none;
        padding: 0px;
    }

    .widget-volume>box>button:hover {
        background: @surface0;
    }

    .widget-volume>revealer>list {
        background: @mantle;
        border-radius: 4px;
        margin-top: 5px;
        padding: 0px;
    }

    .widget-volume>revealer>list>row {
        padding-left: 10px;
        min-height: 40px;
        background: transparent;
    }

    .widget-volume>revealer>list>row:hover {
        background: transparent;
        box-shadow: none;
        border-radius: 4px;
    }

    .widget-backlight>scale {
        background: @mantle;
        border-radius: 0px 4px 4px 0px;
        margin: 5px 10px 5px 0px;
        padding: 0px 10px 0px 0px;
        min-height: 50px;
    }

    .widget-backlight>label {
        background: @surface0;
        margin: 5px 0px 5px 10px;
        border-radius: 4px 0px 0px 4px;
        padding: 0px;
        min-height: 50px;
        min-width: 50px;
    }

    .widget-dnd {
        margin: 8px;
        font-size: 1.1rem;
        padding-top: 20px;
    }

    .widget-dnd>switch {
        font-size: initial;
        border-radius: 12px;
        background: @surface0;
        border: 1px solid @green;
        box-shadow: none;
    }

    .widget-dnd>switch:checked {
        background: @surface2;
    }

    .widget-dnd>switch slider {
        background: @green;
        border-radius: 12px;
    }

    .toggle:checked {
        background: @surface1;
    }

    .toggle:checked:hover {
        background: @surface2;
    }

    scale {
        padding: 0px;
        margin: 0px 10px;
    }

    scale trough {
        border-radius: 4px;
        background: @surface0;
    }

    scale highlight {
        border-radius: 5px;
        min-height: 10px;
        margin-right: -5px;
        background: @surface2;
    }

    scale slider {
        margin: -10px;
        min-width: 10px;
        min-height: 10px;
        background: transparent;
        box-shadow: none;
        padding: 0px;
    }

    .right.overlay-indicator {
        all: unset;
    }
  '';
}
