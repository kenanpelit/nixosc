{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.my.user.noctalia;
  noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  options.my.user.noctalia.enable = lib.mkEnableOption "Noctalia shell (Quickshell-based Wayland bar)";

  config = lib.mkIf cfg.enable {
    imports = [ inputs.noctalia.homeModules.default ];

    programs.noctalia-shell = {
      enable = true;
      package = noctaliaPkg;
      systemd.enable = true;
      # Use upstream defaults; allow UI edits to land in ~/.config/noctalia/.
      settings = { };
    };
  };
}
