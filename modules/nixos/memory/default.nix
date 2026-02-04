# modules/nixos/memory/default.nix
# ==============================================================================
# Memory policy (swap / zram)
# ------------------------------------------------------------------------------
# Keep memory policy separate from `modules/nixos/kernel`:
# - Kernel module focuses on kernel selection + low-level knobs.
# - This module focuses on swap strategy for responsiveness.
# ==============================================================================

{ lib, config, ... }:

let
  inherit (lib) mkIf mkOption types;
  cfg = config.my.memory;
in
{
  options.my.memory = {
    zram = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable ZRAM swap for better responsiveness (fast RAM compression instead of disk swap).";
      };

      algorithm = mkOption {
        type = types.str;
        default = "zstd";
        description = "ZRAM compression algorithm.";
      };

      memoryPercent = mkOption {
        type = types.ints.between 1 100;
        default = 50;
        description = "Percent of RAM to allocate for ZRAM swap.";
      };
    };
  };

  config = mkIf cfg.zram.enable {
    zramSwap = {
      enable = true;
      algorithm = cfg.zram.algorithm;
      memoryPercent = cfg.zram.memoryPercent;
    };
  };
}
