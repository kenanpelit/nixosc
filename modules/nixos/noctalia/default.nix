{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.my.user.noctalia or { enable = false; };
  user = config.my.user.name or "kenan";
  noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  options.my.user.noctalia.enable = lib.mkEnableOption "Enable Noctalia shell (quickshell-based)";

  config = lib.mkIf cfg.enable {
    # Make upstream HM module available
    home-manager.sharedModules = [ inputs.noctalia.homeModules.default ];

    # Configure for main user
    home-manager.users.${user}.programs.noctalia-shell = {
      enable = true;
      package = noctaliaPkg;
      systemd.enable = true;
      settings = { };
    };
  };
}
