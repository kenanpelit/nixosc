# modules/home/wezterm/default.nix
# ==============================================================================
# WezTerm Terminal Emulator Configuration
# ==============================================================================
{ config, lib, pkgs, ... }:
let
  colors = import ./../../../themes/default.nix;
  inherit (colors) kenp;
in
{
  programs.wezterm = {
    enable = true;
    
    extraConfig = ''
      local wezterm = require("wezterm")
      local act = wezterm.action
      local config = wezterm.config_builder()

      -- Performance & GPU
      config.front_end = "WebGpu"
      config.webgpu_power_preference = "HighPerformance"
      config.max_fps = 120
      config.animation_fps = 60
      config.enable_wayland = true
      config.enable_kitty_keyboard = false
      config.warn_about_missing_glyphs = false
      config.enable_kitty_graphics = false
      config.enable_csi_u_key_encoding = false
      config.check_for_updates = false

      -- Her zaman yeni pencere aç
      config.default_workspace = "default"

      -- Font Configuration
      config.font = wezterm.font_with_fallback({
        { family = "${colors.fonts.terminal.family}", weight = "Regular" },
        { family = "${colors.fonts.terminal.family} Bold", weight = "Bold" },
        { family = "${colors.fonts.terminal.family} Italic", italic = true },
        { family = "${colors.fonts.terminal.family} Bold Italic", weight = "Bold", italic = true },
      })
      config.font_size = ${lib.strings.removeSuffix "px" colors.fonts.terminal.size}
      config.line_height = 1.0
      config.harfbuzz_features = {
        "kern",
        "liga",
        "clig",
        "calt",
        "ss01",
      }

      -- Window Appearance
      config.window_padding = { left = 6, right = 6, top = 6, bottom = 6 }
      config.window_decorations = "NONE"
      config.window_background_opacity = ${colors.effects.opacity}
      config.text_background_opacity = ${colors.effects.opacity}
      config.adjust_window_size_when_changing_font_size = false

      -- Tab Bar
      config.enable_tab_bar = true
      config.hide_tab_bar_if_only_one_tab = true
      config.tab_bar_at_bottom = true
      config.use_fancy_tab_bar = false
      config.tab_max_width = 25
      config.show_tab_index_in_tab_bar = false

      -- Cursor & Terminal
      config.default_cursor_style = "SteadyBlock"
      config.cursor_blink_rate = 500
      config.force_reverse_video_cursor = true
      config.term = "wezterm"
      config.scrollback_lines = 10000
      config.enable_scroll_bar = false
      config.hide_mouse_cursor_when_typing = true

      -- URL Detection
      config.hyperlink_rules = {
        {
          regex = [[\b\w+@[\w-]+(\.[\w-]+)+\b]],
          format = "mailto:$0",
        },
        {
          regex = [[\b\w+://(?:[\w.-]+)\.[a-z]{2,15}\S*\b]],
          format = "$0",
        },
        {
          regex = [[\b\.?/[^/\s]+(?:/[^/\s]+)*\b]],
          format = "file://$0",
        },
      }

      -- Mouse Bindings
      config.mouse_bindings = {
        {
          event = { Up = { streak = 1, button = "Left" } },
          mods = "NONE",
          action = act.CompleteSelection("ClipboardAndPrimarySelection"),
        },
        {
          event = { Up = { streak = 2, button = "Left" } },
          mods = "NONE",
          action = act.CompleteSelection("ClipboardAndPrimarySelection"),
        },
        {
          event = { Down = { streak = 3, button = "Left" } },
          mods = "NONE",
          action = act.SelectTextAtMouseCursor("Line"),
        },
        {
          event = { Down = { streak = 4, button = "Left" } },
          mods = "NONE",
          action = act.SelectTextAtMouseCursor("Block"),
        },
      }

      -- Leader Key Configuration
      config.leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 }
      config.keys = {
        {
          mods = "LEADER",
          key = "c",
          action = wezterm.action.SpawnTab("CurrentPaneDomain"),
        },
        {
          mods = "LEADER",
          key = "x",
          action = wezterm.action.CloseCurrentPane({ confirm = true }),
        },
        {
          mods = "LEADER",
          key = "b",
          action = wezterm.action.ActivateTabRelative(-1),
        },
        {
          mods = "LEADER",
          key = "n",
          action = wezterm.action.ActivateTabRelative(1),
        },
        {
          mods = "LEADER",
          key = "|",
          action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
        },
        {
          mods = "LEADER",
          key = "-",
          action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
        },
        {
          mods = "LEADER",
          key = "h",
          action = wezterm.action.ActivatePaneDirection("Left"),
        },
        {
          mods = "LEADER",
          key = "j",
          action = wezterm.action.ActivatePaneDirection("Down"),
        },
        {
          mods = "LEADER",
          key = "k",
          action = wezterm.action.ActivatePaneDirection("Up"),
        },
        {
          mods = "LEADER",
          key = "l",
          action = wezterm.action.ActivatePaneDirection("Right"),
        },
        {
          mods = "LEADER",
          key = "LeftArrow",
          action = wezterm.action.AdjustPaneSize({ "Left", 5 }),
        },
        {
          mods = "LEADER",
          key = "RightArrow",
          action = wezterm.action.AdjustPaneSize({ "Right", 5 }),
        },
        {
          mods = "LEADER",
          key = "DownArrow",
          action = wezterm.action.AdjustPaneSize({ "Down", 5 }),
        },
        {
          mods = "LEADER",
          key = "UpArrow",
          action = wezterm.action.AdjustPaneSize({ "Up", 5 }),
        },
      }

      -- Tab number bindings
      for i = 0, 9 do
        table.insert(config.keys, {
          key = tostring(i),
          mods = "LEADER",
          action = wezterm.action.ActivateTab(i),
        })
      end

      -- Tab bar configuration
      config.hide_tab_bar_if_only_one_tab = false
      config.tab_bar_at_bottom = true
      config.use_fancy_tab_bar = false
      config.tab_and_split_indices_are_zero_based = true

      -- Status line updates
      wezterm.on("update-right-status", function(window, _)
        local SOLID_LEFT_ARROW = ""
        local ARROW_FOREGROUND = { Foreground = { Color = "${kenp.mauve}" } }
        local prefix = ""

        if window:leader_is_active() then
          prefix = " " .. utf8.char(0x1f30a)
          SOLID_LEFT_ARROW = utf8.char(0xe0b2)
        end

        if window:active_tab():tab_id() ~= 0 then
          ARROW_FOREGROUND = { Foreground = { Color = "${kenp.crust}" } }
        end

        window:set_left_status(wezterm.format({
          { Background = { Color = "${kenp.pink}" } },
          { Attribute = { Intensity = "Bold" } },
          { Text = prefix },
          { Background = { Color = "${kenp.mauve}" } },
          { Foreground = { Color = "${kenp.crust}" } },
          { Text = " TERM " },
          ARROW_FOREGROUND,
          { Text = SOLID_LEFT_ARROW },
        }))
      end)

      -- Performance Optimizations
      config.allow_square_glyphs_to_overflow_width = "Never"
      config.custom_block_glyphs = false
      config.unicode_version = 14
      config.freetype_load_target = "Light"

      -- Color Scheme
      config.colors = {
        foreground = "${kenp.text}",
        background = "${kenp.base}",
        cursor_bg = "${kenp.mauve}",
        cursor_fg = "${kenp.surface2}",
        selection_fg = "${kenp.crust}",
        selection_bg = "${kenp.mauve}",
        tab_bar = {
          background = "${kenp.mantle}",
          active_tab = {
            bg_color = "${kenp.mauve}",
            fg_color = "${kenp.crust}",
          },
          inactive_tab = {
            bg_color = "${kenp.crust}",
            fg_color = "${kenp.text}",
          },
        },
        ansi = {
          "${kenp.surface1}",  -- Black
          "${kenp.red}",       -- Red
          "${kenp.green}",     -- Green
          "${kenp.yellow}",    -- Yellow
          "${kenp.mauve}",     -- Blue
          "${kenp.pink}",      -- Magenta
          "${kenp.sky}",       -- Cyan
          "${kenp.text}",      -- White
        },
        brights = {
          "${kenp.surface2}",  -- Bright Black
          "${kenp.red}",       -- Bright Red
          "${kenp.green}",     -- Bright Green
          "${kenp.yellow}",    -- Bright Yellow
          "${kenp.mauve}",     -- Bright Blue
          "${kenp.pink}",      -- Bright Magenta
          "${kenp.sky}",       -- Bright Cyan
          "#ffffff",           -- Bright White
        },
      }

      -- Wayland Environment Variables
      config.set_environment_variables = {
        TERM = "wezterm",
        COLORTERM = "truecolor",
        WINIT_UNIX_BACKEND = "wayland",
        GDK_BACKEND = "wayland",
        QT_QPA_PLATFORM = "wayland",
        SDL_VIDEODRIVER = "wayland",
        CLUTTER_BACKEND = "wayland",
        XDG_CURRENT_DESKTOP = "sway",
        XDG_SESSION_TYPE = "wayland",
        MOZ_ENABLE_WAYLAND = "1",
        QT_AUTO_SCREEN_SCALE_FACTOR = "1",
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1",
      }

      -- Window title formatting
      wezterm.on("format-window-title", function(tab, pane, tabs, panes, config)
        local zoomed = tab.active_pane.is_zoomed and "[Z] " or ""
        local index = #tabs > 1 and string.format("[%d/%d] ", tab.tab_index + 1, #tabs) or ""
        return zoomed .. index .. tab.active_pane.title
      end)

      return config
    '';
  };
}
