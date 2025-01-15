{ pkgs, inputs, username, host, lib, config, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my.user = {
    name = mkOption {
      type = types.str;
      default = username;
      description = "The name of the primary user account";
    };

    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "The user's UID";
    };
  };

  config = {
    # Home Manager konfigürasyonu
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      backupFileExtension = "backup";
      extraSpecialArgs = { inherit inputs username host; };
      users.${username} = {
        imports = [ ./../../home ];
        home = {
          username = "${username}";
          homeDirectory = "/home/${username}";
          stateVersion = "24.11";
        };
      };
    };
    
    # Temel kullanıcı ayarları
    users.users.${username} = {
      isNormalUser = true;
      description = "${username}";
      extraGroups = [
        "networkmanager"
        "wheel"
        "input"
      ];
      shell = pkgs.zsh;
      uid = 1000;
    };

    # Nix ayarları
    nix.settings.allowed-users = [ "${username}" ];
  };
}
