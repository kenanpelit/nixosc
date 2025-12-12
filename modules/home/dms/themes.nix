# modules/home/dms/themes.nix
# ==============================================================================
# DMS theme definitions: palette files for DankMaterialShell keybind UI, etc.
# Imported by default.nix; add/adjust themes here.
# ==============================================================================
{ lib, config, pkgs, ... }:
let
  cfg = config.my.user.dms;

  # Helper to write a theme file
  mkTheme = name: body: {
    path = "DankMaterialShell/themes/${name}.json";
    text = body;
  };

  themes = [
    (mkTheme "tokyo-night" ''
      {
        "name": "Tokyo Night",
        "primary": "#7aa2f7",
        "primaryText": "#1a1b26",
        "primaryContainer": "#2f334d",
        "secondary": "#bb9af7",
        "surfaceTint": "#7aa2f7",
        "surface": "#1a1b26",
        "surfaceText": "#c0caf5",
        "surfaceVariant": "#24283b",
        "surfaceVariantText": "#9aa5ce",
        "surfaceContainer": "#1f2335",
        "surfaceContainerHigh": "#252a3f",
        "surfaceContainerHighest": "#2c3047",
        "background": "#0f111a",
        "backgroundText": "#c0caf5",
        "outline": "#414868",
        "error": "#f7768e",
        "warning": "#e0af68",
        "info": "#7dcfff",
        "matugen_type": "scheme-tonal-spot"
      }
    '')
    (mkTheme "catppuccin-mocha" ''
      {
        "name": "Catppuccin Mocha",
        "primary": "#cba6f7",
        "primaryText": "#1e1e2e",
        "primaryContainer": "#312b45",
        "secondary": "#89dceb",
        "surfaceTint": "#cba6f7",
        "surface": "#1e1e2e",
        "surfaceText": "#cdd6f4",
        "surfaceVariant": "#313244",
        "surfaceVariantText": "#a6adc8",
        "surfaceContainer": "#1f2230",
        "surfaceContainerHigh": "#24283a",
        "surfaceContainerHighest": "#2a3042",
        "background": "#11111b",
        "backgroundText": "#cdd6f4",
        "outline": "#45475a",
        "error": "#f38ba8",
        "warning": "#f9e2af",
        "info": "#89b4fa",
        "matugen_type": "scheme-tonal-spot"
      }
    '')
    (mkTheme "nord" ''
      {
        "name": "Nord Dark",
        "primary": "#88c0d0",
        "primaryText": "#2e3440",
        "primaryContainer": "#4c566a",
        "secondary": "#b48ead",
        "surfaceTint": "#88c0d0",
        "surface": "#2e3440",
        "surfaceText": "#e5e9f0",
        "surfaceVariant": "#3b4252",
        "surfaceVariantText": "#d8dee9",
        "surfaceContainer": "#323845",
        "surfaceContainerHigh": "#373e4c",
        "surfaceContainerHighest": "#3d4554",
        "background": "#242933",
        "backgroundText": "#e5e9f0",
        "outline": "#4c566a",
        "error": "#bf616a",
        "warning": "#d08770",
        "info": "#5e81ac",
        "matugen_type": "scheme-tonal-spot"
      }
    '')
    (mkTheme "gruvbox-dark" ''
      {
        "name": "Gruvbox Dark",
        "primary": "#d79921",
        "primaryText": "#1d2021",
        "primaryContainer": "#3c3836",
        "secondary": "#b16286",
        "surfaceTint": "#d79921",
        "surface": "#1d2021",
        "surfaceText": "#ebdbb2",
        "surfaceVariant": "#282828",
        "surfaceVariantText": "#d5c4a1",
        "surfaceContainer": "#222525",
        "surfaceContainerHigh": "#262a2a",
        "surfaceContainerHighest": "#2b3030",
        "background": "#141617",
        "backgroundText": "#ebdbb2",
        "outline": "#504945",
        "error": "#fb4934",
        "warning": "#fabd2f",
        "info": "#83a598",
        "matugen_type": "scheme-tonal-spot"
      }
    '')
    (mkTheme "dracula" ''
      {
        "name": "Dracula",
        "primary": "#bd93f9",
        "primaryText": "#1e1f29",
        "primaryContainer": "#343746",
        "secondary": "#50fa7b",
        "surfaceTint": "#bd93f9",
        "surface": "#1e1f29",
        "surfaceText": "#f8f8f2",
        "surfaceVariant": "#282a36",
        "surfaceVariantText": "#e2e2dc",
        "surfaceContainer": "#22232f",
        "surfaceContainerHigh": "#272937",
        "surfaceContainerHighest": "#2d3040",
        "background": "#14141c",
        "backgroundText": "#f8f8f2",
        "outline": "#44475a",
        "error": "#ff5555",
        "warning": "#f1fa8c",
        "info": "#8be9fd",
        "matugen_type": "scheme-tonal-spot"
      }
    '')
    (mkTheme "solarized-dark" ''
      {
        "name": "Solarized Dark",
        "primary": "#268bd2",
        "primaryText": "#002b36",
        "primaryContainer": "#073642",
        "secondary": "#b58900",
        "surfaceTint": "#268bd2",
        "surface": "#002b36",
        "surfaceText": "#93a1a1",
        "surfaceVariant": "#073642",
        "surfaceVariantText": "#839496",
        "surfaceContainer": "#03303c",
        "surfaceContainerHigh": "#083743",
        "surfaceContainerHighest": "#0d3e4a",
        "background": "#001f27",
        "backgroundText": "#93a1a1",
        "outline": "#586e75",
        "error": "#dc322f",
        "warning": "#b58900",
        "info": "#2aa198",
        "matugen_type": "scheme-tonal-spot"
      }
    '')
    (mkTheme "hotline-miami" ''
      {
        "name": "Hotline Miami",
        "primary": "#ff71ce",
        "primaryText": "#0b0b12",
        "primaryContainer": "#2b1a2f",
        "secondary": "#01fdf6",
        "surfaceTint": "#ff71ce",
        "surface": "#0b0b12",
        "surfaceText": "#f5f5ff",
        "surfaceVariant": "#1a1a2a",
        "surfaceVariantText": "#c2c2dc",
        "surfaceContainer": "#151520",
        "surfaceContainerHigh": "#1c1c2a",
        "surfaceContainerHighest": "#232332",
        "background": "#07070c",
        "backgroundText": "#f5f5ff",
        "outline": "#37374a",
        "error": "#ff3f78",
        "warning": "#ffc857",
        "info": "#01fdf6",
        "matugen_type": "scheme-expressive"
      }
    '')
    (mkTheme "cyberpunk-electric" ''
      {
        "name": "Cyberpunk Electric",
        "primary": "#00ffcc",
        "primaryText": "#000000",
        "primaryContainer": "#00cc99",
        "secondary": "#ff4dff",
        "surfaceTint": "#00ffcc",
        "surface": "#0f0f0f",
        "surfaceText": "#e0ffe0",
        "surfaceVariant": "#1f2f1f",
        "surfaceVariantText": "#ccffcc",
        "surfaceContainer": "#1a2b1a",
        "surfaceContainerHigh": "#264026",
        "surfaceContainerHighest": "#33553f",
        "background": "#000000",
        "backgroundText": "#f0fff0",
        "outline": "#80ff80",
        "error": "#ff0066",
        "warning": "#ccff00",
        "info": "#00ffcc",
        "matugen_type": "scheme-expressive"
      }
    '')
    (mkTheme "onedark" ''
      {
        "name": "One Dark",
        "primary": "#61afef",
        "primaryText": "#1e222a",
        "primaryContainer": "#2b2f37",
        "secondary": "#c678dd",
        "surfaceTint": "#61afef",
        "surface": "#1e222a",
        "surfaceText": "#abb2bf",
        "surfaceVariant": "#2c323c",
        "surfaceVariantText": "#d7dae0",
        "surfaceContainer": "#20252d",
        "surfaceContainerHigh": "#252b34",
        "surfaceContainerHighest": "#2b323c",
        "background": "#13161c",
        "backgroundText": "#e6e6e6",
        "outline": "#444b58",
        "error": "#e06c75",
        "warning": "#e5c07b",
        "info": "#56b6c2",
        "matugen_type": "scheme-tonal-spot"
      }
    '')
    (mkTheme "everforest" ''
      {
        "name": "Everforest Dark",
        "primary": "#a7c080",
        "primaryText": "#2e383c",
        "primaryContainer": "#323c41",
        "secondary": "#e67e80",
        "surfaceTint": "#a7c080",
        "surface": "#2b3339",
        "surfaceText": "#d3c6aa",
        "surfaceVariant": "#343f44",
        "surfaceVariantText": "#c0c5ce",
        "surfaceContainer": "#2d363c",
        "surfaceContainerHigh": "#333d44",
        "surfaceContainerHighest": "#39444c",
        "background": "#232a2f",
        "backgroundText": "#d3c6aa",
        "outline": "#465258",
        "error": "#e67e80",
        "warning": "#dbbc7f",
        "info": "#7fbbb3",
        "matugen_type": "scheme-tonal-spot"
      }
    '')
    (mkTheme "material-ocean" ''
      {
        "name": "Material Ocean",
        "primary": "#84ffff",
        "primaryText": "#0f111a",
        "primaryContainer": "#1f2230",
        "secondary": "#80cbc4",
        "surfaceTint": "#84ffff",
        "surface": "#0f111a",
        "surfaceText": "#cdd6f4",
        "surfaceVariant": "#1f2433",
        "surfaceVariantText": "#a6adc8",
        "surfaceContainer": "#161926",
        "surfaceContainerHigh": "#1c2030",
        "surfaceContainerHighest": "#23283a",
        "background": "#0b0d14",
        "backgroundText": "#d8dee9",
        "outline": "#39404f",
        "error": "#ff5370",
        "warning": "#ffcb6b",
        "info": "#82aaff",
        "matugen_type": "scheme-tonal-spot"
      }
    '')
    (mkTheme "material-ocean-deep" ''
      {
        "name": "Material Ocean Deep",
        "primary": "#64ffda",
        "primaryText": "#0b0d14",
        "primaryContainer": "#1b1f2c",
        "secondary": "#80cbc4",
        "surfaceTint": "#64ffda",
        "surface": "#0a0c12",
        "surfaceText": "#d7e3f4",
        "surfaceVariant": "#1a1f2d",
        "surfaceVariantText": "#9fb0c6",
        "surfaceContainer": "#131826",
        "surfaceContainerHigh": "#191f2f",
        "surfaceContainerHighest": "#20283a",
        "background": "#070910",
        "backgroundText": "#cfd8e4",
        "outline": "#323a4a",
        "error": "#ff6e6e",
        "warning": "#ffb86c",
        "info": "#7ad7ff",
        "matugen_type": "scheme-tonal-spot"
      }
    '')
    (mkTheme "material-ocean-pastel" ''
      {
        "name": "Material Ocean Pastel",
        "primary": "#9be8ff",
        "primaryText": "#11131c",
        "primaryContainer": "#22283a",
        "secondary": "#a8e3d8",
        "surfaceTint": "#9be8ff",
        "surface": "#12141d",
        "surfaceText": "#e7edf7",
        "surfaceVariant": "#1f2434",
        "surfaceVariantText": "#c0c8d6",
        "surfaceContainer": "#171c2a",
        "surfaceContainerHigh": "#1d2231",
        "surfaceContainerHighest": "#252c3d",
        "background": "#0e1119",
        "backgroundText": "#dbe2ef",
        "outline": "#3d4557",
        "error": "#ff7b93",
        "warning": "#ffd39f",
        "info": "#94c4ff",
        "matugen_type": "scheme-tonal-spot"
      }
    '')
    (mkTheme "synthwave-electric-dark" ''
      {
        "name": "Synthwave Electric Dark",
        "primary": "#FF6600",
        "primaryText": "#000000",
        "primaryContainer": "#CC5200",
        "secondary": "#0080FF",
        "surface": "#0A0A15",
        "surfaceText": "#E6F0FF",
        "surfaceVariant": "#1A1A33",
        "surfaceVariantText": "#CCE0FF",
        "surfaceTint": "#FF6600",
        "background": "#000008",
        "backgroundText": "#F0F8FF",
        "outline": "#4D80FF",
        "surfaceContainer": "#151529",
        "surfaceContainerHigh": "#212147",
        "error": "#FF3366",
        "warning": "#FFCC00",
        "info": "#0080FF",
        "matugen_type": "scheme-tonal-spot"
      }
    '')
  ];

in
lib.mkIf cfg.enable {
  # Write theme JSON files
  xdg.configFile = lib.listToAttrs (map (t: { name = t.path; value.text = t.text; }) themes);
}
