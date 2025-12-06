# modules/home/obsidian/default.nix
# ==============================================================================
# Obsidian Note-Taking App Configuration
# ==============================================================================
# Not: Paket kurulumu artık modules/home/packages/default.nix tarafında
# yönetiliyor. Bu modül ileride Obsidian ayarlarını (theme, plugin vs.)
# taşımak için boş bir iskelet olarak bırakıldı.
# ==============================================================================
{ lib, config, ... }:
let
  cfg = config.my.user.obsidian;
in
{
  options.my.user.obsidian = {
    enable = lib.mkEnableOption "Obsidian configuration";
  };

  config = lib.mkIf cfg.enable {
  };
}
