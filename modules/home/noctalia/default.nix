{ inputs, lib, config, pkgs, ... }:

let
  cfg = config.my.user.noctalia or { enable = false; };
  noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  options.my.user.noctalia.enable = lib.mkEnableOption "Noctalia shell (quickshell-based)";

  config = lib.mkIf cfg.enable {
    # Bring in upstream HM module
    imports = [ inputs.noctalia.homeModules.default ];

    programs.noctalia-shell = {
      enable = true;
      package = noctaliaPkg;
      systemd.enable = true;
      settings = { };
    };
  };
}
