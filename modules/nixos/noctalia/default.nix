{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.my.user.noctalia or { enable = false; };
  user = config.my.user.name or "kenan";
  noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  options.my.user.noctalia.enable = lib.mkEnableOption "Enable Noctalia (Quickshell-based shell)";

  config = lib.mkIf cfg.enable {
    # Provide upstream HM module to the user
    home-manager.sharedModules = [ inputs.noctalia.homeModules.default ];

    # Configure the user's Noctalia shell
    home-manager.users.${user}.programs.noctalia-shell = {
      enable = true;
      package = noctaliaPkg;
      systemd.enable = true;
      settings = { };
    };
  };
}
