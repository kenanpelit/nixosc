# modules/core/user.nix
{ pkgs, inputs, username, host, ... }:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  # Temel kullanıcı ayarları
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [
      "wheel"      # sudo
      "sys"        # sistem yönetimi
      "network"    # ağ yönetimi
      "scanner"    # tarayıcı erişimi
      "power"      # güç yönetimi
      "rfkill"     # kablosuz cihaz kontrolü
      "users"      # kullanıcı grubu
      "video"      # video cihazları
      "storage"    # depolama erişimi
      "optical"    # optik sürücü erişimi
      "lp"         # yazıcı erişimi
      "input"      # input cihazları
      "audio"      # ses sistemi
      "podman"     # container yönetimi
      "docker"     # docker yönetimi (isteğe bağlı)
      "libvirtd"   # sanal makine yönetimi
      "networkmanager" # ağ yönetimi
    ];
    shell = pkgs.zsh;
    initialPassword = "nixos";
  };

  # Home Manager konfigürasyonu
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs username host; };
    users.${username} = {
      imports = [ ./../home ];
      home = {
        username = "${username}";
        homeDirectory = "/home/${username}";
        stateVersion = "24.11";
        # Profil yönetimi düzeltmesi
        file.".local/state/nix/profiles".source = pkgs.lib.mkForce
          (pkgs.runCommand "profile-link" {} ''
            mkdir -p $out
            ln -s /nix/var/nix/profiles/per-user/${username} $out/profile
          '');
        
        # XDG dizinlerini yapılandır
        file.".config/user-dirs.dirs".text = ''
          XDG_DESKTOP_DIR="$HOME/Desktop"
          XDG_DOCUMENTS_DIR="$HOME/Documents"
          XDG_DOWNLOAD_DIR="$HOME/Downloads"
          XDG_MUSIC_DIR="$HOME/Music"
          XDG_PICTURES_DIR="$HOME/Pictures"
          XDG_VIDEOS_DIR="$HOME/Videos"
          XDG_TEMPLATES_DIR="$HOME/Templates"
          XDG_PUBLICSHARE_DIR="$HOME/Public"
        '';
      };
    };
  };

  # Nix ayarları
  nix = {
    settings = {
      allowed-users = [ "${username}" ];
      trusted-users = [ "root" "${username}" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Sistem limitleri
  security.pam.loginLimits = [
    {
      domain = "${username}";
      type = "soft";
      item = "nofile";
      value = "4096";
    }
  ];
}
