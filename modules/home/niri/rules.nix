# modules/home/niri/rules.nix
# ==============================================================================
# Niri Window Rules - Modular Configuration
#
# Contains logic for window placement, floating rules, sizing, and specific
# application behaviors (e.g., PiP, dialogs).
# Imported by default.nix
# ==============================================================================
{ lib, config, ... }:
let
  cfg = config.my.desktop.niri;

  # ----------------------------------------------------------------------------
  # Window Rule Helpers
  # ----------------------------------------------------------------------------
  mkFixedFloating = 
    { w, h, x ? null, y ? null, relativeTo ? "top-right", opacity ? null, focus ? true }:
    ''
      open-floating true;
      default-column-width { fixed ${toString w}; }
      default-window-height { fixed ${toString h}; }
      ${lib.optionalString (x != null && y != null)
        ''default-floating-position x=${toString x} y=${toString y} relative-to=\